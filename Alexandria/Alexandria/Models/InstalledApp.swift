//
//  InstalledApp.swift
//  Alexandria
//
//  Model instalirane aplikacije – folder s .swift datotekama.
//

import Foundation

/// Instalirana Alexandria DSL aplikacija
struct InstalledApp: Identifiable, Equatable {
    let id: UUID
    let name: String
    let folderURL: URL
    /// Relativna staza do glavne .swift datoteke (npr. index.swift)
    let entryPoint: String
    let installedAt: Date
    
    /// Pun URL do entry point datoteke
    var entryURL: URL {
        folderURL.appendingPathComponent(entryPoint)
    }
}
