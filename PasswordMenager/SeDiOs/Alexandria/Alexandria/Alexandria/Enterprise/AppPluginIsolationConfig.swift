//
//  AppPluginIsolationConfig.swift
//  Alexandria
//
//  Priprema: App/Plugin model – izolacija po procesu (XPC), dozvole po capability-ju, timeouts, rate-limit.
//  NIGDJE SE NE UKLJUČUJE – samo modeli i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - Capability za plugin

struct PluginCapability: Codable {
    var id: String
    var name: String
    var allowed: Bool
}

/// Konfiguracija jednog plugina / XPC servisa.
struct PluginIsolationConfig: Codable {
    var bundleId: String
    var capabilities: [PluginCapability]
    var timeoutSeconds: Int
    var rateLimitRequestsPerMinute: Int?
}

// MARK: - Stub (ne poziva se)

enum AppPluginIsolationPolicy {
    static func config(for bundleId: String) -> PluginIsolationConfig? {
        _ = bundleId
        return nil
    }

    static func hasCapability(bundleId: String, capabilityId: String) -> Bool {
        _ = bundleId; _ = capabilityId
        return true
    }
}
