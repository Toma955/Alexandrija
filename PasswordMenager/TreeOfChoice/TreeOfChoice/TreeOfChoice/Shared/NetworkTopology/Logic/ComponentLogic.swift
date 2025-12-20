//
//  ComponentLogic.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Logic za mrežne komponente
/// Svaka komponenta ima svoju logiku koja definira kako se ponaša u mreži

protocol NetworkComponentLogic {
    var componentType: NetworkComponent.ComponentType { get }
    func canConnect(to other: NetworkComponent) -> Bool
    func processPacket(_ packet: NetworkPacket) -> NetworkPacket?
    func getCapabilities() -> [ComponentCapability]
}

struct ComponentCapability {
    let name: String
    let description: String
}

// MARK: - Base Implementation

class BaseComponentLogic: NetworkComponentLogic {
    let componentType: NetworkComponent.ComponentType
    
    init(componentType: NetworkComponent.ComponentType) {
        self.componentType = componentType
    }
    
    func canConnect(to other: NetworkComponent) -> Bool {
        // Default: can connect to anything
        return true
    }
    
    func processPacket(_ packet: NetworkPacket) -> NetworkPacket? {
        // Default: forward packet as-is
        return packet
    }
    
    func getCapabilities() -> [ComponentCapability] {
        return []
    }
}

// MARK: - Specific Component Logic
// Note: Individual component logic classes are in their respective folders:
// - Clients/ (MobileLogic, etc.)
// - Infrastructure/ (RouterLogic, ServerLogic, etc.)
// - Security/ (FirewallLogic, etc.)
// - Nilternius/ (NilterniusLogic)

// MARK: - Network Packet Model

struct NetworkPacket: Codable {
    let id: UUID
    let source: UUID
    let destination: UUID
    let payload: Data
    let timestamp: Date
    let packetProtocol: PacketProtocol
    
    enum PacketProtocol: String, Codable {
        case tcp = "TCP"
        case udp = "UDP"
        case icmp = "ICMP"
        case http = "HTTP"
        case https = "HTTPS"
    }
}

