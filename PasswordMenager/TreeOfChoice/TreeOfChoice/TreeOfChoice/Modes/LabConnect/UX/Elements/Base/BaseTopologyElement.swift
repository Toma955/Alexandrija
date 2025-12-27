//
//  BaseTopologyElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Bazna klasa za sve elemente u topologiji
/// Svi elementi nasljeđuju ovu klasu i automatski dobivaju:
/// - Pinove (ConnectableElement)
/// - Edit/Settings mode
/// - Display info
/// - Visibility management
/// - Settings menu (ElementSettingsMenu)
class BaseTopologyElement: ObservableObject, ConnectableElement, ElementSettingsMenuProtocol {
    // MARK: - Core Properties
    
    @Published var component: NetworkComponent
    @Published var visibility: ElementVisibility
    
    // Optional reference to topology for checking connections
    weak var topology: NetworkTopology?
    
    // MARK: - Mode Properties
    
    @Published var editMode: Bool = true
    @Published var settingsMode: Bool = false
    
    // MARK: - Settings Menu
    
    /// Settings menu instance - svi elementi imaju menu za postavke
    /// Kreira se na zahtjev (lazy) da se osigura da ima najnovije podatke
    var settingsMenu: ElementSettingsMenu {
        ElementSettingsMenu(component: component, topology: topology)
    }
    
    // MARK: - Initialization
    
    init(component: NetworkComponent, visibility: ElementVisibility = .public, topology: NetworkTopology? = nil) {
        self.component = component
        self.visibility = visibility
        self.topology = topology
    }
    
    // MARK: - Display Info
    
    /// Zajednički prikaz informacija za palette i topologiju
    var displayInfo: ElementDisplayInfo {
        ElementDisplayInfo(
            icon: ComponentIconHelper.icon(for: component.componentType),
            name: component.name,
            category: component.componentType.category,
            status: getStatus(),
            metadata: getMetadata(),
            hasArea: hasAreaProperty,
            connectionCount: getConnectionCount()
        )
    }
    
    /// Provjerava da li element ima area (provjerava naziv komponente)
    /// Override u AreaTopologyElement da vraća true
    var hasAreaProperty: Bool {
        component.componentType.rawValue.lowercased().contains("area")
    }
    
    // MARK: - Abstract Methods (Override u subklasama)
    
    /// Vraća status elementa (override u subklasama)
    func getStatus() -> String {
        "Ready"
    }
    
    /// Vraća metadata elementa (override u subklasama)
    func getMetadata() -> [String: Any] {
        [
            "type": component.componentType.rawValue,
            "category": component.componentType.category.rawValue
        ]
    }
    
    /// Vraća broj konekcija (override u subklasama)
    func getConnectionCount() -> Int {
        guard let topology = topology else { return 0 }
        return topology.getConnections(for: component.id).count
    }
    
    // MARK: - Interaction Methods
    
    /// Trenutni mode interakcije
    var currentMode: ElementInteractionMode {
        if editMode {
            return .edit
        } else if settingsMode {
            return .settings
        }
        return .edit // default
    }
    
    /// Enum za mode interakcije
    enum ElementInteractionMode {
        case edit      // Drag & drop
        case settings  // Otvori postavke
    }
    
    /// Handler za klik na ikonu
    /// U edit mode-u: započinje drag (delegira se view-u)
    /// U settings mode-u: otvara postavke
    func handleIconClick() {
        switch currentMode {
        case .edit:
            // U edit mode-u, klik na ikonu započinje drag
            // Ovo se delegira view-u koji poziva handleIconDrag()
            handleIconDrag()
        case .settings:
            openSettings()
        }
    }
    
    /// Handler za drag ikone (poziva se iz view-a)
    /// Override u subklasama ako je potrebno
    func handleIconDrag() {
        // Default: samo postavi flag da je drag aktivan
        // View će započeti drag gesture
    }
    
    /// Otvara settings dialog
    /// Override u subklasama za specifične settings
    func openSettings() {
        // Default: postavi flag da se otvori settings dialog
        // View će otvoriti settings sheet
        settingsMode = true
    }
    
    // MARK: - ElementSettingsMenuProtocol Implementation
    
    /// Prikazuje menu/postavke za element
    /// Override u subklasama za specifične postavke
    func showSettingsMenu() -> AnyView {
        // Kreiraj novi settings menu s najnovijim podacima
        // settingsMenu je computed property koji kreira novi menu svaki put
        return settingsMenu.showSettingsMenu()
    }
    
    // MARK: - ConnectableElement Implementation
    
    /// Svi elementi imaju pinove (default implementacija)
    var connectionPoints: [ConnectionPoint] {
        [.top, .bottom, .left, .right]
    }
    
    func getPinPosition(_ point: ConnectionPoint, componentCenter: CGPoint) -> CGPoint {
        ConnectionPointDetector.position(for: point, componentCenter: componentCenter)
    }
    
    func canConnect(to other: ConnectableElement) -> Bool {
        true
    }
    
    // MARK: - Icon Color Logic
    
    /// Vraća boju ikone na temelju stanja elementa
    /// - Default: siva boja (uvijek)
    /// - Narančasta: samo ako je Config mode (settings mode) upaljen
    /// - U Edit mode-u su UVIJEK sive, čak i ako su spojene
    func getIconColor() -> Color {
        // Default: siva boja (uvijek)
        let defaultColor = Color.gray
        
        // Narančasta boja samo ako je Config mode (settings mode) upaljen
        // U Edit mode-u su UVIJEK sive, bez obzira na konekcije
        if settingsMode {
            return Color(red: 1.0, green: 0.36, blue: 0.0) // Narančasta u Config mode-u
        }
        
        // U Edit mode-u su uvijek sive
        return defaultColor
    }
}

