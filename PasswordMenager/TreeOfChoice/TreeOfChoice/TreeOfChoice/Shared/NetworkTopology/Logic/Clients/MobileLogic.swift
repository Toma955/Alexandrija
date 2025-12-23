//
//  MobileLogic.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Logic za Mobile komponentu
class MobileLogic: BaseComponentLogic {
    override init(componentType: NetworkComponent.ComponentType) {
        super.init(componentType: .mobile)
    }
    
    override func getCapabilities() -> [ComponentCapability] {
        return [
            ComponentCapability(name: "Wireless Communication", description: "Connects via Wi-Fi or cellular"),
            ComponentCapability(name: "Mobile App", description: "Can run mobile applications"),
            ComponentCapability(name: "Location Services", description: "GPS and location tracking")
        ]
    }
    
    override func canConnect(to other: NetworkComponent) -> Bool {
        // Mobile can connect to routers, access points, signal towers
        switch other.componentType {
        case .routerWifi, .accessPoint, .signalTower, .router:
            return true
        default:
            return false
        }
    }
}








