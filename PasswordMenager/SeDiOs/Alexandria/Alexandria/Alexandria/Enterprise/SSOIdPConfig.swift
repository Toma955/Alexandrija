//
//  SSOIdPConfig.swift
//  Alexandria
//
//  Priprema: SSO/IdP – Microsoft Entra ID, Okta, Keycloak, MFA, conditional access.
//  NIGDJE SE NE UKLJUČUJE – samo modeli i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - IdP tip

enum IdentityProviderType: String, Codable {
    case entraID = "entra"
    case okta = "okta"
    case keycloak = "keycloak"
    case customOIDC = "custom_oidc"
}

/// Konfiguracija jednog IdP-a (OIDC/OAuth2).
struct IdPConfig: Codable {
    var type: IdentityProviderType
    var issuerURL: String
    var clientID: String
    var redirectURI: String
    var scopes: [String]
    var requireMFA: Bool
    var conditionalAccessPolicyId: String?  // za Entra
}

/// Session nakon uspješne autentikacije (stub).
struct SSOSession: Codable {
    var accessToken: String?
    var refreshToken: String?
    var idToken: String?
    var expiresAt: Date?
    var mfaVerified: Bool
}

// MARK: - Stub servis (ne poziva se)

enum SSOIdPService {
    static func currentIdPConfig() -> IdPConfig? { nil }

    static func login(completion: @escaping (Result<SSOSession, Error>) -> Void) {
        completion(.failure(NSError(domain: "SSO", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nije implementirano"])))
    }

    static func refreshSession() async throws -> SSOSession {
        throw NSError(domain: "SSO", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nije implementirano"])
    }

    static func logout() {}
}
