//
//  LLMService.swift
//  testingWithVoiceAssistant
//
//  Created for IntentUnderstanding — Phase 00
//

import Foundation

@MainActor
final class LLMService {

    private static let fallback = #"{"intent":"Unknown","entities":{"time":null,"contact":null,"message":null,"app":null,"destination":null},"response":"Sorry, I didn't understand that."}"#

    func parse(transcript: String) async -> String {
        print("[Intent][Phase01] Input: \(transcript)")

        let input = PromptBuilder.build(transcript: transcript)
        print("[Intent][Prompt] Generated prompt")
        print("[Intent][LLM] Prompt sent")

        // Attempt 1
        let raw1 = await PhiEngine.shared.generate(input: input)
        print("[Intent][LLM] Raw output: \(raw1)")
        let result1 = OutputSanitizer.sanitize(raw1)

        if !isFallback(result1) {
            return result1
        }

        // Attempt 1 failed — retry once
        print("[Intent][Retry] Attempt 1 failed")
        print("[Intent][Retry] Retrying")

        let raw2 = await PhiEngine.shared.generate(input: input)
        print("[Intent][LLM] Raw output: \(raw2)")
        let result2 = OutputSanitizer.sanitize(raw2)

        if !isFallback(result2) {
            return result2
        }

        // Both attempts failed — return fallback
        print("[Intent][Fallback] Returning default response")
        return Self.fallback
    }

    private func isFallback(_ result: String) -> Bool {
        result.contains("\"intent\":\"Unknown\"")
    }
}
