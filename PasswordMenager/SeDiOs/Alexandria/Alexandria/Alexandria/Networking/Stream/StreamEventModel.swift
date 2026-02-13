//
//  StreamEventModel.swift
//  Alexandria
//
//  STREAM / SUBSCRIBE / EVENTS – umjesto CRUD-only REST.
//

import Foundation

// MARK: - Event tipovi
enum StreamEventKind: String, Codable {
    case stream = "STREAM"   // kontinuirani tok podataka
    case subscribe = "SUBSCRIBE"  // pretplata na kanal
    case event = "EVENT"     // jednokratni event
    case unsubscribe = "UNSUBSCRIBE"
}

// MARK: - Stream event
struct StreamEvent: Identifiable, Sendable {
    let id: UUID
    let kind: StreamEventKind
    let channel: String
    let payload: Data?
    let timestamp: Date
    
    init(id: UUID = UUID(), kind: StreamEventKind, channel: String, payload: Data? = nil, timestamp: Date = Date()) {
        self.id = id
        self.kind = kind
        self.channel = channel
        self.payload = payload
        self.timestamp = timestamp
    }
}

// MARK: - Async stream kanal (STREAM / SUBSCRIBE)
final class StreamChannel: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<StreamEvent>.Continuation] = [:]
    
    func subscribe() -> AsyncStream<StreamEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            self.lock.lock()
            self.continuations[id] = continuation
            self.lock.unlock()
            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.continuations.removeValue(forKey: id)
                self?.lock.unlock()
            }
        }
    }
    
    func publish(_ event: StreamEvent) {
        lock.lock()
        let conts = continuations
        lock.unlock()
        for (_, cont) in conts {
            cont.yield(event)
        }
    }
}
