//
//  NetworkLockdownConfig.swift
//  Alexandria
//
//  Priprema: Network lock-down – allowlist domena/IP, blok ostalog, proxy, custom DNS.
//  NIGDJE SE NE UKLJUČUJE – samo konfiguracija i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - Pravila mreže

/// Način provjere: dozvoli samo navedeno (allowlist) ili blokiraj navedeno (blocklist).
enum NetworkFilterMode: String, Codable {
    case allowlist
    case blocklist
}

/// Jedan unos u listi – domena (npr. "internal.company.com") ili IP/CIDR (npr. "10.0.0.0/8").
struct NetworkRule: Codable, Equatable {
    let value: String  // domena ili IP/CIDR
    let isDomain: Bool
    var comment: String?
}

/// Konfiguracija proxyja – obavezan proxy za sve ili za odredene domene.
struct ProxyConfig: Codable {
    var enabled: Bool
    var host: String
    var port: Int
    var useTLS: Bool
    var username: String?
    var passwordRef: String?  // referenca na Keychain
    var bypassRules: [NetworkRule]?  // domene koje ne idu kroz proxy
}

/// Custom DNS – serveri koji zamjenjuju sustavski DNS za resolve.
struct CustomDNSConfig: Codable {
    var enabled: Bool
    var servers: [String]  // npr. ["10.0.0.1", "10.0.0.2"]
    var searchDomains: [String]
}

// MARK: - Glavna konfiguracija lock-downa

struct NetworkLockdownConfig: Codable {
    var filterMode: NetworkFilterMode
    var rules: [NetworkRule]
    var proxy: ProxyConfig?
    var customDNS: CustomDNSConfig?
    var requireVPN: Bool  // za buduću provjeru da je VPN aktivan
}

// MARK: - Stub provjere (ne poziva se)

enum NetworkLockdownPolicy {
    /// Vraća true ako je URL/domena dozvoljena prema konfiguraciji. Stub – uvijek true.
    static func isAllowed(host: String, url: URL) -> Bool {
        _ = host; _ = url
        return true
    }

    /// Vraća trenutnu konfiguraciju (iz UserDefaults ili MDM). Stub – default.
    static func currentConfig() -> NetworkLockdownConfig {
        NetworkLockdownConfig(
            filterMode: .allowlist,
            rules: [],
            proxy: nil,
            customDNS: nil,
            requireVPN: false
        )
    }
}
