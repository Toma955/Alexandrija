//
//  MTLSCertPinningConfig.swift
//  Alexandria
//
//  Priprema: mTLS + cert pinning – klijentski certifikati, pinning za interne servise.
//  NIGDJE SE NE UKLJUČUJE – samo modeli i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - Pinning tip

enum PinningType: String, Codable {
    case publicKey
    case certificate
    case certificateChain
}

/// Jedan pinning pravilo za host / pattern.
struct CertPinningRule: Codable {
    var hostPattern: String  // npr. "*.internal.company.com" ili "api.company.com"
    var pinningType: PinningType
    var pinnedHashes: [String]  // SHA-256 base64 ili hex
    var backupHashes: [String]?  // za rollover
    var enforce: Bool
}

/// Konfiguracija klijentskog certifikata za mTLS (referenca na identitet u Keychainu).
struct ClientCertConfig: Codable {
    var identityLabel: String?
    var keychainService: String?
    var useForHosts: [String]  // host pattern
}

// MARK: - Glavna konfiguracija

struct MTLSCertPinningConfig: Codable {
    var pinningRules: [CertPinningRule]
    var clientCertConfigs: [ClientCertConfig]
}

// MARK: - Stub (ne poziva se)

enum MTLSCertPinningPolicy {
    static func currentConfig() -> MTLSCertPinningConfig {
        MTLSCertPinningConfig(pinningRules: [], clientCertConfigs: [])
    }

    /// Da li za host treba klijentski cert. Stub.
    static func requiresClientCert(host: String) -> Bool {
        _ = host
        return false
    }

    /// Da li za host treba provjera pinninga. Stub.
    static func shouldVerifyPinning(host: String) -> Bool {
        _ = host
        return false
    }
}
