//
//  NetworkTopology.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation
import SwiftUI

/// Model za cijelu mrežnu topologiju
class NetworkTopology: ObservableObject, Codable {
    @Published var components: [NetworkComponent] = []
    @Published var connections: [NetworkConnection] = []
    @Published var clientA: NetworkComponent?
    @Published var clientB: NetworkComponent?
    
    // Agent assignments
    @Published var agentAssignments: [UUID: AgentType] = [:]
    
    init() {}
    
    // MARK: - Component Management
    
    /// Dodaje komponentu na topologiju s validacijom
    /// - Parameters:
    ///   - component: Komponenta za dodavanje
    ///   - allowInClientZones: Ako je false, ne dozvoljava dodavanje u Client A/B zone (default: false)
    /// - Returns: true ako je komponenta uspješno dodana, false inače
    @discardableResult
    func addComponent(_ component: NetworkComponent, allowInClientZones: Bool = false) -> Bool {
        // Provjeri da li komponenta već postoji (po ID-u)
        guard !components.contains(where: { $0.id == component.id }) else {
            print("⚠️ Komponenta s ID-om \(component.id) već postoji na topologiji")
            return false
        }
        
        // Provjeri da li je komponenta Client A ili Client B
        if component.isClientA == true {
            // Ako već postoji Client A, zamijeni ga
            if let existingClientA = clientA {
                components.removeAll { $0.id == existingClientA.id }
            }
            clientA = component
        } else if component.isClientB == true {
            // Ako već postoji Client B, zamijeni ga
            if let existingClientB = clientB {
                components.removeAll { $0.id == existingClientB.id }
            }
            clientB = component
        } else {
            // Provjeri ograničenje: mogu biti samo 2 korisnika (user area i business area)
            if component.componentType == .userArea {
                let existingUserAreas = components.filter { $0.componentType == .userArea }
                if existingUserAreas.count >= 2 {
                    print("⚠️ Mogu postojati samo 2 User Area komponente")
                    return false
                }
            } else if component.componentType == .businessArea {
                let existingBusinessAreas = components.filter { $0.componentType == .businessArea }
                if existingBusinessAreas.count >= 2 {
                    print("⚠️ Mogu postojati samo 2 Business Area komponente")
                    return false
                }
            }
            
            // Za regularne komponente, provjeri constraints ako je potrebno
            if !allowInClientZones {
                // Ovdje možemo dodati provjere za Client zone ako je potrebno
                // Trenutno se to rješava u ComponentDropDelegate
            }
        }
        
        // Dodaj komponentu
        components.append(component)
        objectWillChange.send()
        
        return true
    }
    
    /// Uklanja komponentu s topologije
    /// - Parameter component: Komponenta za uklanjanje
    func removeComponent(_ component: NetworkComponent) {
        // Ukloni komponentu
        components.removeAll { $0.id == component.id }
        
        // Ako je Client A ili Client B, resetiraj reference
        if component.id == clientA?.id {
            clientA = nil
        }
        if component.id == clientB?.id {
            clientB = nil
        }
        
        // Ukloni sve konekcije koje koriste ovu komponentu
        connections.removeAll { connection in
            connection.fromComponentId == component.id || connection.toComponentId == component.id
        }
        
        // Ukloni agent assignment ako postoji
        agentAssignments.removeValue(forKey: component.id)
        
        objectWillChange.send()
    }
    
    /// Provjerava da li komponenta postoji na topologiji
    func hasComponent(_ componentId: UUID) -> Bool {
        return components.contains(where: { $0.id == componentId })
    }
    
    /// Provjerava da li komponenta postoji na topologiji (po objektu)
    func hasComponent(_ component: NetworkComponent) -> Bool {
        return hasComponent(component.id)
    }
    
    // MARK: - Connection Management
    
    /// Dodaje konekciju između dvije komponente s provjerom pravila
    /// - Parameters:
    ///   - from: ID komponente od koje se spaja
    ///   - to: ID komponente na koju se spaja
    ///   - type: Tip konekcije (wired, wireless, fiber, vpn)
    ///   - fromConnectionPoint: Točka konekcije na prvoj komponenti
    ///   - toConnectionPoint: Točka konekcije na drugoj komponenti
    /// - Returns: true ako je konekcija uspješno dodana, false inače
    @discardableResult
    func addConnection(from: UUID, to: UUID, type: NetworkConnection.ConnectionType = .wired, fromConnectionPoint: ConnectionPoint? = nil, toConnectionPoint: ConnectionPoint? = nil) -> Bool {
        // Provjeri da li konekcija već postoji
        guard !connections.contains(where: { 
            ($0.fromComponentId == from && $0.toComponentId == to) ||
            ($0.fromComponentId == to && $0.toComponentId == from)
        }) else {
            print("⚠️ Konekcija između komponenti \(from) i \(to) već postoji")
            return false
        }
        
        // Provjeri pravila konekcija
        let validationResult = ConnectionRuleValidator.validateConnection(in: self, from: from, to: to)
        
        switch validationResult {
        case .allowed:
            // Konekcija je dozvoljena, dodaj je
            let connection = NetworkConnection(
                fromComponentId: from,
                toComponentId: to,
                connectionType: type,
                fromConnectionPoint: fromConnectionPoint,
                toConnectionPoint: toConnectionPoint
            )
            connections.append(connection)
            objectWillChange.send()
            return true
            
        case .denied(let reason):
            // Konekcija nije dozvoljena
            print("⚠️ Konekcija nije dozvoljena: \(reason)")
            return false
        }
    }
    
    func removeConnection(_ connection: NetworkConnection) {
        connections.removeAll { $0.id == connection.id }
    }
    
    func getConnections(for componentId: UUID) -> [NetworkConnection] {
        return connections.filter { 
            $0.fromComponentId == componentId || $0.toComponentId == componentId 
        }
    }
    
    // MARK: - Agent Management
    
    func assignAgent(to componentId: UUID, agent: AgentType) {
        agentAssignments[componentId] = agent
    }
    
    func removeAgent(from componentId: UUID) {
        agentAssignments.removeValue(forKey: componentId)
    }
    
    func getAgent(for componentId: UUID) -> AgentType? {
        return agentAssignments[componentId]
    }
    
    // MARK: - Topology Tracking & Analysis
    
    /// Vraća sve komponente na topologiji (uključujući Client A i Client B)
    func getAllComponents() -> [NetworkComponent] {
        return components
    }
    
    /// Vraća sve komponente osim Client A i Client B
    func getRegularComponents() -> [NetworkComponent] {
        return components.filter { $0.isClientA != true && $0.isClientB != true }
    }
    
    /// Vraća komponente filtrirane po tipu
    func getComponentsByType(_ type: NetworkComponent.ComponentType) -> [NetworkComponent] {
        return components.filter { $0.componentType == type }
    }
    
    /// Vraća komponente filtrirane po kategoriji
    func getComponentsByCategory(_ category: NetworkComponent.ComponentCategory) -> [NetworkComponent] {
        return components.filter { $0.componentType.category == category }
    }
    
    /// Vraća ukupan broj komponenti
    func getComponentCount() -> Int {
        return components.count
    }
    
    /// Vraća broj komponenti po tipu
    func getComponentCountByType(_ type: NetworkComponent.ComponentType) -> Int {
        return getComponentsByType(type).count
    }
    
    /// Vraća ukupan broj konekcija
    func getConnectionCount() -> Int {
        return connections.count
    }
    
    /// Vraća broj konekcija po tipu
    func getConnectionCountByType(_ type: NetworkConnection.ConnectionType) -> Int {
        return connections.filter { $0.connectionType == type }.count
    }
    
    /// Vraća sve komponente koje su direktno spojene s određenom komponentom
    func getConnectedComponents(for componentId: UUID) -> [NetworkComponent] {
        let componentConnections = getConnections(for: componentId)
        var connectedIds: Set<UUID> = []
        
        for connection in componentConnections {
            if connection.fromComponentId == componentId {
                connectedIds.insert(connection.toComponentId)
            } else {
                connectedIds.insert(connection.fromComponentId)
            }
        }
        
        return components.filter { connectedIds.contains($0.id) }
    }
    
    /// Vraća detaljne informacije o konekcijama komponente
    func getComponentConnectionDetails(for componentId: UUID) -> [ComponentConnectionInfo] {
        let componentConnections = getConnections(for: componentId)
        var details: [ComponentConnectionInfo] = []
        
        for connection in componentConnections {
            let otherComponentId = connection.fromComponentId == componentId 
                ? connection.toComponentId 
                : connection.fromComponentId
            
            if let otherComponent = components.first(where: { $0.id == otherComponentId }) {
                let isFrom = connection.fromComponentId == componentId
                details.append(ComponentConnectionInfo(
                    connection: connection,
                    connectedComponent: otherComponent,
                    connectionPoint: isFrom ? connection.fromConnectionPoint : connection.toConnectionPoint,
                    otherConnectionPoint: isFrom ? connection.toConnectionPoint : connection.fromConnectionPoint
                ))
            }
        }
        
        return details
    }
    
    /// Vraća sve konekcije s detaljima (koja komponenta je s kojom spojena)
    func getAllConnectionDetails() -> [FullConnectionInfo] {
        var details: [FullConnectionInfo] = []
        
        for connection in connections {
            if let fromComponent = components.first(where: { $0.id == connection.fromComponentId }),
               let toComponent = components.first(where: { $0.id == connection.toComponentId }) {
                details.append(FullConnectionInfo(
                    connection: connection,
                    fromComponent: fromComponent,
                    toComponent: toComponent
                ))
            }
        }
        
        return details
    }
    
    /// Provjerava je li komponenta spojena s drugom komponentom
    func areComponentsConnected(_ componentId1: UUID, _ componentId2: UUID) -> Bool {
        return connections.contains { connection in
            (connection.fromComponentId == componentId1 && connection.toComponentId == componentId2) ||
            (connection.fromComponentId == componentId2 && connection.toComponentId == componentId1)
        }
    }
    
    /// Vraća komponente koje nemaju nijednu konekciju (izolirane)
    func getIsolatedComponents() -> [NetworkComponent] {
        return components.filter { component in
            getConnections(for: component.id).isEmpty
        }
    }
    
    /// Vraća komponente koje imaju najviše konekcija
    func getMostConnectedComponents(limit: Int = 5) -> [(component: NetworkComponent, connectionCount: Int)] {
        let componentConnections = components.map { component in
            (component: component, connectionCount: getConnections(for: component.id).count)
        }
        
        return Array(componentConnections
            .sorted { $0.connectionCount > $1.connectionCount }
            .prefix(limit))
    }
    
    /// Vraća statistiku topologije
    func getTopologyStatistics() -> TopologyStatistics {
        return TopologyStatistics(
            totalComponents: components.count,
            regularComponents: getRegularComponents().count,
            totalConnections: connections.count,
            isolatedComponents: getIsolatedComponents().count,
            componentsByType: Dictionary(grouping: components, by: { $0.componentType })
                .mapValues { $0.count },
            connectionsByType: Dictionary(grouping: connections, by: { $0.connectionType })
                .mapValues { $0.count }
        )
    }
    
    // MARK: - Export/Import
    
    func exportToJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
    
    static func importFromJSON(_ data: Data) throws -> NetworkTopology {
        let decoder = JSONDecoder()
        return try decoder.decode(NetworkTopology.self, from: data)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case components, connections, clientAId, clientBId, agentAssignments
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        components = try container.decode([NetworkComponent].self, forKey: .components)
        connections = try container.decode([NetworkConnection].self, forKey: .connections)
        
        if let clientAId = try? container.decode(UUID.self, forKey: .clientAId) {
            clientA = components.first { $0.id == clientAId }
        }
        
        if let clientBId = try? container.decode(UUID.self, forKey: .clientBId) {
            clientB = components.first { $0.id == clientBId }
        }
        
        // Decode agent assignments
        let assignmentsDict = try container.decode([String: String].self, forKey: .agentAssignments)
        agentAssignments = Dictionary(uniqueKeysWithValues: 
            assignmentsDict.compactMap { (key: String, value: String) -> (UUID, AgentType)? in
                guard let uuid = UUID(uuidString: key),
                      let agent = AgentType(rawValue: value) else { return nil }
                return (uuid, agent)
            }
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(components, forKey: .components)
        try container.encode(connections, forKey: .connections)
        try container.encodeIfPresent(clientA?.id, forKey: .clientAId)
        try container.encodeIfPresent(clientB?.id, forKey: .clientBId)
        
        // Encode agent assignments
        let assignmentsDict: [String: String] = Dictionary(uniqueKeysWithValues:
            agentAssignments.map { (key: UUID, value: AgentType) -> (String, String) in
                (key.uuidString, value.rawValue)
            }
        )
        try container.encode(assignmentsDict, forKey: .agentAssignments)
    }
}

// MARK: - Topology Analysis Structures

/// Informacije o konekciji komponente s drugom komponentom
struct ComponentConnectionInfo {
    let connection: NetworkConnection
    let connectedComponent: NetworkComponent
    let connectionPoint: ConnectionPoint?
    let otherConnectionPoint: ConnectionPoint?
}

/// Potpune informacije o konekciji između dvije komponente
struct FullConnectionInfo {
    let connection: NetworkConnection
    let fromComponent: NetworkComponent
    let toComponent: NetworkComponent
}

/// Statistika topologije
struct TopologyStatistics {
    let totalComponents: Int
    let regularComponents: Int
    let totalConnections: Int
    let isolatedComponents: Int
    let componentsByType: [NetworkComponent.ComponentType: Int]
    let connectionsByType: [NetworkConnection.ConnectionType: Int]
}


