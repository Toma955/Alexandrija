//
//  AppManifestResolver.swift
//  Alexandria
//
//  Pravilo: samo jedan main. Manifest (alexandria.json) može eksplicitno odrediti
//  entry point; inače se koristi postojeća logika u AppInstallService.
//  Paket može sadržavati više .swift i .ll/.bc datoteka – pokreće se samo main.
//

import Foundation

/// Dozvoljene ekstenzije za main (Swift ili LLVM IR)
private let mainAllowedExtensions = ["swift", "alexandria", "ll", "bc"]

/// Imena manifest datoteka (prvi pronađen se koristi)
private let manifestNames = ["alexandria.json", "manifest.json"]

// MARK: - Manifest model

/// Manifest u rootu app paketa – određuje točno jedan main (entry point).
struct AppManifest: Codable {
    /// Relativna staza do glavne datoteke (npr. "index.swift" ili "src/main.ll")
    let main: String
}

// MARK: - Resolver

enum AppManifestResolver {

    /// Vraća entry point ako postoji valjani manifest s jednim main-om; inače nil (koristi se fallback).
    /// Pravilo: postoji samo jedan main – manifest ga eksplicitno imenuje.
    static func resolveEntryPoint(in folder: URL, fileManager: FileManager = .default) -> String? {
        guard let manifest = loadManifest(in: folder, fileManager: fileManager) else {
            return nil
        }
        let mainPath = manifest.main.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !mainPath.isEmpty else { return nil }

        // Normaliziraj: ukloni vodeći /
        let normalized = mainPath.hasPrefix("/") ? String(mainPath.dropFirst()) : mainPath
        let entryURL = folder.appendingPathComponent(normalized)

        guard fileManager.fileExists(atPath: entryURL.path) else {
            return nil
        }
        let ext = (normalized as NSString).pathExtension.lowercased()
        guard mainAllowedExtensions.contains(ext) else {
            return nil
        }
        return normalized
    }

    /// Učitava manifest iz prvog pronađenog alexandria.json / manifest.json u rootu
    private static func loadManifest(in folder: URL, fileManager: FileManager) -> AppManifest? {
        for name in manifestNames {
            let url = folder.appendingPathComponent(name)
            guard fileManager.fileExists(atPath: url.path),
                  let data = try? Data(contentsOf: url),
                  let manifest = try? JSONDecoder().decode(AppManifest.self, from: data) else {
                continue
            }
            return manifest
        }
        return nil
    }

    /// Lista svih Swift i LLVM IR datoteka u folderu (relativne staze). Za info/validaciju.
    static func listSourceFiles(in folder: URL, fileManager: FileManager = .default) -> [String] {
        var out: [String] = []
        let basePath = folder.path + "/"
        guard let enumerator = fileManager.enumerator(at: folder, includingPropertiesForKeys: [.isRegularFileKey]) else {
            return out
        }
        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            guard mainAllowedExtensions.contains(ext) else { continue }
            let rel = url.path.replacingOccurrences(of: basePath, with: "")
            if !rel.isEmpty { out.append(rel) }
        }
        return out.sorted()
    }
}
