//
//  UpdateSystemConfig.swift
//  Alexandria
//
//  Priprema: Update sustav – potpisani update-i, delta update, staged rollout, rollback, offline repozitorij (intranet).
//  NIGDJE SE NE UKLJUČUJE – samo modeli i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - Izvor updatea

struct UpdateSourceConfig: Codable {
    var baseURL: String
    var useDelta: Bool
    var requireSignature: Bool
    var publicKeyForVerification: String?
}

/// Jedna verzija u manifestu.
struct UpdateManifestEntry: Codable {
    var version: String
    var build: Int
    var fullURL: String?
    var deltaURL: String?
    var signature: String?
    var minOSVersion: String?
}

// MARK: - Stub (ne poziva se)

enum UpdateSystemService {
    static func updateSource() -> UpdateSourceConfig? { nil }

    static func checkForUpdates() async -> UpdateManifestEntry? { nil }

    static func installUpdate(_ entry: UpdateManifestEntry) async throws {
        _ = entry
    }

    static func rollback() async throws {}
}
