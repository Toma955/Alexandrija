//
//  InstalledApp.swift
//  Alexandria
//
//  Model instalirane aplikacije – folder s .swift datotekama.
//

import Foundation

/// Instalirana Alexandria Swift aplikacija
struct InstalledApp: Identifiable, Equatable {
    let id: UUID
    let name: String
    let folderURL: URL
    /// Relativna staza do glavne .swift datoteke (npr. index.swift)
    let entryPoint: String
    let installedAt: Date
    /// ID u katalogu servera (npr. "youtube") – za usporedbu hasha
    let catalogId: String?
    /// Hash zipa pri instalaciji – ako se podudara s serverom, ne treba ponovno preuzimanje
    let zipHash: String?
    
    /// Pun URL do entry point datoteke
    var entryURL: URL {
        folderURL.appendingPathComponent(entryPoint)
    }
}
