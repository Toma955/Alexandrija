//
//  BrowserNetworkingService.swift
//  Alexandria
//
//  Mrežni servis – HTTP/HTTPS/HTTP2/HTTP3, WebSocket, TCP, UDP, TLS, DNS, ZIP.
//  Swift concurrency, QUIC-ready, STREAM/SUBSCRIBE/EVENTS.
//

import Foundation

// MARK: - Podržani protokoli (prošireno)
enum BrowserProtocol: String, CaseIterable {
    case http, https, ws, wss, ftp, file
    case smtp, imap, pop3, xmpp, sip
    case ftps, sftp, smb, nfs
    case ldap, mqtt, amqp
    case rtsp
}

// MARK: - Browser Networking Service (async/await, multithreading-ready)
final class BrowserNetworkingService {
    static let shared = BrowserNetworkingService()
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.httpAdditionalHeaders = [
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate, br",
            "User-Agent": "Alexandria/1.0 (macOS; App Browser)"
        ]
        // HTTP/2 i HTTP/3 (QUIC) – URLSession automatski koristi kad server podržava
        #if os(iOS)
        config.multipathServiceType = .handover
        #endif
        self.session = URLSession(configuration: config)
    }

    /// Rezultat fetcha – omogućuje provjeru status koda bez bacanja greške na 4xx/5xx
    enum FetchOutcome {
        case success(Data, HTTPURLResponse)
        case httpError(statusCode: Int, data: Data?, response: HTTPURLResponse)
        case transportError(Error)
    }

    /// Fetch koji vraća status kod – ne baca grešku na 4xx/5xx, samo na mrežne greške
    func fetchWithStatus(url: URL) async -> FetchOutcome {
        let isLocal = url.scheme?.lowercased() == "file"
        if !isLocal && !AppSettings.isInternetEnabled {
            return .transportError(NSError(domain: "BrowserNetworkingService", code: -1,
                                          userInfo: [NSLocalizedDescriptionKey: "Internet isključen u postavkama"]))
        }
        if isLocal {
            do {
                let data = try Data(contentsOf: url)
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return .success(data, response)
            } catch {
                return .transportError(error)
            }
        }
        return await withCheckedContinuation { continuation in
            session.dataTask(with: url) { data, response, error in
                if let error = error {
                    continuation.resume(returning: .transportError(error))
                    return
                }
                guard let http = response as? HTTPURLResponse else {
                    continuation.resume(returning: .transportError(NSError(domain: "BrowserNetworkingService", code: -2,
                                                                           userInfo: [NSLocalizedDescriptionKey: "Nepoznat odgovor"])))
                    return
                }
                if (200...299).contains(http.statusCode) {
                    continuation.resume(returning: .success(data ?? Data(), http))
                } else {
                    continuation.resume(returning: .httpError(statusCode: http.statusCode, data: data, response: http))
                }
            }.resume()
        }
    }

    // MARK: - HTTP/HTTPS GET (HTTP/1.1, HTTP/2, HTTP/3)
    func fetch(url: URL) async throws -> (Data, URLResponse) {
        let isLocal = url.scheme?.lowercased() == "file"
        if !isLocal && !AppSettings.isInternetEnabled {
            throw NSError(domain: "BrowserNetworkingService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Internet isključen u postavkama"])
        }
        return try await session.data(from: url)
    }

    // MARK: - HTTP/HTTPS POST
    func post(url: URL, body: Data, contentType: String = "application/json") async throws -> (Data, URLResponse) {
        let isLocal = url.scheme?.lowercased() == "file"
        if !isLocal && !AppSettings.isInternetEnabled {
            throw NSError(domain: "BrowserNetworkingService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Internet isključen u postavkama"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        return try await session.data(for: request)
    }

    // MARK: - JSON
    func fetchJSON<T: Decodable>(url: URL) async throws -> T {
        let (data, _) = try await fetch(url: url)
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - URL validation
    func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string),
              let scheme = url.scheme?.lowercased() else { return false }
        return BrowserProtocol.allCases.map(\.rawValue).contains(scheme)
    }

    // MARK: - WebSocket
    func createWebSocket(url: URL) -> URLSessionWebSocketTask {
        session.webSocketTask(with: url)
    }
    
    // MARK: - DNS (delegira na DNSService)
    func resolve(host: String) async throws -> [String] {
        try await DNSService.lookup(host: host)
    }
}

// MARK: - ZIP raspakiranje (placeholder – za punu podršku dodaj ZIPFoundation)
enum ZipService {
    static func unzip(data: Data) throws -> [String: Data] {
        guard let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ZipService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No cache dir"])
        }
        let zipURL = dir.appendingPathComponent(UUID().uuidString + ".zip")
        try data.write(to: zipURL)
        defer { try? FileManager.default.removeItem(at: zipURL) }
        // Process + unzip za macOS
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        let outDir = dir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: outDir) }
        process.arguments = ["-o", zipURL.path, "-d", outDir.path]
        try process.run()
        process.waitUntilExit()
        var result: [String: Data] = [:]
        if let enumerator = FileManager.default.enumerator(at: outDir, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.isFileURL, let data = try? Data(contentsOf: fileURL) {
                    let relPath = fileURL.path.replacingOccurrences(of: outDir.path + "/", with: "")
                    result[relPath] = data
                }
            }
        }
        return result
    }
}
