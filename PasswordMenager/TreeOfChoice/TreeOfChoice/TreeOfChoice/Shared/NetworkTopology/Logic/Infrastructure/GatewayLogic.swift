//
//  GatewayLogic.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Logic za Gateway komponentu (Satellite Gateway)
class GatewayLogic: BaseComponentLogic {
    
    /// Dostupni problemi za Gateway komponentu
    static var availableProblems: [ComponentProblem.Type] {
        return [
            PowerOff.self,
            RestartInProgress.self,
            ConfigurationLoss.self,
            FirewallBlockingTraffic.self,
            NATNotWorking.self,
            DNSForwardingNotWorking.self,
            FirmwareOutdated.self,
            FirmwareCorruption.self,
            UnauthorizedAccess.self,
            CPUOverload.self,
            Overheating.self,
            InterfaceDown.self,
            PacketLoss.self,
            HighLatency.self
        ]
    }
    
    override init(componentType: NetworkComponent.ComponentType) {
        super.init(componentType: .satelliteGateway)
    }
    
    override func canConnect(to other: NetworkComponent) -> Bool {
        // Gateway can connect to routers, satellites, ISPs, and other gateways
        switch other.componentType {
        case .router, .satelliteGateway, .isp, .cellTower,
             .server, .cloud, .edgeNode:
            return true
        default:
            return false
        }
    }
    
    override func processPacket(_ packet: NetworkPacket) -> NetworkPacket? {
        // Gateway processes packets with NAT, firewall, and routing
        // TODO: Implement gateway processing logic
        return packet
    }
    
    override func getCapabilities() -> [ComponentCapability] {
        return [
            ComponentCapability(name: "Satellite Communication", description: "Communicates via satellite"),
            ComponentCapability(name: "NAT", description: "Network Address Translation"),
            ComponentCapability(name: "Firewall", description: "Advanced firewall capabilities"),
            ComponentCapability(name: "DNS Forwarding", description: "Forwards DNS queries"),
            ComponentCapability(name: "VPN", description: "VPN gateway capabilities")
        ]
    }
}

