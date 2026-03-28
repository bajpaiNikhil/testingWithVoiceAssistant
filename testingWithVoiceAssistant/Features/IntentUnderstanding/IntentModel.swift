//
//  IntentModel.swift
//  testingWithVoiceAssistant
//
//  Created for IntentUnderstanding — Phase 02
//

import Foundation

struct IntentResponse: Codable {
    let intent: String
    let entities: Entities
    let response: String

    struct Entities: Codable {
        let time: String?
        let contact: String?
        let message: String?
        let app: String?
        let destination: String?

        // Override default encoder behavior: always emit all fields, using null for nil
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(time, forKey: .time)
            try c.encode(contact, forKey: .contact)
            try c.encode(message, forKey: .message)
            try c.encode(app, forKey: .app)
            try c.encode(destination, forKey: .destination)
        }
    }
}
