//
//  IslandLayoutStorage.swift
//  Alexandria
//
//  Mod rada Islanda i redoslijed ikona po fazama (Phase 1 = blizu, Phase 2 = otvoreno).
//  Sprema se po modu (default, home, work, trip, …) za buduće različite setove ikona.
//

import Foundation
import SwiftUI

/// Zadani redoslijed ikona za Phase 1 (kad dođeš blizu / hover).
private let defaultPhase1Keys: [IslandIconKey] = [
    .settings, .appLibrary, .newTab, .favorites, .search
]

/// Zadani redoslijed ikona za Phase 2 – donji red (okrugli gumbi; gornji red je fiksan).
private let defaultPhase2Keys: [IslandIconKey] = [
    .magnifyingGlassMinus, .grid, .magnifyingGlassPlus, .home, .reload,
    .devMode, .person, .printer, .keyboard, .bag, .plus, .settings
]

/// Pohrana redoslijeda Island ikona po modu rada (modeId = WorkMode.id).
enum IslandLayoutStorage {
    private static let phase1Prefix = "island.phase1.order."
    private static let phase2Prefix = "island.phase2.order."

    /// Redoslijed ključeva za Phase 1 za dani mod (id iz WorkMode).
    static func phase1Order(modeId: String) -> [IslandIconKey] {
        let key = phase1Prefix + modeId
        guard let rawList = UserDefaults.standard.array(forKey: key) as? [String] else {
            return defaultPhase1Keys
        }
        return rawList.compactMap { IslandIconKey(rawValue: $0) }
    }

    static func setPhase1Order(modeId: String, keys: [IslandIconKey]) {
        UserDefaults.standard.set(keys.map(\.rawValue), forKey: phase1Prefix + modeId)
    }

    /// Redoslijed ključeva za Phase 2 (donji red) za dani mod.
    static func phase2Order(modeId: String) -> [IslandIconKey] {
        let key = phase2Prefix + modeId
        guard let rawList = UserDefaults.standard.array(forKey: key) as? [String] else {
            return defaultPhase2Keys
        }
        return rawList.compactMap { IslandIconKey(rawValue: $0) }
    }

    static func setPhase2Order(modeId: String, keys: [IslandIconKey]) {
        UserDefaults.standard.set(keys.map(\.rawValue), forKey: phase2Prefix + modeId)
    }

    /// Vraća zadani redoslijed za Phase 1 (za „Vrati na zadano”).
    static var defaultPhase1Order: [IslandIconKey] { defaultPhase1Keys }

    /// Vraća zadani redoslijed za Phase 2.
    static var defaultPhase2Order: [IslandIconKey] { defaultPhase2Keys }
}
