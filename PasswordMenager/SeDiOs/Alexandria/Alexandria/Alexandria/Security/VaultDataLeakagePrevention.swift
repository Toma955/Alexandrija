//
//  VaultDataLeakagePrevention.swift
//  Alexandria
//
//  Priprema: Onemogućavanje data leakage – Spotlight i Time Machine exclusion.
//  isExcludedFromBackup (com_apple_backup_excludeItem), .metadata_never_index.
//  NIGDJE SE NE UKLJUČUJE – samo priprema za buduću uporabu.
//

import Foundation

#if canImport(Darwin)
import Darwin
#endif

// MARK: - Data Leakage Prevention (priprema)

enum VaultDataLeakagePrevention {

    /// Označi putanju (datoteku ili mapu) da je isključena iz Time Machine backupa.
    /// Postavlja resource value isExcludedFromBackup (pod kapom: com.apple.metadata:com_apple_backup_excludeItem).
    static func excludeFromTimeMachine(url: URL) throws {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutable = url
        try mutable.setResourceValues(resourceValues)
    }

    /// Označi putanju da Spotlight ne indeksira sadržaj (extended attribute).
    /// Za potpunu nevidljivost u Spotlightu korisnik može dodati putanju u System Preferences → Spotlight → Privacy.
    static func excludeFromSpotlightIndexing(url: URL) throws {
        let path = url.path
        guard !path.isEmpty else { return }
        #if canImport(Darwin)
        let attrName = "com.apple.metadata:kMDItemUserTags"
        let tagData = "Vault\0NeverIndex".data(using: .utf8)!
        _ = tagData.withUnsafeBytes { buf in
            setxattr(path, attrName, buf.baseAddress, tagData.count, 0, 0)
        }
        #endif
    }

    /// Kombinirano: isključi iz Time Machine i označi za ne-indeksiranje (Spotlight).
    static func applySystemInvisibility(to url: URL) throws {
        try excludeFromTimeMachine(url: url)
        try excludeFromSpotlightIndexing(url: url)
    }
}
