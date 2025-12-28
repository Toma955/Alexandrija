//
//  TopologyStorageService.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation
import SwiftUI

/// Service za spremanje i učitavanje topologije u Swift datoteku
class TopologyStorageService {
    
    static let shared = TopologyStorageService()
    
    private init() {}
    
    // MARK: - Save to Swift File
    
    /// Sprema topologiju u Swift datoteku s elementima i konekcijama
    func saveTopologyToSwiftFile(_ topology: NetworkTopology, to url: URL) throws {
        let swiftCode = generateSwiftCode(from: topology)
        try swiftCode.write(to: url, atomically: true, encoding: .utf8)
    }
    
    /// Public metoda za generiranje Swift koda (za dokument)
    func generateSwiftCodeForDocument(from topology: NetworkTopology) -> String {
        return generateSwiftCode(from: topology)
    }
    
    /// Generira Swift kod s elementima i konekcijama
    private func generateSwiftCode(from topology: NetworkTopology) -> String {
        var code = """
//
//  TopologyData.swift
//  TreeOfChoice
//
//  Auto-generated topology data
//  Generated on: \(Date())
//

import Foundation
import SwiftUI

/// Statički podaci topologije - elementi i konekcije
/// 
/// PRIMJERI KORIŠTENJA:
/// 
/// Pristup listi svih elemenata:
///   let allElements = TopologyData.elements
///   for element in TopologyData.elements { print(element.name) }
/// 
/// Pristup listi svih konekcija:
///   let allConnections = TopologyData.connections
///   for conn in TopologyData.connections { ... }
/// 
/// Pronađi element po imenu:
///   if let element = TopologyData.getElement(by: "Router 1") { ... }
/// 
/// Pronađi sve elemente određenog tipa:
///   let allRouters = TopologyData.getElements(ofType: "router")
/// 
struct TopologyData {
    
    // MARK: - Elements List (Lista svih elemenata na topologiji)
    /// Lista svih elemenata - direktan pristup: TopologyData.elements
    static let elements: [TopologyElement] = [
"""
        
        // Dodaj sve elemente (bez Client A i B jer su posebni)
        let regularComponents = topology.components.filter { 
            $0.isClientA != true && $0.isClientB != true 
        }
        
        for (index, component) in regularComponents.enumerated() {
            code += generateElementCode(component, isLast: index == regularComponents.count - 1)
        }
        
        code += """
    ]
    
    // MARK: - Connections List (Lista svih konekcija između elemenata)
    /// Lista svih konekcija - direktan pristup: TopologyData.connections
    static let connections: [TopologyConnection] = [
"""
        
        // Dodaj sve konekcije
        for (index, connection) in topology.connections.enumerated() {
            code += generateConnectionCode(connection, isLast: index == topology.connections.count - 1)
        }
        
        code += """
    ]
    
    // MARK: - Helper Methods - Pristup listama
    
    /// Vraća listu svih elemenata na topologiji
    /// Koristi: let allElements = TopologyData.getAllElements()
    static func getAllElements() -> [TopologyElement] {
        return elements
    }
    
    /// Vraća listu svih konekcija između elemenata
    /// Koristi: let allConnections = TopologyData.getAllConnections()
    static func getAllConnections() -> [TopologyConnection] {
        return connections
    }
    
    /// Vraća element po ID-u iz liste
    static func getElement(by id: UUID) -> TopologyElement? {
        return elements.first { $0.id == id }
    }
    
    /// Vraća element po imenu iz liste
    static func getElement(by name: String) -> TopologyElement? {
        return elements.first { $0.name == name }
    }
    
    /// Vraća sve elemente određenog tipa iz liste
    static func getElements(ofType type: String) -> [TopologyElement] {
        return elements.filter { $0.componentType == type }
    }
    
    /// Vraća konekcije za određeni element iz liste
    static func getConnections(for elementId: UUID) -> [TopologyConnection] {
        return connections.filter { 
            $0.fromComponentId == elementId || $0.toComponentId == elementId 
        }
    }
    
    /// Vraća sve elemente povezane s određenim elementom
    static func getConnectedElements(for elementId: UUID) -> [TopologyElement] {
        let connectedIds = connections.compactMap { conn -> UUID? in
            if conn.fromComponentId == elementId {
                return conn.toComponentId
            } else if conn.toComponentId == elementId {
                return conn.fromComponentId
            }
            return nil
        }
        return elements.filter { connectedIds.contains($0.id) }
    }
    
    // MARK: - Statistike
    
    /// Broj elemenata u listi
    static var elementCount: Int {
        return elements.count
    }
    
    /// Broj konekcija u listi
    static var connectionCount: Int {
        return connections.count
    }
}

// MARK: - TopologyElement Model

struct TopologyElement: Identifiable, Codable {
    let id: UUID
    let componentType: String
    let position: CGPoint
    let name: String
    let customColorRed: Double?
    let customColorGreen: Double?
    let customColorBlue: Double?
    let areaWidth: CGFloat?
    let areaHeight: CGFloat?
}

// MARK: - TopologyConnection Model

struct TopologyConnection: Identifiable, Codable {
    let id: UUID
    let fromComponentId: UUID
    let toComponentId: UUID
    let connectionType: String
    let fromConnectionPoint: ConnectionPointData?
    let toConnectionPoint: ConnectionPointData?
    let controlPoint: CGPoint?
    let curveType: String?
}

// MARK: - ConnectionPointData Model

struct ConnectionPointData: Codable {
    let direction: String
}

"""
        
        return code
    }
    
    /// Generira Swift kod za pojedini element
    private func generateElementCode(_ component: NetworkComponent, isLast: Bool) -> String {
        var code = "        TopologyElement(\n"
        code += "            id: UUID(uuidString: \"\(component.id.uuidString)\")!,\n"
        code += "            componentType: \"\(component.componentType.rawValue)\",\n"
        code += "            position: CGPoint(x: \(component.position.x), y: \(component.position.y)),\n"
        code += "            name: \"\(component.name.replacingOccurrences(of: "\"", with: "\\\""))\",\n"
        
        if let red = component.customColorRed,
           let green = component.customColorGreen,
           let blue = component.customColorBlue {
            code += "            customColorRed: \(red),\n"
            code += "            customColorGreen: \(green),\n"
            code += "            customColorBlue: \(blue),\n"
        } else {
            code += "            customColorRed: nil,\n"
            code += "            customColorGreen: nil,\n"
            code += "            customColorBlue: nil,\n"
        }
        
        if let width = component.areaWidth, let height = component.areaHeight {
            code += "            areaWidth: \(width),\n"
            code += "            areaHeight: \(height)\n"
        } else {
            code += "            areaWidth: nil,\n"
            code += "            areaHeight: nil\n"
        }
        
        code += "        )"
        if !isLast {
            code += ","
        }
        code += "\n"
        
        return code
    }
    
    /// Generira Swift kod za pojedinu konekciju
    private func generateConnectionCode(_ connection: NetworkConnection, isLast: Bool) -> String {
        var code = "        TopologyConnection(\n"
        code += "            id: UUID(uuidString: \"\(connection.id.uuidString)\")!,\n"
        code += "            fromComponentId: UUID(uuidString: \"\(connection.fromComponentId.uuidString)\")!,\n"
        code += "            toComponentId: UUID(uuidString: \"\(connection.toComponentId.uuidString)\")!,\n"
        code += "            connectionType: \"\(connection.connectionType.rawValue)\",\n"
        
        if let fromPoint = connection.fromConnectionPoint {
            code += "            fromConnectionPoint: ConnectionPointData(\n"
            code += "                direction: \"\(fromPoint.rawValue)\"\n"
            code += "            ),\n"
        } else {
            code += "            fromConnectionPoint: nil,\n"
        }
        
        if let toPoint = connection.toConnectionPoint {
            code += "            toConnectionPoint: ConnectionPointData(\n"
            code += "                direction: \"\(toPoint.rawValue)\"\n"
            code += "            ),\n"
        } else {
            code += "            toConnectionPoint: nil,\n"
        }
        
        if let controlPoint = connection.controlPoint {
            code += "            controlPoint: CGPoint(x: \(controlPoint.x), y: \(controlPoint.y)),\n"
        } else {
            code += "            controlPoint: nil,\n"
        }
        
        if let curveType = connection.curveType {
            code += "            curveType: \"\(curveType.rawValue)\"\n"
        } else {
            code += "            curveType: nil\n"
        }
        
        code += "        )"
        if !isLast {
            code += ","
        }
        code += "\n"
        
        return code
    }
    
    // MARK: - Load from Swift File
    
    /// Učitava topologiju iz Swift datoteke
    /// Note: Swift file parsing not yet implemented - use JSON format instead
    func loadTopologyFromSwiftFile(from url: URL) throws -> (elements: [Any], connections: [Any]) {
        let content = try String(contentsOf: url, encoding: .utf8)
        
        // Parse Swift file - extract data
        // Ovo je pojednostavljena verzija - u produkciji bi trebalo koristiti Swift parser
        // Za sada ćemo koristiti JSON export/import kao alternativu
        
        throw TopologyStorageError.swiftFileParsingNotImplemented
    }
    
    // MARK: - Alternative: Save/Load as JSON (for easier parsing)
    
    /// Sprema topologiju u JSON format (lakše za učitavanje)
    func saveTopologyToJSON(_ topology: NetworkTopology, to url: URL) throws {
        let data = try topology.exportToJSON()
        try data.write(to: url)
    }
    
    /// Učitava topologiju iz JSON datoteke
    func loadTopologyFromJSON(from url: URL) throws -> NetworkTopology {
        let data = try Data(contentsOf: url)
        return try NetworkTopology.importFromJSON(data)
    }
}

// MARK: - Errors

enum TopologyStorageError: Error {
    case swiftFileParsingNotImplemented
    case invalidFileFormat
    case fileNotFound
}

