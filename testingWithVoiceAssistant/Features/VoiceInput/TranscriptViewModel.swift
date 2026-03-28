//
//  TranscriptViewModel.swift
//  testingWithVoiceAssistant
//
//  Created for Phase 00 — Vertical Slice
//

import Observation
import Foundation
import Combine
import AVFoundation
enum RecordingState {
    case idle
    case recording
    case processing
    case completed
    case error(String)
}

@Observable
@MainActor
final class TranscriptViewModel {

    var state: RecordingState = .idle
    var transcript: String = ""

    private let audio = AudioCaptureService()
    private let engine: WhisperEngine
    private var isProcessingChunk = false
    private let ringBuffer = RingBuffer()
    private let silenceEnergyThreshold: Float = 0.01
    private let silenceDurationThreshold: TimeInterval = 1.5
    private var silenceStartDate: Date? = nil
    private let maxRecordingDuration: TimeInterval = 60
    private var recordingTimeoutTask: Task<Void, Never>? = nil
    private var interruptionObserver: AnyCancellable? = nil

    init(engine: WhisperEngine) {
        self.engine = engine
    }

    // MARK: - Public

    func toggleRecording() {
        switch state {
        case .idle, .completed, .error:
            startRecording()
        case .recording:
            stopRecording()
        case .processing:
            break  // ignore taps while processing
        }
    }

    // MARK: - Private

    private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            guard case .recording = state else { return }
            print("[VoiceInput][Safety] Recording interrupted")
            stopRecording()
        case .ended:
            print("[VoiceInput][Safety] Restart handled")
        default:
            break
        }
    }

    private func computeEnergy(_ frames: [Float]) -> Float {
        guard !frames.isEmpty else { return 0 }
        let sumOfSquares = frames.reduce(0) { $0 + $1 * $1 }
        return sqrt(sumOfSquares / Float(frames.count))
    }

    private func mergeTranscript(old: String, new: String) -> String {
        guard !old.isEmpty else { return new }
        guard !new.isEmpty else { return old }

        let oldWords = old.split(separator: " ").map(String.init)
        let newWords = new.split(separator: " ").map(String.init)

        func normalize(_ w: String) -> String {
            w.lowercased().trimmingCharacters(in: .punctuationCharacters)
        }

        // Strategy 1: Prefix matching — new begins with the entire old transcript
        // e.g. old="A B C", new="A B C D E" → old is a full prefix of new → append "D E"
        let oldNorm = oldWords.map(normalize)
        let newNorm = newWords.map(normalize)
        var prefixLength = 0
        for i in 0..<min(oldNorm.count, newNorm.count) {
            if oldNorm[i] == newNorm[i] { prefixLength = i + 1 } else { break }
        }
        if prefixLength == oldNorm.count {
            let suffix = newWords.dropFirst(prefixLength)
            guard !suffix.isEmpty else { return old }
            return old + " " + suffix.joined(separator: " ")
        }

        // Strategy 2: Suffix deduplication — new starts with words from end of old
        // e.g. old="A B C", new="C D E" → overlap "C" → result "A B C D E"
        var overlapCount = 0
        let maxOverlap = min(oldWords.count, newWords.count)
        for length in stride(from: maxOverlap, through: 1, by: -1) {
            let oldSuffix = oldWords.suffix(length).map(normalize)
            let newPrefix = newWords.prefix(length).map(normalize)
            if oldSuffix == newPrefix {
                overlapCount = length
                break
            }
        }

        let uniqueNew = newWords.dropFirst(overlapCount)
        guard !uniqueNew.isEmpty else { return old }
        return old + " " + uniqueNew.joined(separator: " ")
    }

    private func finalizeTranscript() async {
        recordingTimeoutTask?.cancel()
        recordingTimeoutTask = nil
        interruptionObserver = nil
        let remaining = ringBuffer.readNewChunk()
        ringBuffer.reset()

        if !remaining.isEmpty {
            print("[VoiceInput][TranscriptViewModel] Finalizing — \(remaining.count) remaining frames")
            do {
                let result = try await engine.transcribe(audioFrames: remaining)
                if !result.isEmpty {
                    let old = transcript
                    let merged = mergeTranscript(old: old, new: result)
                    print("[VoiceInput][Transcript] Old: \"\(old)\"")
                    print("[VoiceInput][Transcript] New: \"\(result)\"")
                    print("[VoiceInput][Transcript] Merged: \"\(merged)\"")
                    transcript = merged
                }
            } catch {
                print("[VoiceInput][TranscriptViewModel] ❌ Final inference error: \(error)")
            }
        }

        state = .completed
        print("[VoiceInput][Transcript] Final transcript ready")
    }

    private func startRecording() {
        do {
            transcript = ""
            ringBuffer.reset()
            silenceStartDate = nil
            audio.onChunk = { [weak self] frames in
                guard let self else { return }
                self.ringBuffer.append(frames)
                Task { await self.processChunk() }
            }
            try audio.start()
            state = .recording
            interruptionObserver = NotificationCenter.default
                .publisher(for: AVAudioSession.interruptionNotification)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] notification in self?.handleInterruption(notification: notification) }
            recordingTimeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64((self?.maxRecordingDuration ?? 60) * 1_000_000_000))
                guard let self, case .recording = self.state else { return }
                print("[VoiceInput][Safety] Timeout triggered")
                self.stopRecording()
            }
            print("[VoiceInput][TranscriptViewModel] Recording started")
        } catch {
            state = .error(error.localizedDescription)
            print("[VoiceInput][TranscriptViewModel] ❌ Failed to start: \(error)")
        }
    }

    private func stopRecording() {
        recordingTimeoutTask?.cancel()
        recordingTimeoutTask = nil
        interruptionObserver = nil
        isProcessingChunk = false
        ringBuffer.reset()
        audio.onChunk = nil
        audio.stop { frames in
            print("[VoiceInput][TranscriptViewModel] Recording stopped — \(frames.count) total frames")
        }
        state = .completed
        print("[VoiceInput][TranscriptViewModel] Finalized")
    }

    private func processChunk() async {
        guard case .recording = state else {
            print("[VoiceInput][TranscriptViewModel] Chunk skipped — not recording")
            return
        }
        guard !isProcessingChunk else {
            print("[VoiceInput][TranscriptViewModel] Chunk skipped — inference in progress")
            return
        }

        let frames = ringBuffer.readNewChunk()
        guard !frames.isEmpty else {
            print("[VoiceInput][TranscriptViewModel] Chunk skipped — no new audio in buffer")
            return
        }

        let energy = computeEnergy(frames)
        print("[VoiceInput][Silence] Energy: \(energy)")

        if energy < silenceEnergyThreshold {
            if silenceStartDate == nil {
                silenceStartDate = Date()
                print("[VoiceInput][Silence] Silence started")
            } else {
                let duration = Date().timeIntervalSince(silenceStartDate!)
                print("[VoiceInput][Silence] Silence duration: \(String(format: "%.1f", duration))s")
                if duration >= silenceDurationThreshold {
                    print("[VoiceInput][Silence] Silence threshold reached → stopping")
                    audio.onChunk = nil
                    audio.stop { frames in
                        print("[VoiceInput][TranscriptViewModel] Recording stopped — \(frames.count) total frames")
                    }
                    state = .processing
                    Task { await self.finalizeTranscript() }
                    return
                }
            }
        } else {
            silenceStartDate = nil
        }

        isProcessingChunk = true
        defer {
            isProcessingChunk = false
            // Drain any audio that accumulated during inference
            if case .recording = state {
                Task { await self.processChunk() }
            }
        }

        print("[VoiceInput][TranscriptViewModel] Chunk inference started — \(frames.count) frames")
        do {
            let result = try await engine.transcribe(audioFrames: frames)
            // Re-check state — recording may have stopped while inference was running
            guard case .recording = state else {
                print("[VoiceInput][TranscriptViewModel] Chunk discarded — stopped while transcribing")
                return
            }
            guard !result.isEmpty else {
                print("[VoiceInput][TranscriptViewModel] Chunk produced no text — skipping")
                return
            }
            let old = transcript
            let merged = mergeTranscript(old: old, new: result)
            print("[VoiceInput][Transcript] Old: \"\(old)\"")
            print("[VoiceInput][Transcript] New: \"\(result)\"")
            print("[VoiceInput][Transcript] Merged: \"\(merged)\"")
            transcript = merged
        } catch {
            print("[VoiceInput][TranscriptViewModel] ❌ Chunk inference error: \(error)")
        }
    }
}
