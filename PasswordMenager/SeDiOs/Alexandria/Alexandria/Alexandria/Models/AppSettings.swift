//
//  AppSettings.swift
//  Alexandria
//
//  Korisnik prilagođava u postavkama.
//

import SwiftUI

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

// MARK: - App postavke
struct AppSettings {
    private static let searchPanelKey = "searchPanelPosition"
    private static let islandTitleKey = "islandTitle"
    
    static var islandTitle: String {
        get { UserDefaults.standard.string(forKey: islandTitleKey) ?? "Alexandria" }
        set { UserDefaults.standard.set(newValue, forKey: islandTitleKey) }
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
}
