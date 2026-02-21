//
//  DocumentAccessConfig.swift
//  Alexandria
//
//  Priprema: Document access – samo kroz user consent / managed folders, audit svakog pristupa.
//  NIGDJE SE NE UKLJUČUJE – samo modeli i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - Managed folder

struct ManagedFolder: Codable {
    var id: String
    var path: String
    var displayName: String
    var requiresConsent: Bool
    var allowedFileExtensions: [String]?
}

/// Zapis pristupa dokumentu za audit.
struct DocumentAccessAuditEntry: Codable {
    var timestamp: Date
    var userId: String
    var path: String
    var action: String  // "read", "write", "export"
    var consented: Bool
    var correlationId: String?
}

// MARK: - Stub (ne poziva se)

enum DocumentAccessPolicy {
    static func managedFolders() -> [ManagedFolder] { [] }

    static func requestConsent(for path: String, action: String) async -> Bool {
        _ = path; _ = action
        return true
    }

    static func logAccess(_ entry: DocumentAccessAuditEntry) {
        _ = entry
    }
}
