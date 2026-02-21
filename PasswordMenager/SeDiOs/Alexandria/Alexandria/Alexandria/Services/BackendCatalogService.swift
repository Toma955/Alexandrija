//
//  BackendCatalogService.swift
//  Alexandria
//
//  Spajanje na Alexandria backend – preuzimanje kataloga (teme, jezici, plug-ini),
//  cache na disk, preuzimanje pojedinačnih stavki.
//

import Foundation
import SwiftUI

private let catalogFileName = "catalog.json"
private let catalogAPIPath = "/api/alexandria/catalog"

final class BackendCatalogService: ObservableObject {
    static let shared = BackendCatalogService()

    /// Katalog s backenda (cache ili posljednji uspješni fetch).
    @Published private(set) var catalog: BackendCatalogResponse?
    /// Učitavanje kataloga u tijeku.
    @Published private(set) var isSyncing = false
    /// Zadnja greška (mreža ili parsiranje).
    @Published private(set) var lastError: String?
    /// Zadnje uspješno osvježavanje kataloga.
    @Published private(set) var lastSyncDate: Date?

    /// Snapshot preuzetih tema (da UI osvježi nakon Preuzmi).
    @Published private(set) var installedThemeIdsSnapshot: [String] = []
    @Published private(set) var installedLanguageIdsSnapshot: [String] = []
    @Published private(set) var installedPluginIdsSnapshot: [String] = []

    /// Id-evi stavki koje se trenutno preuzimaju (za indikator u UI).
    @Published private(set) var downloadingThemeIds: Set<String> = []
    @Published private(set) var downloadingLanguageIds: Set<String> = []
    @Published private(set) var downloadingPluginIds: Set<String> = []

    private let fileManager = FileManager.default

    private var baseURL: String {
        let custom = AppSettings.alexandriaBackendBaseURL.trimmingCharacters(in: .whitespaces)
        if !custom.isEmpty { return custom.replacingOccurrences(of: "/$", with: "", options: .regularExpression) }
        let engine = SearchEngineManager.shared.selectedEngineURL
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/$", with: "", options: .regularExpression)
        return engine
    }

    /// Root za cache: Application Support/Alexandria
    private var alexandriaSupportURL: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Alexandria")
    }

    /// Mapa za catalog.json i metadata.
    private var catalogDirectoryURL: URL? {
        guard let root = alexandriaSupportURL else { return nil }
        let dir = root.appendingPathComponent("Catalog")
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Mapa za preuzete teme (po id-u podmapa).
    var themesDirectoryURL: URL? {
        guard let root = alexandriaSupportURL else { return nil }
        let dir = root.appendingPathComponent("Themes")
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Mapa za preuzete jezične pakete.
    var languagesDirectoryURL: URL? {
        guard let root = alexandriaSupportURL else { return nil }
        let dir = root.appendingPathComponent("Languages")
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Mapa za preuzete plug-ine.
    var pluginsDirectoryURL: URL? {
        guard let root = alexandriaSupportURL else { return nil }
        let dir = root.appendingPathComponent("Plugins")
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private init() {
        loadCachedCatalog()
        refreshInstalledSnapshots()
    }

    private func refreshInstalledSnapshots() {
        installedThemeIdsSnapshot = installedThemeIds()
        installedLanguageIdsSnapshot = installedLanguageIds()
        installedPluginIdsSnapshot = installedPluginIds()
    }

    // MARK: - Cache

    private var catalogCacheFileURL: URL? {
        catalogDirectoryURL?.appendingPathComponent(catalogFileName)
    }

    private func loadCachedCatalog() {
        guard let url = catalogCacheFileURL, fileManager.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(BackendCatalogResponse.self, from: data)
            catalog = decoded
            if let attrs = try? fileManager.attributesOfItem(atPath: url.path), let date = attrs[.modificationDate] as? Date {
                lastSyncDate = date
            }
        } catch {
            lastError = "Cache: \(error.localizedDescription)"
        }
    }

    private func saveCachedCatalog(_ response: BackendCatalogResponse) {
        guard let url = catalogCacheFileURL else { return }
        do {
            let data = try JSONEncoder().encode(response)
            try data.write(to: url)
            catalog = response
            lastSyncDate = Date()
            lastError = nil
        } catch {
            lastError = "Spremanje cachea: \(error.localizedDescription)"
        }
    }

    // MARK: - Fetch kataloga

    /// Maksimalno čekanje za cold start (Render free tier) – do 15 sekundi.
    private static let coldStartMaxWaitSeconds: UInt64 = 15
    private static let coldStartRetryIntervalSeconds: UInt64 = 5

    /// Osvježi katalog s backenda i spremi u cache. Na prvi neuspjeh (npr. cold start) čeka i retrya do ~15 s.
    func fetchCatalog() async {
        guard !baseURL.isEmpty else {
            await MainActor.run {
                lastError = "Nema postavljenog backenda (Postavke → Server kataloga ili Alexandria backend)."
            }
            return
        }
        await MainActor.run { isSyncing = true; lastError = nil }
        defer { Task { @MainActor in isSyncing = false } }
        let urlString = baseURL + catalogAPIPath
        guard let url = URL(string: urlString) else {
            await MainActor.run { lastError = "Neispravan URL: \(urlString)" }
            return
        }
        let deadline = ContinuousClock.now + .seconds(Int64(Self.coldStartMaxWaitSeconds))
        repeat {
            let outcome = await BrowserNetworkingService.shared.fetchWithStatus(url: url)
            switch outcome {
            case .success(let data, let http):
                guard http.statusCode == 200 else {
                    await MainActor.run { lastError = "Server vraća \(http.statusCode)" }
                    return
                }
                do {
                    let response = try JSONDecoder().decode(BackendCatalogResponse.self, from: data)
                    await MainActor.run { saveCachedCatalog(response) }
                } catch {
                    await MainActor.run { lastError = "Parsiranje kataloga: \(error.localizedDescription)" }
                }
                return
            case .httpError(let statusCode, _, _):
                await MainActor.run { lastError = "HTTP \(statusCode)" }
                return
            case .transportError(let err):
                if ContinuousClock.now < deadline {
                    try? await Task.sleep(nanoseconds: Self.coldStartRetryIntervalSeconds * 1_000_000_000)
                } else {
                    await MainActor.run { lastError = err.localizedDescription }
                    return
                }
            }
        } while true
    }

    /// Pogodan za poziv pri pokretanju ako je syncCatalogOnLaunch uključen.
    func syncCatalogIfNeeded() {
        guard AppSettings.syncCatalogOnLaunch, !baseURL.isEmpty else { return }
        Task { await fetchCatalog() }
    }

    /// Ako katalog nije učitan ili je stariji od maxAgeSeconds, osvježi ga (npr. kad korisnik otvori Market).
    func refreshCatalogIfStale(maxAgeSeconds: TimeInterval = 600) {
        guard !baseURL.isEmpty else { return }
        if let last = lastSyncDate, Date().timeIntervalSince(last) < maxAgeSeconds { return }
        Task { await fetchCatalog() }
    }

    // MARK: - Preuzimanje pojedinačnih stavki

    /// Preuzima datoteku s URL-a i sprema u zadanu mapu. Vraća URL spremljene datoteke ili nil.
    func download(urlString: String, to directory: URL, suggestedFileName: String?) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "BackendCatalogService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Neispravan URL"])
        }
        let (data, _) = try await BrowserNetworkingService.shared.fetch(url: url)
        let name = suggestedFileName ?? (url.lastPathComponent.isEmpty ? "download" : url.lastPathComponent)
        let safeName = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? name
        let fileURL = directory.appendingPathComponent(safeName)
        try data.write(to: fileURL)
        return fileURL
    }

    /// Preuzmi temu – zip (s theme.json, pozadina, boje, opcionalno preview) ili samo metadata u theme.json.
    func downloadTheme(_ item: RemoteThemeItem) async throws -> URL? {
        _ = await MainActor.run { downloadingThemeIds.insert(item.id) }
        defer { Task { @MainActor in downloadingThemeIds.remove(item.id) } }
        guard let dir = themesDirectoryURL else { return nil }
        let themeDir = dir.appendingPathComponent(item.id)
        try fileManager.createDirectory(at: themeDir, withIntermediateDirectories: true)
        var result: URL?
        if let downloadURL = item.downloadURL {
            let fileURL = try await download(urlString: downloadURL, to: themeDir, suggestedFileName: "theme.zip")
            if fileURL.pathExtension.lowercased() == "zip",
               let data = try? Data(contentsOf: fileURL),
               let contents = try? ZipService.unzip(data: data) {
                for (relPath, fileData) in contents {
                    let flatName = flattenZipPath(relPath)
                    let dest = themeDir.appendingPathComponent(flatName)
                    if !flatName.isEmpty, !flatName.contains("..") {
                        try? fileManager.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
                        try? fileData.write(to: dest)
                    }
                }
                try? fileManager.removeItem(at: fileURL)
            }
            result = themeDir
        } else if let overrides = item.iconOverrides, !overrides.isEmpty {
            let payload = ThemePackagePayload(id: item.id, name: item.name, version: item.version, iconOverrides: overrides, colors: nil, background: nil)
            let data = try JSONEncoder().encode(payload)
            let themeJsonURL = themeDir.appendingPathComponent("theme.json")
            try data.write(to: themeJsonURL)
            result = themeJsonURL
        }
        await MainActor.run { refreshInstalledSnapshots() }
        return result
    }

    /// Ako je path tipa "custom-dark/theme.json", vraća "theme.json"; inače zadnju komponentu.
    private func flattenZipPath(_ relPath: String) -> String {
        let parts = relPath.split(separator: "/").map(String.init)
        if parts.count > 1 {
            return parts.suffix(from: 1).joined(separator: "/")
        }
        return relPath
    }

    /// Preuzmi jezični paket u Languages/id/ i spremi manifest (ime, locale) za postavke jezika.
    func downloadLanguage(_ item: RemoteLanguageItem) async throws -> URL? {
        _ = await MainActor.run { downloadingLanguageIds.insert(item.id) }
        defer { Task { @MainActor in downloadingLanguageIds.remove(item.id) } }
        guard let dir = languagesDirectoryURL else { return nil }
        let langDir = dir.appendingPathComponent(item.id)
        try fileManager.createDirectory(at: langDir, withIntermediateDirectories: true)
        if let downloadURL = item.downloadURL {
            _ = try await download(urlString: downloadURL, to: langDir, suggestedFileName: nil)
        }
        let manifest = InstalledLanguageManifest(id: item.id, name: item.name, locale: item.locale)
        let manifestData = try JSONEncoder().encode(manifest)
        let manifestURL = langDir.appendingPathComponent("manifest.json")
        try manifestData.write(to: manifestURL)
        await MainActor.run { refreshInstalledSnapshots() }
        return langDir
    }

    /// Preuzmi plug-in u Plugins/id/.
    func downloadPlugin(_ item: RemotePluginItem) async throws -> URL? {
        _ = await MainActor.run { downloadingPluginIds.insert(item.id) }
        defer { Task { @MainActor in downloadingPluginIds.remove(item.id) } }
        guard let dir = pluginsDirectoryURL else { return nil }
        let pluginDir = dir.appendingPathComponent(item.id)
        try fileManager.createDirectory(at: pluginDir, withIntermediateDirectories: true)
        guard let downloadURL = item.downloadURL else { return nil }
        let url = try await download(urlString: downloadURL, to: pluginDir, suggestedFileName: nil)
        await MainActor.run { refreshInstalledSnapshots() }
        return url
    }

    /// Ukloni preuzetu temu (briše mapu Themes/id).
    func removeTheme(id: String) {
        guard let dir = themesDirectoryURL else { return }
        let themeDir = dir.appendingPathComponent(id)
        try? fileManager.removeItem(at: themeDir)
        refreshInstalledSnapshots()
    }

    /// Vraća broj bajtova koje zauzima mapa teme (rekurzivno).
    func themeDirectorySize(id: String) -> Int64? {
        guard let dir = themesDirectoryURL else { return nil }
        let themeDir = dir.appendingPathComponent(id)
        return directorySize(url: themeDir)
    }

    private func directorySize(url: URL) -> Int64? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles) else { return nil }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            total += Int64(size)
        }
        return total
    }

    /// Ukloni preuzeti jezični paket (briše mapu Languages/id).
    func removeLanguage(id: String) {
        guard let dir = languagesDirectoryURL else { return }
        let langDir = dir.appendingPathComponent(id)
        try? fileManager.removeItem(at: langDir)
        refreshInstalledSnapshots()
    }

    /// Ukloni preuzeti plug-in (briše mapu Plugins/id).
    func removePlugin(id: String) {
        guard let dir = pluginsDirectoryURL else { return }
        let pluginDir = dir.appendingPathComponent(id)
        try? fileManager.removeItem(at: pluginDir)
        refreshInstalledSnapshots()
    }

    /// Lista id-eva preuzetih tema (podmape u Themes).
    func installedThemeIds() -> [String] {
        guard let dir = themesDirectoryURL,
              let contents = try? fileManager.contentsOfDirectory(atPath: dir.path) else { return [] }
        return contents.filter { name in
            var isDir: ObjCBool = false
            return fileManager.fileExists(atPath: dir.appendingPathComponent(name).path, isDirectory: &isDir) && isDir.boolValue
        }
    }

    /// ThemeInfo za sve preuzete teme (za ThemeRegistry).
    func installedThemeInfos() -> [ThemeInfo] {
        installedThemeIds().compactMap { loadThemeInfo(installedId: $0) }
    }

    private func loadThemeInfo(installedId: String) -> ThemeInfo? {
        guard let dir = themesDirectoryURL else { return nil }
        let jsonURL = dir.appendingPathComponent(installedId).appendingPathComponent("theme.json")
        if fileManager.fileExists(atPath: jsonURL.path),
           let data = try? Data(contentsOf: jsonURL) {
            if let package = try? JSONDecoder().decode(ThemePackagePayload.self, from: data) {
                return ThemeInfo(id: package.id, displayName: package.name, iconOverrides: package.iconOverrides ?? [:])
            }
            if let remote = try? JSONDecoder().decode(RemoteThemeItem.self, from: data) {
                return ThemeInfo(id: remote.id, displayName: remote.name, iconOverrides: remote.iconOverrides ?? [:])
            }
        }
        if let theme = catalog?.themes?.first(where: { $0.id == installedId }) {
            return ThemeInfo(id: theme.id, displayName: theme.name, iconOverrides: theme.iconOverrides ?? [:])
        }
        return nil
    }

    /// Učitaj cijeli paket teme (theme.json s bojama i pozadinom) za dani id – za primjenu boja kad je tema odabrana.
    func loadThemePackage(themeId: String) -> ThemePackagePayload? {
        guard let dir = themesDirectoryURL else { return nil }
        let jsonURL = dir.appendingPathComponent(themeId).appendingPathComponent("theme.json")
        guard fileManager.fileExists(atPath: jsonURL.path),
              let data = try? Data(contentsOf: jsonURL),
              let package = try? JSONDecoder().decode(ThemePackagePayload.self, from: data) else { return nil }
        return package
    }

    /// Lista id-eva preuzetih jezika.
    func installedLanguageIds() -> [String] {
        guard let dir = languagesDirectoryURL,
              let contents = try? fileManager.contentsOfDirectory(atPath: dir.path) else { return [] }
        return contents.filter { name in
            var isDir: ObjCBool = false
            return fileManager.fileExists(atPath: dir.appendingPathComponent(name).path, isDirectory: &isDir) && isDir.boolValue
        }
    }

    /// Jezici preuzeti s backenda – za odabir u Postavkama → Jezik i font (prikazno ime + locale).
    func installedInterfaceLanguages() -> [InterfaceLanguage] {
        installedLanguageIds().compactMap { loadInterfaceLanguage(installedId: $0) }
    }

    private func loadInterfaceLanguage(installedId: String) -> InterfaceLanguage? {
        guard let dir = languagesDirectoryURL else { return nil }
        let manifestURL = dir.appendingPathComponent(installedId).appendingPathComponent("manifest.json")
        if fileManager.fileExists(atPath: manifestURL.path),
           let data = try? Data(contentsOf: manifestURL),
           let manifest = try? JSONDecoder().decode(InstalledLanguageManifest.self, from: data) {
            return InterfaceLanguage(localeCode: manifest.locale.isEmpty ? manifest.id : manifest.locale, displayName: manifest.name)
        }
        if let lang = catalog?.languages?.first(where: { $0.id == installedId }) {
            return InterfaceLanguage(localeCode: lang.locale.isEmpty ? lang.id : lang.locale, displayName: lang.name)
        }
        return InterfaceLanguage(localeCode: installedId, displayName: installedId)
    }

    /// Lista id-eva preuzetih plug-ina.
    func installedPluginIds() -> [String] {
        guard let dir = pluginsDirectoryURL,
              let contents = try? fileManager.contentsOfDirectory(atPath: dir.path) else { return [] }
        return contents.filter { name in
            var isDir: ObjCBool = false
            return fileManager.fileExists(atPath: dir.appendingPathComponent(name).path, isDirectory: &isDir) && isDir.boolValue
        }
    }
}
