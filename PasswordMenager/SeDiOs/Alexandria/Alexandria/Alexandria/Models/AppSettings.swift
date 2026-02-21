//
//  AppSettings.swift
//  Alexandria
//
//  Korisnik prilagođava u postavkama.
//

import SwiftUI

// MARK: - Što se otvori kad app starta
enum OnOpenAction: String, CaseIterable, Codable {
    case search = "search"
    case webBrowser = "webBrowser"
    case empty = "empty"
    case devMode = "devMode"
    
    var label: String {
        switch self {
        case .search: return "Pretraživanje"
        case .webBrowser: return "Pretraga aplikacija"
        case .empty: return "Prazno"
        case .devMode: return "Dev Mode"
        }
    }
}

// MARK: - Search panel pozicija
enum SearchPanelPosition: String, CaseIterable, Codable {
    case none = "none"
    case left = "left"
    case right = "right"
    case both = "both"
    
    var label: String {
        switch self {
        case .none: return "Skriven"
        case .left: return "Lijevo"
        case .right: return "Desno"
        case .both: return "Lijevo i desno"
        }
    }
}

// MARK: - Tema / Izgled
enum AppTheme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var label: String {
        switch self {
        case .system: return "Sustav"
        case .light: return "Svijetla"
        case .dark: return "Tamna"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - App postavke
struct AppSettings {
    private static let searchPanelKey = "searchPanelPosition"
    private static let islandTitleKey = "islandTitle"
    private static let incognitoKey = "isIncognito"
    private static let internetEnabledKey = "isInternetEnabled"
    private static let themeKey = "appTheme"
    private static let onOpenKey = "onOpenAction"
    private static let interfaceLocaleKey = "interfaceLocaleCode"

    /// Jezik sučelja (hr, en, de, …). Uvijek jedan označen – zadano Hrvatski.
    static var interfaceLocaleCode: String {
        get {
            let stored = UserDefaults.standard.string(forKey: interfaceLocaleKey)
            return InterfaceLanguage.validLocaleCode(stored: stored)
        }
        set {
            let valid = InterfaceLanguage.validLocaleCode(stored: newValue)
            UserDefaults.standard.set(valid, forKey: interfaceLocaleKey)
        }
    }

    /// Što se otvori kad app starta
    static var onOpenAction: OnOpenAction {
        get {
            guard let raw = UserDefaults.standard.string(forKey: onOpenKey),
                  let action = OnOpenAction(rawValue: raw) else { return .search }
            return action
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: onOpenKey) }
    }
    
    /// Dozvoli spajanje na internet (postavke)
    static var isInternetEnabled: Bool {
        get { UserDefaults.standard.object(forKey: internetEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: internetEnabledKey) }
    }
    
    static var isIncognito: Bool {
        get { UserDefaults.standard.bool(forKey: incognitoKey) }
        set { UserDefaults.standard.set(newValue, forKey: incognitoKey) }
    }
    
    static var islandTitle: String {
        get { UserDefaults.standard.string(forKey: islandTitleKey) ?? "Alexandria" }
        set { UserDefaults.standard.set(newValue, forKey: islandTitleKey) }
    }
    
    static var appTheme: AppTheme {
        get {
            guard let raw = UserDefaults.standard.string(forKey: themeKey),
                  let theme = AppTheme(rawValue: raw) else { return .system }
            return theme
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: themeKey) }
    }
    
    @AppStorage(searchPanelKey)
    private static var searchPanelPositionRaw: String = SearchPanelPosition.both.rawValue
    
    static var searchPanelPosition: SearchPanelPosition {
        get {
            SearchPanelPosition(rawValue: searchPanelPositionRaw) ?? .both
        }
        set {
            searchPanelPositionRaw = newValue.rawValue
        }
    }
    
    /// Prikaži panel na lijevoj strani
    static var showSearchPanelLeft: Bool {
        searchPanelPosition == .left || searchPanelPosition == .both
    }
    
    /// Prikaži panel na desnoj strani
    static var showSearchPanelRight: Bool {
        searchPanelPosition == .right || searchPanelPosition == .both
    }

    // MARK: - Backend katalog (teme, jezici, plug-ini)
    private static let alexandriaBackendURLKey = "alexandriaBackendBaseURL"
    private static let syncCatalogOnLaunchKey = "syncCatalogOnLaunch"

    /// Zadani backend (Render free tier – cold start do ~15 s).
    private static let defaultAlexandriaBackendURL = "https://alexandria-backend-u76b.onrender.com"

    /// Base URL Alexandria backenda za katalog. Ako korisnik nije ništa upisao, koristi se zadani Render URL.
    static var alexandriaBackendBaseURL: String {
        get {
            let stored = UserDefaults.standard.string(forKey: alexandriaBackendURLKey)?.trimmingCharacters(in: .whitespaces)
            return (stored?.isEmpty == false) ? stored! : defaultAlexandriaBackendURL
        }
        set { UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespaces), forKey: alexandriaBackendURLKey) }
    }

    /// Pri pokretanju aplikacije osvježi katalog s backenda (ako je backend postavljen).
    static var syncCatalogOnLaunch: Bool {
        get { UserDefaults.standard.object(forKey: syncCatalogOnLaunchKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: syncCatalogOnLaunchKey) }
    }
}
