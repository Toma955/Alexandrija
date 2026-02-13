//
//  BrowserNetworkingService.swift
//  Alexandria
//
//  Mrežni servis za Swift preglednik – HTTP, HTTPS, WebSocket, DNS, ZIP.
//

import Foundation

// MARK: - Podržani protokoli
enum BrowserProtocol: String, CaseIterable {
    case http = "http"
    case https = "https"
    case ws = "ws"
    case wss = "wss"
    case ftp = "ftp"
    case file = "file"
}

// MARK: - Browser Networking Service
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
            "User-Agent": "Alexandria/1.0 (macOS; Swift Browser)"
        ]
        self.session = URLSession(configuration: config)
    }

    // MARK: - HTTP/HTTPS GET
    func fetch(url: URL) async throws -> (Data, URLResponse) {
        try await session.data(from: url)
    }

    // MARK: - HTTP/HTTPS POST
    func post(url: URL, body: Data, contentType: String = "application/json") async throws -> (Data, URLResponse) {
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

    // MARK: - URL validation (DNS se rješava automatski kroz URLSession)
    func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string),
              let scheme = url.scheme?.lowercased() else { return false }
        return BrowserProtocol.allCases.map(\.rawValue).contains(scheme)
    }

    // MARK: - WebSocket (osnova – za punu implementaciju treba URLSessionWebSocketTask)
    func createWebSocket(url: URL) -> URLSessionWebSocketTask {
        session.webSocketTask(with: url)
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
