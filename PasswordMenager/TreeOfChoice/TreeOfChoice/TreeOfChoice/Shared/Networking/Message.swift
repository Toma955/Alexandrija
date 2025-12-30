//
//  Message.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

enum MessageDirection: String, Codable {
    case incoming
    case outgoing
    case system   // npr. "razgovor završen", "sesija istekla"
}

struct Message: Identifiable, Codable {
    let id: UUID
    let conversationId: String
    let direction: MessageDirection
    let timestamp: Date
    let text: String
    
    init(id: UUID = UUID(), conversationId: String, direction: MessageDirection, timestamp: Date = Date(), text: String) {
        self.id = id
        self.conversationId = conversationId
        self.direction = direction
        self.timestamp = timestamp
        self.text = text
    }
}

