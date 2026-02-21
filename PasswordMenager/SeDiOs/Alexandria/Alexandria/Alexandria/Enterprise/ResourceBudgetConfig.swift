//
//  ResourceBudgetConfig.swift
//  Alexandria
//
//  Priprema: Resource manager – RAM/CPU/GPU/ML budžeti po tabu/modulu, suspend/kill background.
//  NIGDJE SE NE UKLJUČUJE – samo konfiguracija i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - Budžet po tabu / modulu

struct ResourceBudget: Codable {
    var maxRAMBytes: Int?
    var maxCPUPercent: Double?
    var maxGPUPercent: Double?
    var allowML: Bool
    var suspendAfterIdleSeconds: Int?
    var killIfOverBudget: Bool
}

/// Identifikator konteksta (tab, plugin, modul).
struct ResourceContextId: Hashable {
    var tabId: String?
    var moduleId: String
}

// MARK: - Stub (ne poziva se)

enum ResourceBudgetPolicy {
    static func budget(for contextId: ResourceContextId) -> ResourceBudget {
        ResourceBudget(
            maxRAMBytes: nil,
            maxCPUPercent: nil,
            maxGPUPercent: nil,
            allowML: true,
            suspendAfterIdleSeconds: nil,
            killIfOverBudget: false
        )
    }

    static func reportUsage(contextId: ResourceContextId, ramBytes: Int, cpuPercent: Double) {}
    static func requestSuspend(contextId: ResourceContextId) {}
}
