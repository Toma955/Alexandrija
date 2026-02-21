//
//  AuditLogConfig.swift
//  Alexandria
//
//  Priprema: Audit & logging – centralni event log, korelacijski ID-ovi, sigurnosni događaji, export u SIEM.
//  NIGDJE SE NE UKLJUČUJE – samo modeli i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - Kategorija događaja

enum AuditEventCategory: String, Codable {
    case security
    case access
    case config
    case network
    case app
    case system
}

struct AuditEvent: Codable {
    var id: String
    var timestamp: Date
    var category: AuditEventCategory
    var action: String
    var userId: String?
    var resource: String?
    var outcome: String?  // "success", "failure"
    var correlationId: String?
    var metadata: [String: String]?
}

// MARK: - Stub (ne poziva se)

enum AuditLogService {
    static func currentCorrelationId() -> String { UUID().uuidString }

    static func log(_ event: AuditEvent) {
        _ = event
    }

    static func exportForSIEM(format: String) -> Data? {
        _ = format
        return nil
    }
}
