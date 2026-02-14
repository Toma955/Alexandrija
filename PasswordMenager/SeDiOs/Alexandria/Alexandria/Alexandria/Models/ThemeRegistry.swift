//
//  ThemeRegistry.swift
//  Alexandria
//
//  Registar tema – odabir teme i mapiranje ikona za Island.
//  Teme se ne hardkodiraju: dostupne teme dolaze iz registra (kasnije i s marketa).
//

import SwiftUI

/// Jedna tema – id, prikazno ime, opcionalno mapiranje ikona (ključ → SF Symbol ili asset).
struct ThemeInfo: Identifiable, Equatable {
    let id: String
    let displayName: String
    /// Mapiranje ključeva ikona (npr. island.settings) na naziv ikone (SF Symbol ili asset).
    /// Ako ključ nije u mapi, koristi se zadani simbol.
    let iconOverrides: [String: String]
    
    init(id: String, displayName: String, iconOverrides: [String: String] = [:]) {
        self.id = id
        self.displayName = displayName
        self.iconOverrides = iconOverrides
    }
}

/// Ključevi ikona za Island – semantički nazivi (ne SF Symbol nazivi).
enum IslandIconKey: String, CaseIterable {
    case settings
    case appLibrary
    case newTab
    case favorites
    case search
    case back
    case forward
    case globe
    case magnifyingGlassMinus
    case grid
    case magnifyingGlassPlus
    case home
    case reload
    case devMode
    case person
    case printer
    case keyboard
    case bag
    case plus
    case mic
}

/// Zadani SF Symbol nazivi za svaki Island ključ (kad tema nema override).
private let defaultIslandSymbols: [String: String] = {
    let pairs: [(IslandIconKey, String)] = [
        (.settings, "gearshape.fill"),
        (.appLibrary, "square.grid.2x2"),
        (.newTab, "plus.circle.fill"),
        (.favorites, "star.fill"),
        (.search, "magnifyingglass"),
        (.back, "chevron.backward"),
        (.forward, "chevron.forward"),
        (.globe, "globe"),
        (.magnifyingGlassMinus, "minus.magnifyingglass"),
        (.grid, "rectangle.grid.2x2"),
        (.magnifyingGlassPlus, "plus.magnifyingglass"),
        (.home, "house.fill"),
        (.reload, "arrow.clockwise"),
        (.devMode, "hammer.fill"),
        (.person, "person.fill"),
        (.printer, "printer"),
        (.keyboard, "keyboard"),
        (.bag, "bag.fill"),
        (.plus, "plus"),
        (.mic, "mic.fill"),
    ]
    return Dictionary(uniqueKeysWithValues: pairs.map { ($0.0.rawValue, $0.1) })
}()

/// Vraća naziv ikone (SF Symbol ili asset) za dani Island ključ prema trenutno odabranoj temi.
enum IslandIcon {
    static func symbol(for key: IslandIconKey) -> String {
        let keyString = key.rawValue
        if let theme = ThemeRegistry.current,
           let overridden = theme.iconOverrides[keyString], !overridden.isEmpty {
            return overridden
        }
        return defaultIslandSymbols[keyString] ?? "circle"
    }
}

/// Registar tema – dostupne teme i odabrana tema. Proširivo (npr. teme s marketa).
enum ThemeRegistry {
    private static let selectedThemeIdKey = "themeRegistrySelectedThemeId"
    
    /// Odabrana tema (id). Sprema se u UserDefaults.
    static var selectedThemeId: String {
        get {
            let stored = UserDefaults.standard.string(forKey: selectedThemeIdKey)
            if all.contains(where: { $0.id == stored }) { return stored ?? "" }
            return all.first?.id ?? ""
        }
        set { UserDefaults.standard.set(newValue, forKey: selectedThemeIdKey) }
    }
    
    /// Trenutno odabrana tema (nil ako nema odgovarajuće).
    static var current: ThemeInfo? {
        all.first { $0.id == selectedThemeId }
    }
    
    /// Sve dostupne teme. Kasnije se može dopuniti s temama s marketa.
    static var all: [ThemeInfo] {
        [
            builtinDefaultTheme,
            builtinClassicTheme,
        ]
    }
    
    /// Ugrađena zadana tema (bez overrida ikona).
    private static var builtinDefaultTheme: ThemeInfo {
        ThemeInfo(id: "default", displayName: "Zadano", iconOverrides: [:])
    }
    
    /// Ugrađena klasična tema – druge ikone u Islandu.
    private static var builtinClassicTheme: ThemeInfo {
        ThemeInfo(
            id: "classic",
            displayName: "Classic",
            iconOverrides: [
                IslandIconKey.settings.rawValue: "gearshape",
                IslandIconKey.appLibrary.rawValue: "square.grid.2x2",
                IslandIconKey.newTab.rawValue: "plus.square",
                IslandIconKey.favorites.rawValue: "star",
                IslandIconKey.search.rawValue: "magnifyingglass",
                IslandIconKey.back.rawValue: "chevron.left",
                IslandIconKey.forward.rawValue: "chevron.right",
                IslandIconKey.globe.rawValue: "globe.americas",
                IslandIconKey.magnifyingGlassMinus.rawValue: "minus.magnifyingglass",
                IslandIconKey.grid.rawValue: "square.grid.2x2",
                IslandIconKey.magnifyingGlassPlus.rawValue: "plus.magnifyingglass",
                IslandIconKey.home.rawValue: "house",
                IslandIconKey.reload.rawValue: "arrow.clockwise",
                IslandIconKey.devMode.rawValue: "wrench",
                IslandIconKey.person.rawValue: "person",
                IslandIconKey.printer.rawValue: "printer",
                IslandIconKey.keyboard.rawValue: "keyboard",
                IslandIconKey.bag.rawValue: "bag",
                IslandIconKey.plus.rawValue: "plus",
                IslandIconKey.mic.rawValue: "mic",
            ]
        )
    }
}
