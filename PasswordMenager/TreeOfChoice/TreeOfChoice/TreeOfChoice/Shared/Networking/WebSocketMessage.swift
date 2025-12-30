//
//  WebSocketMessage.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Tip poruke ("t" u JSON-u)
enum WSType: String, Codable {
    case ping
    case pong
    
    case join
    case joined
    case sessionReady = "session_ready"
    
    case msg
    case signal
    
    case extendRequest = "extend_request"
    case extend
    case extended
    case expired
    
    case error
}

/// Generičan model jedne WS poruke.
struct WSMessage: Codable {
    let t: WSType
    
    // zajednička polja
    let code: String?
    let mode: String?
    
    // ping / pong
    let alive: Bool?
    
    // chat
    let body: String?
    
    // signal (E2E)
    let from: String?
    let data: [String: String]?
    
    // extend / lifetime
    let remainingExtensions: Int?
    let renewCount: Int?
    
    // error
    let reason: String?
    let message: String?
    
    // MARK: - helperi za slanje
    
    static func ping() -> WSMessage {
        WSMessage(
            t: .ping,
            code: nil, mode: nil,
            alive: nil,
            body: nil,
            from: nil, data: nil,
            remainingExtensions: nil, renewCount: nil,
            reason: nil, message: nil
        )
    }
    
    static func join(code: String, mode: String = "direct") -> WSMessage {
        WSMessage(
            t: .join,
            code: code, mode: mode,
            alive: nil,
            body: nil,
            from: nil, data: nil,
            remainingExtensions: nil, renewCount: nil,
            reason: nil, message: nil
        )
    }
    
    static func chat(code: String, body: String) -> WSMessage {
        WSMessage(
            t: .msg,
            code: code, mode: nil,
            alive: nil,
            body: body,
            from: nil, data: nil,
            remainingExtensions: nil, renewCount: nil,
            reason: nil, message: nil
        )
    }
    
    static func signal(code: String,
                       from: String,
                       data: [String: String]) -> WSMessage {
        WSMessage(
            t: .signal,
            code: code, mode: nil,
            alive: nil,
            body: nil,
            from: from, data: data,
            remainingExtensions: nil, renewCount: nil,
            reason: nil, message: nil
        )
    }
    
    static func extend(code: String) -> WSMessage {
        WSMessage(
            t: .extend,
            code: code, mode: nil,
            alive: nil,
            body: nil,
            from: nil, data: nil,
            remainingExtensions: nil, renewCount: nil,
            reason: nil, message: nil
        )
    }
}

