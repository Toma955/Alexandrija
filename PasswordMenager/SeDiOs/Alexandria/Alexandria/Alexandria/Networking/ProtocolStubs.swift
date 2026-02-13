//
//  ProtocolStubs.swift
//  Alexandria
//
//  Stub implementacije za protokole koji zahtijevaju eksterne biblioteke.
//

import Foundation

// MARK: - SMTP (stub)
enum SMTPService {
    static func send(host: String, port: UInt16, from: String, to: [String], subject: String, body: String) async throws {
        // TODO: Implementacija s TCP + SMTP handshake
        throw ProtocolStubError.notImplemented("SMTP")
    }
}

// MARK: - IMAP (stub)
enum IMAPService {
    static func fetch(host: String, port: UInt16, user: String, password: String) async throws -> [String] {
        throw ProtocolStubError.notImplemented("IMAP")
    }
}

// MARK: - MQTT (stub)
enum MQTTService {
    static func connect(broker: String, port: UInt16) async throws -> MQTTConnection {
        throw ProtocolStubError.notImplemented("MQTT")
    }
}

struct MQTTConnection {}

// MARK: - gRPC (stub)
enum GRPCService {
    static func call(url: URL, method: String, request: Data) async throws -> Data {
        throw ProtocolStubError.notImplemented("gRPC")
    }
}

// MARK: - SFTP (stub)
enum SFTPService {
    static func connect(host: String, port: UInt16, user: String, auth: SFTPAuth) async throws -> SFTPClient {
        throw ProtocolStubError.notImplemented("SFTP")
    }
}

enum SFTPAuth {
    case password(String)
    case key(Data)
}

struct SFTPClient {
    func list(path: String) async throws -> [String] { [] }
    func get(path: String) async throws -> Data { Data() }
    func put(path: String, data: Data) async throws {}
}

// MARK: - NTP (stub)
enum NTPService {
    static func sync(server: String = "time.apple.com") async throws -> Date {
        throw ProtocolStubError.notImplemented("NTP")
    }
}

// MARK: - WebRTC (stub)
enum WebRTCService {
    static func createPeerConnection() async throws -> WebRTCPeerConnection {
        throw ProtocolStubError.notImplemented("WebRTC")
    }
}

struct WebRTCPeerConnection {}

// MARK: - OAuth 2.0 (stub)
enum OAuth2Service {
    static func authorize(url: URL, clientId: String, redirectURI: String) async throws -> String {
        throw ProtocolStubError.notImplemented("OAuth 2.0")
    }
}

enum ProtocolStubError: Error {
    case notImplemented(String)
}
