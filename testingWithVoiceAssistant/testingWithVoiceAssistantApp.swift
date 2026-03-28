//
//  testingWithVoiceAssistantApp.swift
//  testingWithVoiceAssistant
//
//  Created by Nikhil Bajpai on 22/03/26.
//

import SwiftUI

@main
struct testingWithVoiceAssistantApp: App {

    let whisperEngine = WhisperEngine()

    init() {
        whisperEngine.initialize()
        Task {
            await PhiEngine.shared.runSmokeTest()
            let svc = LLMService()
            await svc.parse(transcript: "set alarm for 7 am")
            await svc.parse(transcript: "call mom")
            await svc.parse(transcript: "open youtube")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(engine: whisperEngine)
        }
    }
}
