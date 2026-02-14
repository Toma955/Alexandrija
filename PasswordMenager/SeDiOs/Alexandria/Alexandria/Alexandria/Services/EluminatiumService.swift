//
//  EluminatiumService.swift
//  Alexandria
//
//  Alexandria ne pretražuje web – koristi odabrani pretraživač (protokol). Pretraživač također
//  ne pretražuje web, samo svoj app library (katalog). Ovaj servis šalje upite na njegov URL.
//

import Foundation
import SwiftUI

/// Izvor upita – odakle dolazi zahtjev
enum EluminatiumRequestSource: String {
    case island = "Island"
    case searchBar = "Search bar"
    case suggestions = "Suggestions"
    case url = "URL"
    case connect = "Spajanje"
}

/// Stavka iz Eluminatium API-ja (name, description, icon, zipHash za preskakanje preuzimanja)
struct EluminatiumAppCatalogItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let zipFile: String
    let iconUrl: String?
    /// SHA-256 hash zipa – ako lokalna app ima isti naziv i hash, ne preuzimaj ponovo
    let zipHash: String?
    /// Ako postoji, Alexandria prikazuje pravi web (HTML/CSS/JS) u WKWebView umjesto DSL-a
    let webURL: String?
}

struct EluminatiumSearchResponse: Codable {
    let exists: Bool?
    let message: String?
    let apps: [EluminatiumAppCatalogItem]
}

final class EluminatiumService {
    static let shared = EluminatiumService()
    
    private var baseURL: String {
        let url = SearchEngineManager.shared.selectedEngineURL
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/$", with: "", options: .regularExpression)
        return url
    }
    
    private init() {}
    
    private func log(_ text: String, type: ConsoleMessageType = .info) {
        Task { @MainActor in
            ConsoleStore.shared.log(text, type: type)
        }
    }

    /// Uspostavi vezu i preuzmi UI pretraživača (Swift kod s backenda)
    func fetchSearchUI() async throws -> String {
        guard !baseURL.isEmpty else {
            log("Nema postavljenog servera – dodaj u postavkama", type: .error)
            throw NSError(domain: "EluminatiumService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Dodaj server u postavkama"])
        }
        let urlString = "\(baseURL)/api/ui"
        guard let url = URL(string: urlString) else {
            log("Neispravan URL: \(urlString)", type: .error)
            throw NSError(domain: "EluminatiumService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Neispravan URL"])
        }
        log("[\(EluminatiumRequestSource.connect.rawValue)] Šaljem: GET \(urlString)", type: .info)
        let outcome = await BrowserNetworkingService.shared.fetchWithStatus(url: url)
        switch outcome {
        case .success(let data, let http):
            log("[\(EluminatiumRequestSource.connect.rawValue)] Odgovor: \(http.statusCode), veličina \(data.count) B", type: .info)
            if http.statusCode == 200 {
                log("[\(EluminatiumRequestSource.connect.rawValue)] Server pokrenut ✓", type: .info)
            }
            let json = try JSONDecoder().decode(EluminatiumDSLResponse.self, from: data)
            guard let dsl = json.dsl else {
                log("[\(EluminatiumRequestSource.connect.rawValue)] Swift kod nije u odgovoru: \(json.message ?? "—")", type: .error)
                throw NSError(domain: "EluminatiumService", code: -1, userInfo: [NSLocalizedDescriptionKey: json.message ?? "Nema"])
            }
            log("[\(EluminatiumRequestSource.connect.rawValue)] Vraćeno: Swift \(dsl.count) znakova", type: .info)
            log("Spojeno na server ✓ \(baseURL)", type: .info)
            return dsl
        case .httpError(let statusCode, _, _):
            log("[\(EluminatiumRequestSource.connect.rawValue)] HTTP greška: \(statusCode)", type: .error)
            throw HTTPStatusError(statusCode: statusCode, message: "Server vraća \(statusCode)")
        case .transportError(let error):
            log("[\(EluminatiumRequestSource.connect.rawValue)] Server nije dostupan: \(error.localizedDescription)", type: .error)
            throw error
        }
    }
    
    /// Pošalji upit odabranom pretraživaču (protokol) – pretragu obavlja pretraživač, ne Alexandria.
    func search(query: String, source: EluminatiumRequestSource = .searchBar) async throws -> [EluminatiumAppCatalogItem] {
        guard !baseURL.isEmpty else {
            log("[\(source.rawValue)] Nema postavljenog servera", type: .error)
            throw NSError(domain: "EluminatiumService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Dodaj server u postavkama"])
        }
        var urlString = "\(baseURL)/api/search"
        if !query.isEmpty {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            urlString += "?q=\(encoded)"
        } else {
            urlString = "\(baseURL)/api/apps"
        }
        guard let url = URL(string: urlString) else {
            log("[\(source.rawValue)] Neispravan URL", type: .error)
            throw NSError(domain: "EluminatiumService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Neispravan URL"])
        }
        log("[\(source.rawValue)] Izvor: \(source.rawValue) | Šaljem: GET \(urlString)", type: .info)
        do {
            let (data, urlResponse) = try await BrowserNetworkingService.shared.fetch(url: url)
            if let http = urlResponse as? HTTPURLResponse {
                log("[\(source.rawValue)] Odgovor: \(http.statusCode), veličina \(data.count) B", type: .info)
            }
            let searchResponse = try JSONDecoder().decode(EluminatiumSearchResponse.self, from: data)
            let apps = searchResponse.apps
            log("[\(source.rawValue)] Tražio: \"\(query)\" → \(apps.count) rezultata", type: .info)
            log("[\(source.rawValue)] Vraćeno: \(apps.count) appova" + (apps.isEmpty ? " (prazno)" : " – \(apps.prefix(3).map(\.name).joined(separator: ", "))\(apps.count > 3 ? "…" : "")"), type: .info)
            return apps
        } catch {
            log("[\(source.rawValue)] Greška: \(error.localizedDescription)", type: .error)
            throw error
        }
    }
    
    /// Preuzmi zip aplikacije
    func downloadZip(appId: String) async throws -> Data {
        guard !baseURL.isEmpty else {
            log("Download: Nema postavljenog servera", type: .error)
            throw NSError(domain: "EluminatiumService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Dodaj server u postavkama"])
        }
        let urlString = "\(baseURL)/api/apps/\(appId)/download"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "EluminatiumService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Neispravan URL"])
        }
        log("Preuzimanje webapp: \(appId)", type: .info)
        log("Download: Šaljem GET \(urlString)", type: .info)
        do {
            let (data, response) = try await BrowserNetworkingService.shared.fetch(url: url)
            if let http = response as? HTTPURLResponse {
                log("Download: \(appId) – odgovor \(http.statusCode), preuzeto \(data.count) B", type: .info)
                log("Preuzeto: \(appId) (\(data.count) B) ✓", type: .info)
            }
            await MainActor.run {
                DownloadTracker.shared.add(url: url.absoluteString, filename: "\(appId).zip", sizeBytes: Int64(data.count))
            }
            return data
        } catch {
            log("Download: \(appId) – greška \(error.localizedDescription)", type: .error)
            throw error
        }
    }
    
    /// Preuzmi Swift izvornik (.swift) s backenda – samo izvornik, bez parsiranja.
    func fetchSource(appId: String) async throws -> String {
        guard !baseURL.isEmpty else {
            throw NSError(domain: "EluminatiumService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Dodaj server u postavkama"])
        }
        let urlString = "\(baseURL)/api/apps/\(appId)/dsl"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "EluminatiumService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Neispravan URL"])
        }
        log("Swift: GET \(urlString)", type: .info)
        let (data, _) = try await BrowserNetworkingService.shared.fetch(url: url)
        let json = try JSONDecoder().decode(EluminatiumDSLResponse.self, from: data)
        guard let source = json.dsl else {
            throw NSError(domain: "EluminatiumService", code: -1, userInfo: [NSLocalizedDescriptionKey: json.message ?? "Nema"])
        }
        log("Swift: \(appId) – preuzeto \(source.count) znakova", type: .info)
        return source
    }
}

/// Greška s HTTP status kodom – za prikaz interne stranice
struct HTTPStatusError: Error {
    let statusCode: Int
    let message: String?
}

struct EluminatiumDSLResponse: Codable {
    let exists: Bool?
    let message: String?
    let dsl: String?
    let app: EluminatiumDSLApp?
}

struct EluminatiumDSLApp: Codable {
    let id: String?
    let name: String?
}
