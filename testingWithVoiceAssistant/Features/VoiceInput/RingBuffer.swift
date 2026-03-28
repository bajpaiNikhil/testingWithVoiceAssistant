//
//  RingBuffer.swift
//  testingWithVoiceAssistant
//
//  Created for Phase 02 — RingBuffer
//

/// Bounded append buffer with a read cursor.
/// Stores up to `capacity` audio frames; returns only frames added since the last read.
final class RingBuffer {

    private var buffer: [Float] = []
    private var readIndex: Int = 0
    private let capacity: Int

    // MARK: - Init

    /// - Parameter capacity: Max frames to retain. Default = 480,000 (30 seconds at 16 kHz).
    init(capacity: Int = 480_000) {
        self.capacity = capacity
    }

    // MARK: - Public API

    /// Appends new audio frames. Trims oldest frames if buffer exceeds capacity.
    func append(_ frames: [Float]) {
        buffer.append(contentsOf: frames)

        if buffer.count > capacity {
            let excess = buffer.count - capacity
            buffer.removeFirst(excess)
            // Clamp readIndex so it stays within the trimmed buffer
            readIndex = max(0, readIndex - excess)
        }

        print("[VoiceInput][RingBuffer] Appended \(frames.count) frames — total: \(buffer.count), readIndex: \(readIndex)")
    }

    /// Returns all frames added since the last read and advances the read cursor.
    /// Returns an empty array if there are no new frames.
    func readNewChunk() -> [Float] {
        guard readIndex < buffer.count else {
            print("[VoiceInput][RingBuffer] Read new chunk: 0 frames — nothing new")
            return []
        }

        let chunk = Array(buffer[readIndex...])
        readIndex = buffer.count
        print("[VoiceInput][RingBuffer] Read new chunk: \(chunk.count) frames — readIndex now: \(readIndex)")
        return chunk
    }

    /// Clears the buffer and resets the read cursor.
    func reset() {
        buffer.removeAll()
        readIndex = 0
        print("[VoiceInput][RingBuffer] Reset")
    }
}
