//
//  RouterLogic.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Logic za Router komponentu
class RouterLogic: BaseComponentLogic {
    override init(componentType: NetworkComponent.ComponentType) {
        super.init(componentType: .router)
    }
    
    override func getCapabilities() -> [ComponentCapability] {
        return [
            ComponentCapability(name: "Routing", description: "Routes packets between networks"),
            ComponentCapability(name: "NAT", description: "Network Address Translation"),
            ComponentCapability(name: "DHCP", description: "Dynamic Host Configuration Protocol")
        ]
    }
    
    override func canConnect(to other: NetworkComponent) -> Bool {
        // Router can connect to most network devices
        return true
    }
}







