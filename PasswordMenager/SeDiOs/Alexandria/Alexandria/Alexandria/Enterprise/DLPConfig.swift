//
//  DLPConfig.swift
//  Alexandria
//
//  Priprema: DLP kontrole – copy/paste, drag&drop, print, screenshot, export, clipboard timeout.
//  NIGDJE SE NE UKLJUČUJE – samo konfiguracija i stubovi za buduću implementaciju.
//

import Foundation

// MARK: - DLP pravila

struct DLPConfig: Codable {
    var allowCopyPaste: Bool
    var allowDragDrop: Bool
    var allowPrint: Bool
    var allowScreenshot: Bool
    var allowExport: Bool
    var clipboardClearTimeoutSeconds: Int?  // nil = ne briši automatski
}

// MARK: - Stub provjere (ne poziva se)

enum DLPPolicy {
    static func currentConfig() -> DLPConfig {
        DLPConfig(
            allowCopyPaste: true,
            allowDragDrop: true,
            allowPrint: true,
            allowScreenshot: true,
            allowExport: true,
            clipboardClearTimeoutSeconds: nil
        )
    }

    static func canCopy() -> Bool { currentConfig().allowCopyPaste }
    static func canPaste() -> Bool { currentConfig().allowCopyPaste }
    static func canDragDrop() -> Bool { currentConfig().allowDragDrop }
    static func canPrint() -> Bool { currentConfig().allowPrint }
    static func canExport() -> Bool { currentConfig().allowExport }
    static func clipboardTimeoutSeconds() -> Int? { currentConfig().clipboardClearTimeoutSeconds }
}
