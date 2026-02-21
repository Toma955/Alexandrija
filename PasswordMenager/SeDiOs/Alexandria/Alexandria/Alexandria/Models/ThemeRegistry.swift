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

// MARK: - Objekt teme za izbor (parent = lista tema, child = ovaj objekt u svakom redu)

/// Jedna tema kao objekt za prikaz u izboru: nosi identitet, boje za mini pregled i opis.
/// Lista takvih objekata je parent; svaki Theme je child koji se prikazuje kroz ThemeSelectionRow.
struct Theme: Identifiable, Equatable {
    let id: String
    let displayName: String
    let iconOverrides: [String: String]
    /// Boje za mini pregled (pozadina, bar, naglasak) – hex stringovi.
    let previewBackgroundHex: String
    let previewBarFillHex: String
    let previewAccentHex: String
    /// Kratki opis za red (npr. "Pozadina: jednobojna #111").
    let summary: String

    init(
        id: String,
        displayName: String,
        iconOverrides: [String: String] = [:],
        previewBackgroundHex: String,
        previewBarFillHex: String,
        previewAccentHex: String,
        summary: String
    ) {
        self.id = id
        self.displayName = displayName
        self.iconOverrides = iconOverrides
        self.previewBackgroundHex = previewBackgroundHex
        self.previewBarFillHex = previewBarFillHex
        self.previewAccentHex = previewAccentHex
        self.summary = summary
    }

    /// Boje za mini pregled (Color).
    var previewBackgroundColor: Color { Color(hex: previewBackgroundHex) }
    var previewBarFillColor: Color { Color(hex: previewBarFillHex) }
    var previewAccentColor: Color { Color(hex: previewAccentHex) }
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

    /// Prikazni natpis za postavke i Phase 1 gumbe.
    var displayLabel: String {
        switch self {
        case .settings: return "Postavke"
        case .appLibrary: return "Aplikacije"
        case .newTab: return "Novi tab"
        case .favorites: return "Omiljeno"
        case .search: return "Pretraživanje"
        case .back: return "Nazad"
        case .forward: return "Naprijed"
        case .globe: return "Globus"
        case .magnifyingGlassMinus: return "Udalji"
        case .grid: return "Mreža"
        case .magnifyingGlassPlus: return "Povećaj"
        case .home: return "Početna"
        case .reload: return "Osvježi"
        case .devMode: return "Dev mod"
        case .person: return "Korisnik"
        case .printer: return "Ispis"
        case .keyboard: return "Tipkovnica"
        case .bag: return "Torba"
        case .plus: return "Dodaj"
        case .mic: return "Mikrofon"
        }
    }
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

/// Registar tema: samo jedna ugrađena (Default). Sve ostale teme moraju se skinuti (Market → Teme).
enum ThemeRegistry {
    private static let selectedThemeIdKey = "themeRegistrySelectedThemeId"

    /// Odabrana tema (id). Sprema se u UserDefaults. Kad se postavi, primjenjuju se boje iz theme.json ako tema ima paket.
    static var selectedThemeId: String {
        get {
            let stored = UserDefaults.standard.string(forKey: selectedThemeIdKey)
            if all.contains(where: { $0.id == stored }) { return stored ?? "" }
            return all.first?.id ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: selectedThemeIdKey)
            applyCurrentThemeColors()
        }
    }

    /// Učita theme.json odabrane teme i primijeni boje; za "default" koristi zadanu crno-bijelu (#111, #F9F6EE).
    static func applyCurrentThemeColors() {
        let id = selectedThemeId
        if id == "default" {
            AlexandriaTheme.resetToDefaults()
            return
        }
        guard let package = BackendCatalogService.shared.loadThemePackage(themeId: id) else { return }
        if let colors = package.colors {
            if let hex = colors.accentHex, !hex.isEmpty { AlexandriaTheme.accentColorHex = hex }
            if let hex = colors.barFillHex, !hex.isEmpty { AlexandriaTheme.barFillColorHex = hex }
            if let hex = colors.primaryTextHex { AlexandriaTheme.primaryTextColorHex = hex.isEmpty ? nil : hex }
            if let hex = colors.secondaryTextHex { AlexandriaTheme.secondaryTextColorHex = hex.isEmpty ? nil : hex }
        }
        if let hex = package.background?.colorHex, !hex.isEmpty { AlexandriaTheme.backgroundColorHex = hex }
    }

    /// Trenutno odabrana tema (nil ako nema odgovarajuće).
    static var current: ThemeInfo? {
        all.first { $0.id == selectedThemeId }
    }

    /// Sve teme (za Picker i current). Jedna default + skinute.
    static var all: [ThemeInfo] {
        [builtinDefaultTheme] + BackendCatalogService.shared.installedThemeInfos()
    }

    /// Lista objekata tema za izbor (parent). Svaki Theme se prikazuje kao child u ThemeSelectionRow.
    static var themesForSelection: [Theme] {
        [builtinDefaultThemeObject] + installedThemeObjects
    }

    /// Jedina ugrađena tema. Ostale se moraju skinuti.
    private static var builtinDefaultTheme: ThemeInfo {
        ThemeInfo(id: "default", displayName: "Zadano", iconOverrides: [:])
    }

    private static var builtinDefaultThemeObject: Theme {
        Theme(
            id: "default",
            displayName: "Zadano",
            iconOverrides: [:],
            previewBackgroundHex: "111111",
            previewBarFillHex: "F9F6EE",
            previewAccentHex: "F9F6EE",
            summary: "Pozadina: jednobojna #111. Boje: krem #F9F6EE."
        )
    }

    private static var installedThemeObjects: [Theme] {
        BackendCatalogService.shared.installedThemeInfos().compactMap { info -> Theme? in
            guard let package = BackendCatalogService.shared.loadThemePackage(themeId: info.id) else { return nil }
            let bgHex = package.background?.colorHex ?? "111111"
            let barHex = package.colors?.barFillHex ?? "F9F6EE"
            let accentHex = package.colors?.accentHex ?? "F9F6EE"
            var summaryParts: [String] = []
            if let bgType = package.background?.type, !bgType.isEmpty { summaryParts.append("Pozadina: \(bgType)") }
            if package.colors != nil { summaryParts.append("Boje: iz paketa") }
            if let ov = package.iconOverrides, !ov.isEmpty { summaryParts.append("Ikone: prilagođene") }
            let summary = summaryParts.isEmpty ? "Instalirana tema" : summaryParts.joined(separator: ". ")
            return Theme(
                id: info.id,
                displayName: info.displayName,
                iconOverrides: info.iconOverrides,
                previewBackgroundHex: bgHex,
                previewBarFillHex: barHex,
                previewAccentHex: accentHex,
                summary: summary
            )
        }
    }
}
