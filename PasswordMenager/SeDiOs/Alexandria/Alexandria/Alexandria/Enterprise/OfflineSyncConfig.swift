//
//  OfflineSyncConfig.swift
//  Alexandria
//
//  Priprema: Offline-first – lokalna baza (SQLite), queue promjena, delta sync, retry/backoff, konflikti.
//  NIGDJE SE NE UKLJUČUJE – samo modeli i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - Sync stavka u redu

enum SyncOperationKind: String, Codable {
    case create
    case update
    case delete
}

struct SyncQueueItem: Codable {
    var id: String
    var kind: SyncOperationKind
    var entityType: String
    var entityId: String
    var payload: Data?
    var createdAt: Date
    var retryCount: Int
    var lastError: String?
}

/// Konfiguracija retry/backoff.
struct SyncRetryConfig: Codable {
    var maxRetries: Int
    var initialDelaySeconds: Double
    var maxDelaySeconds: Double
    var backoffMultiplier: Double
}

/// Konfliktnu rezoluciju: server wins, client wins, manual.
enum ConflictResolution: String, Codable {
    case serverWins
    case clientWins
    case manual
}

// MARK: - Stub (ne poziva se)

enum OfflineSyncService {
    static func retryConfig() -> SyncRetryConfig {
        SyncRetryConfig(maxRetries: 5, initialDelaySeconds: 1, maxDelaySeconds: 60, backoffMultiplier: 2)
    }

    static func enqueue(_ item: SyncQueueItem) {}
    static func processQueue() async {}
    static func resolveConflict(entityId: String, resolution: ConflictResolution) {}
}
