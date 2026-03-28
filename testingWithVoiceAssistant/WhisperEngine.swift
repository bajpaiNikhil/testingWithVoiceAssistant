//
//  WhisperEngine.swift
//  testingWithVoiceAssistant
//
//  Created by Nikhil Bajpai on 22/03/26.
//


import Foundation
import SwiftWhisper

final class WhisperEngine {

    private var whisper: Whisper?

    func initialize() {

        guard let modelPath = Bundle.main.path(
            forResource: "whisper.base",
            ofType: "bin"
        ) else {
            print("[VoiceInput][WhisperEngine] ❌ Model not found in bundle")
            return
        }

        print("[VoiceInput][WhisperEngine] Model path: \(modelPath)")

        let params = WhisperParams(strategy: .greedy)
        params.language = .english          // skip language detection — saves ~100ms per chunk
        params.n_threads = 4                // use 4 CPU threads for decoder
        params.no_context = true            // don't carry context between chunks
        params.single_segment = true        // streaming-friendly: one segment per chunk
        params.suppress_blank = true        // suppress leading blank tokens
        params.suppress_non_speech_tokens = true  // suppress [BLANK_AUDIO], [NOISE] etc at decoder level
        params.temperature_inc = 0          // disable temperature stepping — primary fallback guard
        params.entropy_thold = -1.0         // disable entropy fallback — stops decoder looping on silence
        params.logprob_thold = -1.0         // disable logprob fallback — secondary guard against extra passes
        params.max_tokens = 64              // cap token count — 3s of speech ≈ 30-50 tokens max
        params.duration_ms = 3000           // only decode 3s window, don't process silent padding

        whisper = Whisper(fromFileURL: URL(fileURLWithPath: modelPath), withParams: params)

        print("[VoiceInput][WhisperEngine] ✅ Initialized — language: en, threads: 4, no fallback")
    }

    func transcribe(audioFrames: [Float]) async throws -> String {
        guard let whisper else {
            print("[VoiceInput][WhisperEngine] ❌ Not initialized — call initialize() first")
            throw WhisperError.notInitialized
        }

        print("[VoiceInput][WhisperEngine] Inference started — \(audioFrames.count) frames")

        let segments = try await whisper.transcribe(audioFrames: audioFrames)
        let raw = segments.map(\.text).joined(separator: " ")
        let text = Self.stripHallucinationTokens(raw)

        print("[VoiceInput][WhisperEngine] Inference completed — result: \"\(text)\"")
        return text
    }

    // Whisper.cpp emits special tokens for silence/noise — strip them before returning text
    private static let hallucinationTokens = ["[BLANK_AUDIO]", "[NOISE]", "[MUSIC]", "(Music)", "(Applause)"]

    private static func stripHallucinationTokens(_ text: String) -> String {
        var result = text
        for token in hallucinationTokens {
            result = result.replacingOccurrences(of: token, with: "")
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    enum WhisperError: Error {
        case notInitialized
    }
}
