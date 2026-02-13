//
//  ProtocolService.swift
//  Alexandria
//
//  Jedinstveni pristup svim protokolima – factory + async/await.
//

import Foundation
import Network

/// Glavni servis za sve protokole – Swift concurrency, actor-based
actor ProtocolService {
    static let shared = ProtocolService()
    
    private init() {}
    
    // MARK: - Transport
    
    func createTCP() -> TCPConnection {
        TCPConnection()
    }
    
    func createUDP() -> UDPConnection {
        UDPConnection()
    }
    
    func createTLS() -> TLSConnection {
        TLSConnection()
    }
    
    // MARK: - HTTP (URLSession – HTTP/1.1, HTTP/2, HTTP/3 kad podržan)
    func fetch(url: URL) async throws -> (Data, URLResponse) {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "Alexandria/1.0 (macOS)"]
        let session = URLSession(configuration: config)
        return try await session.data(from: url)
    }
    
    func createWebSocket(url: URL) -> URLSessionWebSocketTask {
        URLSession.shared.webSocketTask(with: url)
    }
    
    // MARK: - DNS
    func resolveDNS(host: String) async throws -> [String] {
        try await DNSService.lookup(host: host)
    }
}
