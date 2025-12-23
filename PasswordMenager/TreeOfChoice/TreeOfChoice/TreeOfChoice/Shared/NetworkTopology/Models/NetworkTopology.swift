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
    
    // MARK: - Connection Management
    
    func addConnection(from: UUID, to: UUID, type: NetworkConnection.ConnectionType = .wired, fromConnectionPoint: ConnectionPoint? = nil, toConnectionPoint: ConnectionPoint? = nil) {
        // Check if connection already exists
        guard !connections.contains(where: { 
            ($0.fromComponentId == from && $0.toComponentId == to) ||
            ($0.fromComponentId == to && $0.toComponentId == from)
        }) else { return }
        
        let connection = NetworkConnection(
            fromComponentId: from,
            toComponentId: to,
            connectionType: type,
            fromConnectionPoint: fromConnectionPoint,
            toConnectionPoint: toConnectionPoint
        )
        connections.append(connection)
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


