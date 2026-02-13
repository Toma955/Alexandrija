//
//  ProtocolRegistry.swift
//  Alexandria
//
//  Registar svih podržanih protokola – IP, TCP, UDP, QUIC, TLS, HTTP, WebSocket, itd.
//

import Foundation

// MARK: - Kategorije protokola
enum ProtocolCategory: String, CaseIterable {
    case transport = "Transport"
    case security = "Sigurnost"
    case web = "Web & aplikacije"
    case communication = "Komunikacija"
    case files = "Datoteke"
    case services = "Mrežne usluge"
    case streaming = "Streaming & real-time"
    case auth = "Autentikacija & identitet"
    case other = "Ostalo"
}

// MARK: - Status implementacije
enum ProtocolStatus: String {
    case implemented = "Implementirano"
    case partial = "Djelomično"
    case stub = "Stub (placeholder)"
    case planned = "Planirano"
}

// MARK: - Definicija protokola
struct ProtocolDefinition: Identifiable {
    let id: String
    let name: String
    let description: String
    let category: ProtocolCategory
    let status: ProtocolStatus
    let scheme: String?
}

// MARK: - Registar protokola
enum ProtocolRegistry {
    static let all: [ProtocolDefinition] = [
        // Transport
        .init(id: "ip", name: "IP", description: "Adresiranje paketa (Internet Protocol)", category: .transport, status: .implemented, scheme: nil),
        .init(id: "tcp", name: "TCP", description: "Pouzdan prijenos", category: .transport, status: .implemented, scheme: nil),
        .init(id: "udp", name: "UDP", description: "Brzi, nepouzdan prijenos", category: .transport, status: .implemented, scheme: nil),
        .init(id: "quic", name: "QUIC", description: "Moderni UDP-based transport (brz, enkriptiran)", category: .transport, status: .partial, scheme: nil),
        
        // Sigurnost
        .init(id: "tls", name: "TLS/SSL", description: "Enkripcija prometa", category: .security, status: .implemented, scheme: nil),
        .init(id: "dtls", name: "DTLS", description: "TLS za UDP", category: .security, status: .stub, scheme: nil),
        .init(id: "ipsec", name: "IPSec", description: "Enkripcija na mrežnoj razini", category: .security, status: .planned, scheme: nil),
        .init(id: "ssh", name: "SSH", description: "Siguran remote pristup", category: .security, status: .stub, scheme: "ssh"),
        
        // Web & aplikacije
        .init(id: "http", name: "HTTP", description: "Web protokol", category: .web, status: .implemented, scheme: "http"),
        .init(id: "https", name: "HTTPS", description: "HTTP preko TLS", category: .web, status: .implemented, scheme: "https"),
        .init(id: "http2", name: "HTTP/2", description: "Multiplexing, brži", category: .web, status: .implemented, scheme: nil),
        .init(id: "http3", name: "HTTP/3", description: "Preko QUIC-a", category: .web, status: .partial, scheme: nil),
        .init(id: "websocket", name: "WebSocket", description: "Real-time dvosmjerni kanal", category: .web, status: .implemented, scheme: "ws"),
        .init(id: "websockets", name: "WebSocket Secure", description: "WebSocket preko TLS", category: .web, status: .implemented, scheme: "wss"),
        .init(id: "webrtc", name: "WebRTC", description: "P2P audio/video/data", category: .web, status: .stub, scheme: nil),
        
        // Komunikacija
        .init(id: "smtp", name: "SMTP", description: "Slanje maila", category: .communication, status: .stub, scheme: "smtp"),
        .init(id: "imap", name: "IMAP", description: "Dohvat maila", category: .communication, status: .stub, scheme: "imap"),
        .init(id: "pop3", name: "POP3", description: "Dohvat maila", category: .communication, status: .stub, scheme: "pop3"),
        .init(id: "xmpp", name: "XMPP", description: "Chat", category: .communication, status: .stub, scheme: "xmpp"),
        .init(id: "sip", name: "SIP", description: "VoIP signalizacija", category: .communication, status: .stub, scheme: "sip"),
        
        // Datoteke
        .init(id: "ftp", name: "FTP", description: "Prijenos datoteka", category: .files, status: .implemented, scheme: "ftp"),
        .init(id: "ftps", name: "FTPS", description: "FTP preko TLS", category: .files, status: .stub, scheme: "ftps"),
        .init(id: "sftp", name: "SFTP", description: "File transfer preko SSH", category: .files, status: .stub, scheme: "sftp"),
        .init(id: "smb", name: "SMB", description: "Dijeljenje datoteka (Windows)", category: .files, status: .stub, scheme: "smb"),
        .init(id: "nfs", name: "NFS", description: "Network file system", category: .files, status: .stub, scheme: "nfs"),
        .init(id: "file", name: "file", description: "Lokalne datoteke", category: .files, status: .implemented, scheme: "file"),
        
        // Mrežne usluge
        .init(id: "dns", name: "DNS", description: "Pretvara domene u IP", category: .services, status: .implemented, scheme: nil),
        .init(id: "dhcp", name: "DHCP", description: "Dodjela IP adresa", category: .services, status: .stub, scheme: nil),
        .init(id: "snmp", name: "SNMP", description: "Monitoring mreže", category: .services, status: .stub, scheme: nil),
        .init(id: "ldap", name: "LDAP", description: "Direktoriji/autentikacija", category: .services, status: .stub, scheme: "ldap"),
        .init(id: "ntp", name: "NTP", description: "Sinkronizacija vremena", category: .services, status: .stub, scheme: nil),
        
        // Streaming
        .init(id: "rtp", name: "RTP/RTCP", description: "Audio/video stream", category: .streaming, status: .stub, scheme: nil),
        .init(id: "rtsp", name: "RTSP", description: "Kontrola streama", category: .streaming, status: .stub, scheme: "rtsp"),
        .init(id: "hls", name: "HLS", description: "Video streaming", category: .streaming, status: .stub, scheme: nil),
        .init(id: "dash", name: "DASH", description: "Video streaming", category: .streaming, status: .stub, scheme: nil),
        
        // Auth
        .init(id: "oauth2", name: "OAuth 2.0", description: "Autorizacija", category: .auth, status: .stub, scheme: nil),
        .init(id: "oidc", name: "OIDC", description: "Login layer iznad OAuth-a", category: .auth, status: .stub, scheme: nil),
        .init(id: "saml", name: "SAML", description: "Enterprise SSO", category: .auth, status: .stub, scheme: nil),
        .init(id: "kerberos", name: "Kerberos", description: "Mrežna autentikacija", category: .auth, status: .stub, scheme: nil),
        
        // Ostalo
        .init(id: "mqtt", name: "MQTT", description: "IoT messaging", category: .other, status: .stub, scheme: "mqtt"),
        .init(id: "amqp", name: "AMQP", description: "Message queue", category: .other, status: .stub, scheme: "amqp"),
        .init(id: "grpc", name: "gRPC", description: "RPC preko HTTP/2", category: .other, status: .stub, scheme: nil),
        .init(id: "bittorrent", name: "BitTorrent", description: "P2P dijeljenje", category: .other, status: .stub, scheme: nil),
    ]
    
    static func byCategory(_ category: ProtocolCategory) -> [ProtocolDefinition] {
        all.filter { $0.category == category }
    }
    
    static func byStatus(_ status: ProtocolStatus) -> [ProtocolDefinition] {
        all.filter { $0.status == status }
    }
    
    static func forScheme(_ scheme: String) -> ProtocolDefinition? {
        all.first { $0.scheme?.lowercased() == scheme.lowercased() }
    }
}
