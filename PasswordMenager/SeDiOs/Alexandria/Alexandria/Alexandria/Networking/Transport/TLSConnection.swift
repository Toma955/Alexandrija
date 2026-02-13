//
//  TLSConnection.swift
//  Alexandria
//
//  TLS/SSL – enkripcija prometa preko TCP.
//

import Foundation
import Network

/// TLS konekcija – TCP + TLS (Network.framework)
actor TLSConnection {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "alexandria.tls")
    
    func connect(host: String, port: UInt16) async throws {
        let endpoint = NWEndpoint.Host(host)
        let port = NWEndpoint.Port(integerLiteral: port)
        let tlsOptions = NWProtocolTLS.Options()
        let tcpOptions = NWProtocolTCP.Options()
        let params = NWParameters(tls: tlsOptions, tcp: tcpOptions)
        let conn = NWConnection(host: endpoint, port: port, using: params)
        connection = conn
        
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
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
                    cont.resume(throwing: NSError(domain: "TLS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cancelled"]))
                default:
                    break
                }
            }
            conn.start(queue: queue)
        }
    }
    
    func send(_ data: Data) async throws {
        guard let conn = connection else { throw TLSError.notConnected }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            conn.send(content: data, completion: .contentProcessed { error in
                if let e = error { cont.resume(throwing: e) }
                else { cont.resume() }
            })
        }
    }
    
    func receive(minimumIncompleteLength: Int = 1, maximumLength: Int = 65536) async throws -> Data? {
        guard let conn = connection else { throw TLSError.notConnected }
        return try await withCheckedThrowingContinuation { cont in
            conn.receive(minimumIncompleteLength: minimumIncompleteLength, maximumLength: maximumLength) { data, _, _, error in
                if let e = error { cont.resume(throwing: e) }
                else { cont.resume(returning: data) }
            }
        }
    }
    
    func close() {
        connection?.cancel()
        connection = nil
    }
    
    enum TLSError: Error {
        case notConnected
    }
}
