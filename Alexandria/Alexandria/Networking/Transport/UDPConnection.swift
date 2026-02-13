//
//  UDPConnection.swift
//  Alexandria
//
//  UDP transport – brzi, nepouzdan prijenos.
//

import Foundation
import Network

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
        
        return try await withCheckedThrowingContinuation { cont in
            var resumed = false
            conn.stateUpdateHandler = { state in
                guard !resumed else { return }
                switch state {
                case .ready:
                    resumed = true
                    cont.resume()
                case .failed(let error):
                    resumed = true
                    cont.resume(throwing: error)
                case .cancelled:
                    resumed = true
                    cont.resume(throwing: NSError(domain: "UDP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cancelled"]))
                default:
                    break
                }
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
