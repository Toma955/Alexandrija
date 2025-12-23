//
//  ConnectionRuleValidator.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Validator za provjeru valjanosti konekcija između mrežnih komponenti
struct ConnectionRuleValidator {
    
    /// Provjerava da li je komponenta dio neispravne konekcije
    /// - Parameters:
    ///   - component: Komponenta za provjeru
    ///   - topology: Topologija koja sadrži sve komponente i konekcije
    /// - Returns: `true` ako komponenta ima neispravne konekcije, `false` inače
    static func isComponentInInvalidConnection(_ component: NetworkComponent, in topology: NetworkTopology) -> Bool {
        let connections = topology.getConnections(for: component.id)
        
        for connection in connections {
            // Pronađi drugu komponentu u konekciji
            let otherComponentId = connection.fromComponentId == component.id 
                ? connection.toComponentId 
                : connection.fromComponentId
            
            guard let otherComponent = topology.components.first(where: { $0.id == otherComponentId }) else {
                // Konekcija vodi do nepostojeće komponente - neispravno
                return true
            }
            
            // Provjeri valjanost konekcije između ove dvije komponente
            if !isValidConnection(from: component, to: otherComponent) {
                return true
            }
        }
        
        return false
    }
    
    /// Provjerava da li je konekcija između dvije komponente valjana
    /// - Parameters:
    ///   - from: Izvorna komponenta
    ///   - to: Odredišna komponenta
    /// - Returns: `true` ako je konekcija valjana, `false` inače
    static func isValidConnection(from: NetworkComponent, to: NetworkComponent) -> Bool {
        // Osnovna pravila valjanosti konekcija
        
        // 1. Komponenta ne može biti povezana sama sa sobom
        if from.id == to.id {
            return false
        }
        
        // 2. Area komponente mogu biti povezane samo s određenim tipovima
        let areaTypes: [NetworkComponent.ComponentType] = [.userArea, .businessArea, .businessPrivateArea, .nilterniusArea]
        if areaTypes.contains(from.componentType) {
            // Area komponente mogu biti povezane s bilo kojom komponentom unutar svoje zone
            // Za sada dopuštamo sve konekcije
            return true
        }
        
        if areaTypes.contains(to.componentType) {
            // Isto pravilo vrijedi i obrnuto
            return true
        }
        
        // 3. Client komponente (Client A i Client B) mogu biti povezane s bilo kojom komponentom
        if from.isClientA == true || from.isClientB == true || to.isClientA == true || to.isClientB == true {
            return true
        }
        
        // 4. ISP (Satellite Earth Station) može biti povezan samo s određenim tipovima
        if from.componentType == .isp {
            // ISP može biti povezan s: satellite gateway, cell tower, router, modem
            let allowedTypes: [NetworkComponent.ComponentType] = [
                .satelliteGateway, .cellTower, .router, .modem, .signalTower
            ]
            return allowedTypes.contains(to.componentType)
        }
        
        if to.componentType == .isp {
            let allowedTypes: [NetworkComponent.ComponentType] = [
                .satelliteGateway, .cellTower, .router, .modem, .signalTower
            ]
            return allowedTypes.contains(from.componentType)
        }
        
        // 5. Satellite Gateway može biti povezan s: ISP, router, modem, cell tower
        if from.componentType == .satelliteGateway {
            let allowedTypes: [NetworkComponent.ComponentType] = [
                .isp, .router, .modem, .cellTower, .signalTower, .user
            ]
            return allowedTypes.contains(to.componentType)
        }
        
        if to.componentType == .satelliteGateway {
            let allowedTypes: [NetworkComponent.ComponentType] = [
                .isp, .router, .modem, .cellTower, .signalTower, .user
            ]
            return allowedTypes.contains(from.componentType)
        }
        
        // 6. User (Satellite) može biti povezan s: satellite gateway, cell tower, signal tower
        if from.componentType == .user {
            let allowedTypes: [NetworkComponent.ComponentType] = [
                .satelliteGateway, .cellTower, .signalTower
            ]
            return allowedTypes.contains(to.componentType)
        }
        
        if to.componentType == .user {
            let allowedTypes: [NetworkComponent.ComponentType] = [
                .satelliteGateway, .cellTower, .signalTower
            ]
            return allowedTypes.contains(from.componentType)
        }
        
        // 7. Default: sve ostale konekcije su valjane
        // Ovdje možete dodati dodatna pravila prema potrebi
        return true
    }
    
    /// Provjerava da li se konekcija može stvoriti između dvije komponente
    /// - Parameters:
    ///   - from: Izvorna komponenta
    ///   - to: Odredišna komponenta
    /// - Returns: `true` ako se konekcija može stvoriti, `false` inače
    static func canCreateConnection(from: NetworkComponent, to: NetworkComponent) -> Bool {
        return isValidConnection(from: from, to: to)
    }
}

