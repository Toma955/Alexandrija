//
//  RBACConfig.swift
//  Alexandria
//
//  Priprema: Role-based access – RBAC/ABAC, least-privilege, capabilities po tenant-u.
//  NIGDJE SE NE UKLJUČUJE – samo modeli i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - Tenant i uloge

struct Tenant: Codable, Equatable {
    var id: String
    var name: String
}

/// Uloga – npr. admin, user, viewer.
struct Role: Codable, Equatable {
    var id: String
    var name: String
    var capabilityIds: [String]
}

/// Capability – dozvola za jednu radnju (npr. "app.install", "app.uninstall", "settings.network").
struct Capability: Codable, Equatable {
    var id: String
    var name: String
    var scope: String?  // optional scope npr. po tenant-u
}

/// Pridružba korisnika/profila tenantu i ulozi.
struct UserRoleAssignment: Codable {
    var userId: String
    var tenantId: String
    var roleId: String
}

// MARK: - Stub provjere (ne poziva se)

enum RBACPolicy {
    static func currentTenant() -> Tenant? { nil }

    static func hasCapability(_ capabilityId: String, tenantId: String?) -> Bool {
        _ = capabilityId; _ = tenantId
        return true
    }

    static func allowedCapabilities(for userId: String, tenantId: String) -> [String] {
        _ = userId; _ = tenantId
        return []
    }
}
