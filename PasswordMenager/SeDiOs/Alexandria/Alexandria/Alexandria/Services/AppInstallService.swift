//
//  AppInstallService.swift
//  Alexandria
//
//  Primanje .zip aplikacija, raspakiranje u folder aplikacija, upravljanje listom.
//

import Foundation
import SwiftUI

/// Prioritet imena za entry point (glavna .swift datoteka)
private let entryPointCandidates = ["index.swift", "main.swift", "App.swift", "ContentView.swift", "app.alexandria"]

final class AppInstallService: ObservableObject {
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
    func install(from zipURL: URL, suggestedName: String? = nil, catalogId: String? = nil, zipHash: String? = nil) throws -> InstalledApp {
        guard zipURL.pathExtension.lowercased() == "zip" else {
            throw AppInstallError.notZip
        }
        guard fileManager.fileExists(atPath: zipURL.path) else {
            throw AppInstallError.fileNotFound
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
        
        // Pronađi entry point
        guard let entryPoint = findEntryPoint(in: destFolder) else {
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
        let app = InstalledApp(
            id: appId,
            name: appName,
            folderURL: destFolder,
            entryPoint: entryPoint,
            installedAt: Date(),
            catalogId: catalogId,
            zipHash: zipHash
        )
        
        installedApps.append(app)
        saveInstalledApps()
        return app
    }
    
    /// Instalira iz Data (npr. preuzeto s mreže). suggestedName, catalogId i zipHash za HasTable logiku.
    func install(from zipData: Data, suggestedName: String? = nil, catalogId: String? = nil, zipHash: String? = nil) throws -> InstalledApp {
        let tempZip = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".zip")
        try zipData.write(to: tempZip)
        defer { try? fileManager.removeItem(at: tempZip) }
        return try install(from: tempZip, suggestedName: suggestedName, catalogId: catalogId, zipHash: zipHash)
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
        let data = try Data(contentsOf: app.entryURL)
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
        
        // Zatim rekurzivno traži prvu .swift ili .alexandria datoteku
        guard let enumerator = fileManager.enumerator(at: folder, includingPropertiesForKeys: [.isRegularFileKey]) else {
            return nil
        }
        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            if ext == "swift" || ext == "alexandria" {
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
            if let entry = findEntryPoint(in: url) {
                let app = InstalledApp(
                    id: UUID(),
                    name: url.lastPathComponent,
                    folderURL: url,
                    entryPoint: entry,
                    installedAt: Date(),
                    catalogId: nil,
                    zipHash: nil
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
    let catalogId: String?
    let zipHash: String?
    
    init(from app: InstalledApp) {
        id = app.id
        name = app.name
        folderPath = app.folderURL.path
        entryPoint = app.entryPoint
        installedAt = app.installedAt
        catalogId = app.catalogId
        zipHash = app.zipHash
    }
    
    func toInstalledApp(fileManager: FileManager) -> InstalledApp? {
        let url = URL(fileURLWithPath: folderPath)
        guard fileManager.fileExists(atPath: url.path),
              fileManager.fileExists(atPath: url.appendingPathComponent(entryPoint).path) else {
            return nil
        }
        return InstalledApp(id: id, name: name, folderURL: url, entryPoint: entryPoint, installedAt: installedAt, catalogId: catalogId, zipHash: zipHash)
    }
}

// MARK: - Greške
enum AppInstallError: LocalizedError {
    case notZip
    case fileNotFound
    case unzipFailed
    case noEntryPoint
    case invalidEncoding
    
    var errorDescription: String? {
        switch self {
        case .notZip: return "Datoteka nije .zip"
        case .fileNotFound: return "Datoteka nije pronađena"
        case .unzipFailed: return "Raspakiranje nije uspjelo"
        case .noEntryPoint: return "U .zip-u nema .swift datoteke (traži index.swift, main.swift ili App.swift)"
        case .invalidEncoding: return "Datoteka nije UTF-8"
        }
    }
}
