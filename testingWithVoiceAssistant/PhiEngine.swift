//
//  PhiEngine.swift
//  testingWithVoiceAssistant
//
//  Smoke-test for phi3-mini.gguf responsiveness.
//  Call PhiEngine.shared.runSmokeTest() once on app launch to verify the model loads and generates tokens.
//

import Foundation
import LocalLLMClient
import LocalLLMClientLlama

@MainActor
final class PhiEngine {

    static let shared = PhiEngine()
    private init() {}

    private var client: LlamaClient?
    private var isLoading = false

    // MARK: - Load

    func load() async {
        guard client == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        guard let modelURL = Bundle.main.url(forResource: "phi3-mini", withExtension: "gguf") else {
            print("[PhiEngine] ❌ phi3-mini.gguf not found in bundle")
            return
        }

        print("[PhiEngine] Loading model from: \(modelURL.lastPathComponent)")

        do {
            client = try await LocalLLMClient.llama(url: modelURL, parameter: .default)
            print("[PhiEngine] ✅ Model loaded")
        } catch {
            print("[PhiEngine] ❌ Failed to load model: \(error)")
        }
    }

    // MARK: - Generate

    func generate(input: LLMInput) async -> String {
        await load()
        guard let client else { return "" }
        var response = ""
        do {
            for try await token in try await client.textStream(from: input) {
                response += token
            }
        } catch {
            print("[PhiEngine] ❌ generate error: \(error)")
        }
        return response
    }

    // MARK: - Smoke Test

    /// Sends a single short prompt and streams the response to console.
    /// Call this once to confirm the model is responsive.
    func runSmokeTest() async {
        await load()

        guard let client else {
            print("[PhiEngine] ❌ Client not available — skipping smoke test")
            return
        }

        let input = LLMInput.chat([
            .system("You are a helpful assistant. Be brief."),
            .user("Reply with exactly: I am ready.")
        ])

        print("[PhiEngine] Smoke test started")
        var response = ""

        do {
            for try await token in try await client.textStream(from: input) {
                response += token
                print("[PhiEngine] Token: \(token)", terminator: "")
            }
            print()  // newline after streaming
            print("[PhiEngine] ✅ Smoke test complete — response: \"\(response.trimmingCharacters(in: .whitespacesAndNewlines))\"")
        } catch {
            print("[PhiEngine] ❌ Inference error: \(error)")
        }
    }
}
