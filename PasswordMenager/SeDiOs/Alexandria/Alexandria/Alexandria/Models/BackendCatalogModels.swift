//
//  BackendCatalogModels.swift
//  Alexandria
//
//  Modeli za backend katalog – teme, jezici, plug-ini. API vraća listu stavki;
//  preuzimanje po id ili downloadURL.
//

import Foundation

// MARK: - Paket teme (theme.json u zipu) – pozadina, boje, ikone u jednoj datoteci
struct ThemePackagePayload: Codable {
    let id: String
    let name: String
    let version: String?
    let iconOverrides: [String: String]?
    let colors: ThemePackageColors?
    let background: ThemePackageBackground?
}

struct ThemePackageColors: Codable {
    let accentHex: String?
    let barFillHex: String?
    let primaryTextHex: String?
    let secondaryTextHex: String?
}

struct ThemePackageBackground: Codable {
    let type: String?
    let blobColors: [String]?
    let colorHex: String?
    let imagePath: String?
    let gradientStops: [ThemePackageGradientStop]?
}

struct ThemePackageGradientStop: Codable {
    let hex: String
    let position: Double?
}

// MARK: - Teme s backenda
struct RemoteThemeItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    /// URL za preuzimanje zip paketa (unutar: theme.json s pozadinom, bojama, ikonama).
    let downloadURL: String?
    /// URL slike pregleda (kako tema izgleda) – opcionalno.
    let previewImageURL: String?
    /// URL videa pregleda – opcionalno.
    let previewVideoURL: String?
    /// Verzija za cache invalidation.
    let version: String?
    /// Ako backend šalje izravno, mapiranje Island ključeva na SF Symbol nazive.
    let iconOverrides: [String: String]?
}

// MARK: - Jezični paketi s backenda
struct RemoteLanguageItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let locale: String
    let description: String?
    let downloadURL: String?
    let version: String?
}

/// Manifest spremljen u Languages/<id>/manifest.json nakon preuzimanja (ime i locale za prikaz u postavkama).
struct InstalledLanguageManifest: Codable {
    let id: String
    let name: String
    let locale: String
}

// MARK: - Plug-ini s backenda
struct RemotePluginItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let downloadURL: String?
    let version: String?
    let enabledByDefault: Bool?
}

// MARK: - Fontovi s backenda (opcionalno u katalogu)
struct RemoteFontItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let downloadURL: String?
    let version: String?
}

// MARK: - Sigurnosna zakrpa (opcionalno u katalogu)
struct RemoteSecurityPatchItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let downloadURL: String?
    let version: String?
    let severity: String?
    let publishedAt: String?
}

// MARK: - Update ugrađene aplikacije – VPN, Security Agent, Dev Tools, itd. (opcionalno u katalogu)
struct RemoteAppUpdateItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let downloadURL: String?
    let version: String?
    let builtInAppId: String?
}

// MARK: - Odgovor kataloga (GET /api/alexandria/catalog). Sinkronizirano s Alexandria Backend.
struct BackendCatalogResponse: Codable {
    let themes: [RemoteThemeItem]?
    let languages: [RemoteLanguageItem]?
    let plugins: [RemotePluginItem]?
    let fonts: [RemoteFontItem]?
    let swift: RemoteSwiftCatalog?
    let securityPatches: [RemoteSecurityPatchItem]?
    let appUpdates: [RemoteAppUpdateItem]?
    let message: String?
}

/// Swift katalog (verzija, biblioteke) – opcionalno u odgovoru.
struct RemoteSwiftCatalog: Codable {
    let version: String?
    let dslVersion: String?
    let libraries: [RemoteSwiftLibraryItem]?
    let additionalLibraries: [RemoteSwiftLibraryItem]?
}

struct RemoteSwiftLibraryItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let downloadURL: String?
}
