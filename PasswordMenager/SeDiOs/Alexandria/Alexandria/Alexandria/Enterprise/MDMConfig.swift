//
//  MDMConfig.swift
//  Alexandria
//
//  Priprema: MDM upravljanje – konfiguracija kroz profile (policy, allowlist, proxy, feature flags) preko Jamf / Microsoft Intune.
//  NIGDJE SE NE UKLJUČUJE – samo modeli i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - MDM payload (čitanje iz UserDefaults / managed preferences)

struct MDMPolicyPayload: Codable {
    var networkAllowlist: [String]?
    var networkBlocklist: [String]?
    var proxyConfig: [String: String]?
    var customDNS: [String]?
    var featureFlags: [String: Bool]?
    var requireVPN: Bool?
    var ssoConfig: [String: String]?
    var dlpConfig: [String: String]?
}

// MARK: - Stub (ne poziva se)

enum MDMConfigService {
    /// Čita managed app config (Intune) ili custom key (Jamf). Stub vraća nil.
    static func readManagedConfig() -> MDMPolicyPayload? {
        // UserDefaults.standard.object(forKey: "com.apple.configuration.managed")
        return nil
    }

    static func isManagedByMDM() -> Bool { false }
}
