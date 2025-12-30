//
//  RouterLogic.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Logic za Router komponentu
class RouterLogic: BaseComponentLogic {
    
    /// Dostupni problemi za Router komponentu
    static var availableProblems: [ComponentProblem.Type] {
        return [
            PowerOff.self,
            RestartInProgress.self,
            ConfigurationLoss.self,
            IPAddressChange.self,
            DuplicateIPAddress.self,
            MACAddressChange.self,
            InvalidRoutingTable.self,
            RoutingLoop.self,
            CPUOverload.self,
            Overheating.self,
            InterfaceDown.self,
            PacketLoss.self,
            HighLatency.self
        ]
    }
    
    override init(componentType: NetworkComponent.ComponentType) {
        super.init(componentType: .router)
    }
    
    override func canConnect(to other: NetworkComponent) -> Bool {
        // Router can connect to most network components
        switch other.componentType {
        case .server, .router, .switchDevice, .modem, .accessPoint,
             .firewall, .vpnGateway, .loadBalancer, .cloud, .edgeNode,
             .dnsServer, .dhcpServer, .isp, .satelliteGateway:
            return true
        default:
            return false
        }
    }
    
    override func processPacket(_ packet: NetworkPacket) -> NetworkPacket? {
        // Router forwards packets based on routing table
        // TODO: Implement routing logic
        return packet
    }
    
    override func getCapabilities() -> [ComponentCapability] {
        return [
            ComponentCapability(name: "Packet Routing", description: "Routes packets based on routing table"),
            ComponentCapability(name: "NAT", description: "Network Address Translation"),
            ComponentCapability(name: "DHCP Server", description: "Can act as DHCP server"),
            ComponentCapability(name: "Firewall", description: "Basic firewall capabilities")
        ]
    }
}
