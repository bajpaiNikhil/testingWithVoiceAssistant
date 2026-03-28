//
//  OutputSanitizer.swift
//  testingWithVoiceAssistant
//
//  Created for IntentUnderstanding — Phase 02
//

import Foundation

enum OutputSanitizer {

    static func sanitize(_ raw: String) -> String {
        print("[Intent][Phase02] Raw output: \(raw)")

        // Step 1 — Remove special tokens and leading noise
        var cleaned = raw
        cleaned = cleaned.replacingOccurrences(of: "<|assistant|>", with: "")
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        print("[Intent][Phase02] Cleaned output: \(cleaned)")

        // Step 2 — Extract first { ... } block
        guard let start = cleaned.firstIndex(of: "{"),
              let end = cleaned.lastIndex(of: "}") else {
            print("[Intent][Phase02] Extracted JSON: none — returning fallback")
            return fallback
        }
        let extracted = String(cleaned[start...end])
        print("[Intent][Phase02] Extracted JSON: \(extracted)")

        // Step 3 & 4 — Decode → normalize → re-encode
        guard let data = extracted.data(using: .utf8),
              let model = try? JSONDecoder().decode(IntentResponse.self, from: data) else {
            print("[Intent][Phase02] Decode failed — returning fallback")
            return fallback
        }

        let normalized = normalize(model)
        let output = (try? String(data: JSONEncoder().encode(normalized), encoding: .utf8)) ?? fallback
        print("[Intent][Phase02] Final normalized JSON: \(output)")
        return output
    }

    // MARK: - Private

    private static let fallback = #"{"intent":"Unknown","entities":{"time":null,"contact":null,"message":null,"app":null,"destination":null},"response":"Sorry, I didn't understand that."}"#

    private static func normalize(_ model: IntentResponse) -> IntentResponse {
        let intentMap = ["Call": "CallContact", "Alarm": "SetAlarm"]
        let intent = intentMap[model.intent] ?? model.intent

        let contact = model.entities.contact.map { $0.prefix(1).uppercased() + $0.dropFirst() }

        let entities = IntentResponse.Entities(
            time: model.entities.time?.trimmingCharacters(in: .whitespaces),
            contact: contact,
            message: model.entities.message?.trimmingCharacters(in: .whitespaces),
            app: model.entities.app,
            destination: model.entities.destination?.trimmingCharacters(in: .whitespaces)
        )

        return IntentResponse(intent: intent, entities: entities, response: model.response)
    }
}
