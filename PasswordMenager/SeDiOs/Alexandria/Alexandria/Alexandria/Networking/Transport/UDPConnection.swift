//
//  UDPConnection.swift
//  Alexandria
//
//  UDP transport – brzi, nepouzdan prijenos.
//

import Foundation
import Network
import os

/// UDP konekcija – Network.framework
actor UDPConnection {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "alexandria.udp")
    
    func connect(host: String, port: UInt16) async throws {
        let endpoint = NWEndpoint.Host(host)
        let port = NWEndpoint.Port(integerLiteral: port)
        let params = NWParameters.udp
        let conn = NWConnection(host: endpoint, port: port, using: params)
        connection = conn
        
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            // NE DIRAJ: OSAllocatedUnfairLock – Swift 6 zabranjuje captured var u concurrently-executing closure
            let once = OSAllocatedUnfairLock(initialState: false)
            conn.stateUpdateHandler = { state in
                let skip = once.withLock { done -> Bool in
                    guard !done else { return true }
                    switch state {
                    case .ready:
                        done = true
                        cont.resume()
                        return false
                    case .failed(let error):
                        done = true
                        cont.resume(throwing: error)
                        return false
                    case .cancelled:
                        done = true
                        cont.resume(throwing: NSError(domain: "UDP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cancelled"]))
                        return false
                    default:
                        return false
                    }
                }
                if skip { return }
            }
            conn.start(queue: queue)
        }
    }
    
    func send(_ data: Data) async throws {
        guard let conn = connection else { throw UDPError.notConnected }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            conn.send(content: data, completion: .contentProcessed { error in
                if let e = error { cont.resume(throwing: e) }
                else { cont.resume() }
            })
        }
    }
    
    func receive() async throws -> (Data?, NWEndpoint?) {
        guard let conn = connection else { throw UDPError.notConnected }
        return try await withCheckedThrowingContinuation { cont in
            conn.receiveMessage { data, _, _, error in
                if let e = error { cont.resume(throwing: e) }
                else { cont.resume(returning: (data, nil)) }
            }
        }
    }
    
    func close() {
        connection?.cancel()
        connection = nil
    }
    
    enum UDPError: Error {
        case notConnected
    }
}
