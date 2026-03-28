//
//  AudioCaptureService.swift
//  testingWithVoiceAssistant
//
//  Created for Phase 00 — Vertical Slice
//

import AVFoundation

final class AudioCaptureService {

    var onChunk: (([Float]) -> Void)?

    private let engine = AVAudioEngine()
    private var frames: [Float] = []
    private var lastEmitCount: Int = 0
    private var converter: AVAudioConverter?
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16_000,
        channels: 1,
        interleaved: false
    )!

    // MARK: - Public API

    func start() throws {
        if engine.isRunning {
            print("[VoiceInput][Safety] Restart handled")
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }

        print("[VoiceInput][AudioCaptureService] Configuring session")

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        frames.removeAll()
        lastEmitCount = 0

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        converter = AVAudioConverter(from: inputFormat, to: targetFormat)

        guard converter != nil else {
            print("[VoiceInput][AudioCaptureService] ❌ Could not create converter")
            throw CaptureError.converterFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.process(buffer: buffer)
        }

        try engine.start()
        print("[VoiceInput][AudioCaptureService] Recording started — input format: \(inputFormat)")
    }

    func stop(completion: ([Float]) -> Void) {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        try? AVAudioSession.sharedInstance().setActive(false)

        print("[VoiceInput][AudioCaptureService] Recording stopped — captured \(frames.count) frames")
        completion(frames)
    }

    // MARK: - Private

    private func process(buffer: AVAudioPCMBuffer) {
        guard let converter else { return }

        let frameCapacity = AVAudioFrameCount(
            Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate
        )
        guard frameCapacity > 0,
              let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCapacity)
        else { return }

        var error: NSError?
        var consumedAll = false

        converter.convert(to: converted, error: &error) { _, outStatus in
            if consumedAll {
                outStatus.pointee = .noDataNow
                return nil
            }
            outStatus.pointee = .haveData
            consumedAll = true
            return buffer
        }

        if let e = error {
            print("[VoiceInput][AudioCaptureService] Conversion error: \(e)")
            return
        }

        guard let channelData = converted.floatChannelData?[0] else { return }
        let newFrames = Array(UnsafeBufferPointer(start: channelData, count: Int(converted.frameLength)))
        frames.append(contentsOf: newFrames)

        let chunkSize = 48_000  // 3 seconds at 16 kHz — minimum for reliable Whisper output
        if frames.count - lastEmitCount >= chunkSize {
            let chunk = Array(frames[lastEmitCount...])
            lastEmitCount = frames.count
            print("[VoiceInput][AudioCaptureService] Chunk emitted — \(chunk.count) frames")
            onChunk?(chunk)
        }
    }

    // MARK: - Errors

    enum CaptureError: Error {
        case converterFailed
    }
}
