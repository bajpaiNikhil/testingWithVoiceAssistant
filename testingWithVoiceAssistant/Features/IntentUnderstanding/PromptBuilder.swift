//
//  PromptBuilder.swift
//  testingWithVoiceAssistant
//
//  Created for IntentUnderstanding — Phase 01
//

import LocalLLMClient

enum PromptBuilder {

    static func build(transcript: String) -> LLMInput {
        .chat([
            .system("You are a JSON intent parser. Output only a valid JSON object. No text, no explanation, no markdown."),

            // Few-shot examples as real conversation turns
            .user("set alarm for 7 am"),
            .assistant(#"{"intent":"SetAlarm","entities":{"time":"07:00","contact":null,"message":null,"app":null,"destination":null},"response":"Setting alarm for 7 AM."}"#),

            .user("call mom"),
            .assistant(#"{"intent":"Call","entities":{"time":null,"contact":"mom","message":null,"app":null,"destination":null},"response":"Calling mom."}"#),

            .user("send message to Rahul saying I'm on my way"),
            .assistant(#"{"intent":"SendMessage","entities":{"time":null,"contact":"Rahul","message":"I'm on my way","app":null,"destination":null},"response":"Sending message to Rahul."}"#),

            .user("open youtube"),
            .assistant(#"{"intent":"LaunchApp","entities":{"time":null,"contact":null,"message":null,"app":"YouTube","destination":null},"response":"Opening YouTube."}"#),

            .user("navigate to airport"),
            .assistant(#"{"intent":"Navigate","entities":{"time":null,"contact":null,"message":null,"app":null,"destination":"airport"},"response":"Starting navigation to the airport."}"#),

            .user("what time is it"),
            .assistant(#"{"intent":"Unknown","entities":{"time":null,"contact":null,"message":null,"app":null,"destination":null},"response":"Sorry, I didn't understand that."}"#),

            .user(transcript)
        ])
    }
}
