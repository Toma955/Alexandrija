//
//  ConsoleStore.swift
//  Alexandria
//
//  Console – log output za Alexandria renderer.
//

import Foundation
import SwiftUI

private let consoleMaxMessages = 500

@MainActor
final class ConsoleStore: ObservableObject {
    static let shared = ConsoleStore()
    
    @Published var messages: [ConsoleMessage] = []
    
    private init() {}
    
    func log(_ text: String, type: ConsoleMessageType = .log) {
        if messages.count >= consoleMaxMessages {
            messages.removeFirst(messages.count - consoleMaxMessages + 1)
        }
        messages.append(ConsoleMessage(text: text, type: type, date: Date()))
        print("[Eluminatium] \(text)")
    }
    
    func clear() {
        messages.removeAll()
    }
}

struct ConsoleMessage: Identifiable {
    let id = UUID()
    let text: String
    let type: ConsoleMessageType
    let date: Date
}

enum ConsoleMessageType {
    case log
    case info
    case warn
    case error
}
