//
//  TopologyStorageService.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Servis za spremanje i učitavanje mrežnih topologija
class TopologyStorageService {
    static let shared = TopologyStorageService()
    
    private init() {}
    
    // MARK: - JSON Import/Export
    
    /// Učitava topologiju iz JSON datoteke
    func loadTopologyFromJSON(from url: URL) throws -> NetworkTopology {
        let data = try Data(contentsOf: url)
        return try NetworkTopology.importFromJSON(data)
    }
    
    /// Sprema topologiju u JSON datoteku
    func saveTopologyToJSON(_ topology: NetworkTopology, to url: URL) throws {
        let data = try topology.exportToJSON()
        try data.write(to: url)
    }
    
    // MARK: - Swift Code Generation
    
    /// Generira Swift kod za dokument iz topologije
    func generateSwiftCodeForDocument(from topology: NetworkTopology) -> String {
        var swiftCode = """
        // Auto-generated Swift code from NetworkTopology
        // Generated on \(Date())
        
        import Foundation
        import SwiftUI
        
        // MARK: - Topology Data
        
        """
        
        // Generiraj kod za komponente
        swiftCode += "// Components\n"
        swiftCode += "let topologyComponents: [NetworkComponent] = [\n"
        
        for component in topology.components {
            swiftCode += generateComponentCode(component)
            swiftCode += ",\n"
        }
        
        if !topology.components.isEmpty {
            swiftCode.removeLast(2) // Remove last comma and newline
            swiftCode += "\n"
        }
        
        swiftCode += "]\n\n"
        
        // Generiraj kod za konekcije
        swiftCode += "// Connections\n"
        swiftCode += "let topologyConnections: [NetworkConnection] = [\n"
        
        for connection in topology.connections {
            swiftCode += generateConnectionCode(connection)
            swiftCode += ",\n"
        }
        
        if !topology.connections.isEmpty {
            swiftCode.removeLast(2) // Remove last comma and newline
            swiftCode += "\n"
        }
        
        swiftCode += "]\n\n"
        
        // Generiraj kod za Client A i B
        if let clientA = topology.clientA {
            swiftCode += "// Client A\n"
            swiftCode += "let clientA = \(generateComponentCode(clientA))\n\n"
        }
        
        if let clientB = topology.clientB {
            swiftCode += "// Client B\n"
            swiftCode += "let clientB = \(generateComponentCode(clientB))\n\n"
        }
        
        // Generiraj kod za agent assignments
        if !topology.agentAssignments.isEmpty {
            swiftCode += "// Agent Assignments\n"
            swiftCode += "let agentAssignments: [UUID: AgentType] = [\n"
            
            for (componentId, agentType) in topology.agentAssignments {
                swiftCode += "    UUID(uuidString: \"\(componentId.uuidString)\")!: AgentType(rawValue: \"\(agentType.rawValue)\")!,\n"
            }
            
            swiftCode.removeLast(2) // Remove last comma and newline
            swiftCode += "\n]\n\n"
        }
        
        // Generiraj kod za kreiranje topologije
        swiftCode += """
        // MARK: - Topology Creation
        
        func createTopology() -> NetworkTopology {
            let topology = NetworkTopology()
            topology.components = topologyComponents
            topology.connections = topologyConnections
        """
        
        if topology.clientA != nil {
            swiftCode += "\n    topology.clientA = clientA\n"
        }
        
        if topology.clientB != nil {
            swiftCode += "    topology.clientB = clientB\n"
        }
        
        if !topology.agentAssignments.isEmpty {
            swiftCode += "    topology.agentAssignments = agentAssignments\n"
        }
        
        swiftCode += "    return topology\n}\n"
        
        return swiftCode
    }
    
    // MARK: - Helper Methods
    
    private func generateComponentCode(_ component: NetworkComponent) -> String {
        var code = "    NetworkComponent(\n"
        code += "        id: UUID(uuidString: \"\(component.id.uuidString)\")!,\n"
        code += "        componentType: .\(component.componentType.rawValue),\n"
        code += "        position: CGPoint(x: \(component.position.x), y: \(component.position.y)),\n"
        code += "        name: \"\(component.name)\""
        
        if let isClientA = component.isClientA {
            code += ",\n        isClientA: \(isClientA)"
        }
        
        if let isClientB = component.isClientB {
            code += ",\n        isClientB: \(isClientB)"
        }
        
        code += "\n    )"
        return code
    }
    
    private func generateConnectionCode(_ connection: NetworkConnection) -> String {
        var code = "    NetworkConnection(\n"
        code += "        id: UUID(uuidString: \"\(connection.id.uuidString)\")!,\n"
        code += "        fromComponentId: UUID(uuidString: \"\(connection.fromComponentId.uuidString)\")!,\n"
        code += "        toComponentId: UUID(uuidString: \"\(connection.toComponentId.uuidString)\")!,\n"
        code += "        connectionType: .\(connection.connectionType.rawValue)"
        
        if let fromPoint = connection.fromConnectionPoint {
            code += ",\n        fromConnectionPoint: .\(fromPoint.rawValue)"
        }
        
        if let toPoint = connection.toConnectionPoint {
            code += ",\n        toConnectionPoint: .\(toPoint.rawValue)"
        }
        
        if let controlPoint = connection.controlPoint {
            code += ",\n        controlPoint: CGPoint(x: \(controlPoint.x), y: \(controlPoint.y))"
        }
        
        if let curveType = connection.curveType {
            code += ",\n        curveType: .\(curveType.rawValue)"
        }
        
        code += "\n    )"
        return code
    }
}

