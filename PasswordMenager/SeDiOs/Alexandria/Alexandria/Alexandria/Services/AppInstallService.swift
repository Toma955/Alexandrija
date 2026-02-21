//
//  AppInstallService.swift
//  Alexandria
//
//  Primanje .zip aplikacija, raspakiranje u folder aplikacija, upravljanje listom.
//

import Foundation
import SwiftUI

/// Prioritet imena za entry point: Swift/.alexandria pa LLVM IR (.ll / .bc)
private let entryPointCandidates = ["index.alexandria", "index.swift", "main.swift", "App.swift", "ContentView.swift", "app.alexandria", "index.ll", "main.ll", "App.ll", "index.bc", "main.bc", "App.bc"]

final class AppInstallService: ObservableObject, AppInstallServiceProtocol {
    static let shared = AppInstallService()
    
    /// Folder gdje se instaliraju aplikacije
    var applicationsFolderURL: URL {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return FileManager.default.temporaryDirectory.appendingPathComponent("AlexandriaApps")
        }
        let dir = appSupport.appendingPathComponent("Alexandria").appendingPathComponent("Applications")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    @Published private(set) var installedApps: [InstalledApp] = []
    
    private let fileManager = FileManager.default
    
    private init() {
        loadInstalledApps()
    }
    
    // MARK: - Instalacija
    
    /// Instalira aplikaciju iz .zip datoteke – raspakira u folder i dodaje na listu.
    /// catalogId i zipHash: za HasTable – ako server kasnije pošalje isti hash, preskoči preuzimanje.
    /// webURL: ako postoji, app se prikazuje kao pravi web (WKWebView) umjesto DSL-a.
    func install(from zipURL: URL, suggestedName: String? = nil, catalogId: String? = nil, zipHash: String? = nil, webURL: String? = nil) throws -> InstalledApp {
        guard zipURL.pathExtension.lowercased() == "zip" else {
            throw AppInstallError.notZip
        }
        guard fileManager.fileExists(atPath: zipURL.path) else {
            throw AppInstallError.fileNotFound
        }
        if let attrs = try? fileManager.attributesOfItem(atPath: zipURL.path), let size = attrs[.size] as? Int {
            if !AppLimitsSettings.isZipSizeAllowed(bytes: size) {
                let limit = AppLimitsSettings.maxZipSizeBytes ?? 0
                throw AppInstallError.sizeLimitRequiresPermission(bytes: size, limit: limit)
            }
        }
        
        let appId = UUID()
        let fileBaseName = zipURL.deletingPathExtension().lastPathComponent
        let appFolderName = fileBaseName + "-" + appId.uuidString.prefix(8)
        let destFolder = applicationsFolderURL.appendingPathComponent(appFolderName)
        
        if fileManager.fileExists(atPath: destFolder.path) {
            try fileManager.removeItem(at: destFolder)
        }
        try fileManager.createDirectory(at: destFolder, withIntermediateDirectories: true)
        
        // Raspakiraj
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", zipURL.path, "-d", destFolder.path]
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            try? fileManager.removeItem(at: destFolder)
            throw AppInstallError.unzipFailed
        }
        
        // Pronađi entry point: prvo manifest (samo jedan main), pa postojeći kandidati
        let entryPoint: String
        if let fromManifest = AppManifestResolver.resolveEntryPoint(in: destFolder, fileManager: fileManager) {
            entryPoint = fromManifest
        } else if let fromCandidates = findEntryPoint(in: destFolder) {
            entryPoint = fromCandidates
        } else {
            try? fileManager.removeItem(at: destFolder)
            throw AppInstallError.noEntryPoint
        }
        
        // Ime: suggestedName (npr. iz kataloga) ili ime datoteke; ako je datoteka UUID.zip, ne koristi UUID kao ime
        let appName: String
        if let suggested = suggestedName, !suggested.trimmingCharacters(in: .whitespaces).isEmpty {
            appName = suggested.trimmingCharacters(in: .whitespaces)
        } else if UUID(uuidString: fileBaseName) != nil {
            appName = "App"
        } else {
            appName = fileBaseName
        }
        let sourceFormat = AppSourceFormat.from(entryPoint: entryPoint)
        let allowsSourceInspection = sourceFormat == .swift ? true : false // LLVM IR: ne smije se otvoriti/spremati osim ako aplikacija ne odredi
        let app = InstalledApp(
            id: appId,
            name: appName,
            folderURL: destFolder,
            entryPoint: entryPoint,
            installedAt: Date(),
            sourceFormat: sourceFormat,
            allowsSourceInspection: allowsSourceInspection,
            catalogId: catalogId,
            zipHash: zipHash,
            webURL: webURL
        )
        
        installedApps.append(app)
        saveInstalledApps()
        return app
    }
    
    /// Instalira iz Data (npr. preuzeto s mreže). suggestedName, catalogId, zipHash za HasTable; webURL za prikaz weba.
    func install(from zipData: Data, suggestedName: String? = nil, catalogId: String? = nil, zipHash: String? = nil, webURL: String? = nil) throws -> InstalledApp {
        if !AppLimitsSettings.isZipSizeAllowed(bytes: zipData.count) {
            let limit = AppLimitsSettings.maxZipSizeBytes ?? 0
            throw AppInstallError.sizeLimitRequiresPermission(bytes: zipData.count, limit: limit)
        }
        let tempZip = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".zip")
        try zipData.write(to: tempZip)
        defer { try? fileManager.removeItem(at: tempZip) }
        return try install(from: tempZip, suggestedName: suggestedName, catalogId: catalogId, zipHash: zipHash, webURL: webURL)
    }
    
    /// Instalira iz URL-a (npr. fileImporter) – kopira u temp radi sandbox pristupa
    func install(fromSecurityScopedURL url: URL) throws -> InstalledApp {
        guard url.startAccessingSecurityScopedResource() else {
            throw AppInstallError.fileNotFound
        }
        defer { url.stopAccessingSecurityScopedResource() }
        let tempZip = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".zip")
        try fileManager.copyItem(at: url, to: tempZip)
        defer { try? fileManager.removeItem(at: tempZip) }
        return try install(from: tempZip, suggestedName: nil, catalogId: nil, zipHash: nil)
    }
    
    /// Ako postoji instalirana aplikacija s istim catalogId i zipHash (i nazivom), ne treba je ponovo preuzimati.
    /// Vraća nil ako nema hasha od servera (uvijek preuzimi) ili nema odgovarajuće instalirane app.
    func findInstalledApp(catalogId: String, name: String, zipHash: String?) -> InstalledApp? {
        guard let hash = zipHash, !hash.isEmpty else { return nil }
        return installedApps.first { app in
            app.catalogId == catalogId && app.name == name && app.zipHash == hash
        }
    }
    
    // MARK: - Deinstalacija
    
    func uninstall(_ app: InstalledApp) {
        try? fileManager.removeItem(at: app.folderURL)
        installedApps.removeAll { $0.id == app.id }
        saveInstalledApps()
    }
    
    /// Briše sve instalirane aplikacije (foldere i listu).
    func uninstallAll() {
        for app in installedApps {
            try? fileManager.removeItem(at: app.folderURL)
        }
        installedApps = []
        let indexURL = applicationsFolderURL.appendingPathComponent("installed.json")
        try? fileManager.removeItem(at: indexURL)
    }
    
// MARK: - Učitavanje Swift sadržaja

    /// Učitava Swift izvornik (.swift) iz entry point datoteke
    func loadSource(for app: InstalledApp) throws -> String {
        let url = app.entryURL
        if let attrs = try? fileManager.attributesOfItem(atPath: url.path), let size = attrs[.size] as? Int {
            if !AppLimitsSettings.isMainFileSizeAllowed(bytes: size) {
                let limit = AppLimitsSettings.maxMainFileSizeBytes ?? 0
                throw AppInstallError.sizeLimitRequiresPermission(bytes: size, limit: limit)
            }
        }
        let data = try Data(contentsOf: url)
        guard let str = String(data: data, encoding: .utf8) else {
            throw AppInstallError.invalidEncoding
        }
        return str
    }
    
    // MARK: - Privatno
    
    private func findEntryPoint(in folder: URL) -> String? {
        // Prvo provjeri kandidate u rootu
        for candidate in entryPointCandidates {
            let url = folder.appendingPathComponent(candidate)
            if fileManager.fileExists(atPath: url.path) {
                return candidate
            }
        }
        
        // Zatim rekurzivno traži prvu .swift, .alexandria, .ll ili .bc datoteku
        guard let enumerator = fileManager.enumerator(at: folder, includingPropertiesForKeys: [.isRegularFileKey]) else {
            return nil
        }
        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            if ext == "swift" || ext == "alexandria" || ext == "ll" || ext == "bc" {
                let relPath = url.path.replacingOccurrences(of: folder.path + "/", with: "")
                return relPath
            }
        }
        return nil
    }
    
    private func loadInstalledApps() {
        let indexURL = applicationsFolderURL.appendingPathComponent("installed.json")
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([InstalledAppCodable].self, from: data) else {
            scanFolderForApps()
            return
        }
        installedApps = decoded.compactMap { $0.toInstalledApp(fileManager: fileManager) }
    }
    
    private func scanFolderForApps() {
        guard let contents = try? fileManager.contentsOfDirectory(at: applicationsFolderURL, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return
        }
        var apps: [InstalledApp] = []
        for url in contents where (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            let entry = AppManifestResolver.resolveEntryPoint(in: url, fileManager: fileManager)
                ?? findEntryPoint(in: url)
            if let entry = entry {
                let format = AppSourceFormat.from(entryPoint: entry)
                let allows = format == .swift
                let app = InstalledApp(
                    id: UUID(),
                    name: url.lastPathComponent,
                    folderURL: url,
                    entryPoint: entry,
                    installedAt: Date(),
                    sourceFormat: format,
                    allowsSourceInspection: allows,
                    catalogId: nil,
                    zipHash: nil,
                    webURL: nil
                )
                apps.append(app)
            }
        }
        installedApps = apps
        saveInstalledApps()
    }
    
    private func saveInstalledApps() {
        let indexURL = applicationsFolderURL.appendingPathComponent("installed.json")
        let codable = installedApps.map { InstalledAppCodable(from: $0) }
        guard let data = try? JSONEncoder().encode(codable) else { return }
        try? data.write(to: indexURL)
    }
}

// MARK: - Codable wrapper za persistence
private struct InstalledAppCodable: Codable {
    let id: UUID
    let name: String
    let folderPath: String
    let entryPoint: String
    let installedAt: Date
    let sourceFormatRaw: String?
    let allowsSourceInspection: Bool?
    let catalogId: String?
    let zipHash: String?
    let webURL: String?
    
    init(from app: InstalledApp) {
        id = app.id
        name = app.name
        folderPath = app.folderURL.path
        entryPoint = app.entryPoint
        installedAt = app.installedAt
        sourceFormatRaw = app.sourceFormat.rawValue
        allowsSourceInspection = app.allowsSourceInspection
        catalogId = app.catalogId
        zipHash = app.zipHash
        webURL = app.webURL
    }
    
    func toInstalledApp(fileManager: FileManager) -> InstalledApp? {
        let url = URL(fileURLWithPath: folderPath)
        guard fileManager.fileExists(atPath: url.path),
              fileManager.fileExists(atPath: url.appendingPathComponent(entryPoint).path) else {
            return nil
        }
        let format = sourceFormatRaw.flatMap { AppSourceFormat(rawValue: $0) } ?? AppSourceFormat.from(entryPoint: entryPoint)
        let allows = allowsSourceInspection ?? (format == .swift)
        return InstalledApp(id: id, name: name, folderURL: url, entryPoint: entryPoint, installedAt: installedAt, sourceFormat: format, allowsSourceInspection: allows, catalogId: catalogId, zipHash: zipHash, webURL: webURL)
    }
}

// MARK: - Greške
enum AppInstallError: LocalizedError {
    case notZip
    case fileNotFound
    case unzipFailed
    case noEntryPoint
    case invalidEncoding
    case zipSizeLimitExceeded(bytes: Int, limit: Int)
    case mainFileSizeLimitExceeded(bytes: Int, limit: Int)
    case sizeLimitRequiresPermission(bytes: Int, limit: Int)
    
    var errorDescription: String? {
        switch self {
        case .notZip: return "Datoteka nije .zip"
        case .fileNotFound: return "Datoteka nije pronađena"
        case .unzipFailed: return "Raspakiranje nije uspjelo"
        case .noEntryPoint: return "U .zip-u nema .swift, .ll ili .bc datoteke (traži index.swift, main.ll, App.bc, itd.)"
        case .invalidEncoding: return "Datoteka nije UTF-8"
        case .zipSizeLimitExceeded(let bytes, let limit): return "Zip prevelik: \(bytes) B (limit \(limit) B). Uključi posebnu dozvolu u Postavkama → Ograničenja i dozvole."
        case .mainFileSizeLimitExceeded(let bytes, let limit): return "Main datoteka prevelika: \(bytes) B (limit \(limit) B). Uključi posebnu dozvolu u Postavkama."
        case .sizeLimitRequiresPermission(let bytes, let limit): return "Prekoračen limit (\(bytes) B > \(limit) B). U Postavkama → Ograničenja i dozvole uključi „Dopusti prekoračenje limita”."
        }
    }
}
