//
//  ConnectionRuleValidator.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Validator koji provjerava pravila konekcija prije dodavanja konekcije
struct ConnectionRuleValidator {
    
    /// Rezultat validacije
    enum ValidationResult {
        case allowed
        case denied(reason: String)
    }
    
    /// Provjerava da li je konekcija dozvoljena između dvije komponente
    /// - Parameters:
    ///   - fromComponent: Komponenta od koje se spaja
    ///   - toComponent: Komponenta na koju se spaja
    ///   - topology: Topologija za provjeru putanje (opcionalno)
    /// - Returns: ValidationResult - je li dozvoljeno ili razlog zašto nije
    static func validateConnection(from fromComponent: NetworkComponent, 
                                   to toComponent: NetworkComponent,
                                   in topology: NetworkTopology? = nil) -> ValidationResult {
        
        // Provjeri da li se komponente ne pokušavaju spojiti same sa sobom
        if fromComponent.id == toComponent.id {
            return .denied(reason: "Komponenta se ne može spojiti sama sa sobom")
        }
        
        // Provjeri da li se DNS i DHCP serveri pokušavaju direktno spojiti
        if (fromComponent.componentType == .dnsServer && toComponent.componentType == .dhcpServer) ||
           (fromComponent.componentType == .dhcpServer && toComponent.componentType == .dnsServer) {
            return .denied(reason: "DNS i DHCP serveri se ne mogu direktno spojiti")
        }
        
        // Provjeri pravila konekcija
        let (allowed, reason) = ConnectionRules.isConnectionAllowed(
            from: fromComponent.componentType,
            to: toComponent.componentType
        )
        
        if !allowed {
            let errorMessage = reason ?? "Konekcija između \(fromComponent.componentType.displayName) i \(toComponent.componentType.displayName) nije dozvoljena"
            return .denied(reason: errorMessage)
        }
        
        // Konekcija je dozvoljena (ne blokiramo direktne konekcije između servera i client komponenti)
        // Umjesto toga, one će biti označene kao neispravne u test modu (crvena boja)
        return .allowed
    }
    
    /// Provjerava da li je konekcija dozvoljena između dvije komponente (po tipovima)
    /// - Parameters:
    ///   - fromType: Tip komponente od koje se spaja
    ///   - toType: Tip komponente na koju se spaja
    /// - Returns: ValidationResult - je li dozvoljeno ili razlog zašto nije
    static func validateConnection(from fromType: NetworkComponent.ComponentType, 
                                   to toType: NetworkComponent.ComponentType) -> ValidationResult {
        
        // Provjeri pravila konekcija
        let (allowed, reason) = ConnectionRules.isConnectionAllowed(
            from: fromType,
            to: toType
        )
        
        if allowed {
            return .allowed
        } else {
            let errorMessage = reason ?? "Konekcija između \(fromType.displayName) i \(toType.displayName) nije dozvoljena"
            return .denied(reason: errorMessage)
        }
    }
    
    /// Provjerava da li je konekcija dozvoljena između dvije komponente (po ID-ovima)
    /// - Parameters:
    ///   - topology: Topologija koja sadrži komponente
    ///   - fromId: ID komponente od koje se spaja
    ///   - toId: ID komponente na koju se spaja
    /// - Returns: ValidationResult - je li dozvoljeno ili razlog zašto nije
    static func validateConnection(in topology: NetworkTopology, 
                                   from fromId: UUID, 
                                   to toId: UUID) -> ValidationResult {
        
        // Pronađi komponente
        guard let fromComponent = topology.components.first(where: { $0.id == fromId }) else {
            return .denied(reason: "Komponenta s ID-om \(fromId) ne postoji na topologiji")
        }
        
        guard let toComponent = topology.components.first(where: { $0.id == toId }) else {
            return .denied(reason: "Komponenta s ID-om \(toId) ne postoji na topologiji")
        }
        
        return validateConnection(from: fromComponent, to: toComponent, in: topology)
    }
    
    /// Provjerava da li je konekcija neispravna (između servera i client komponenti bez routera/access pointa, ili server-NAS)
    /// - Parameters:
    ///   - connection: Konekcija za provjeru
    ///   - topology: Topologija koja sadrži komponente
    /// - Returns: true ako je konekcija neispravna
    static func isInvalidConnection(_ connection: NetworkConnection, in topology: NetworkTopology) -> Bool {
        guard let fromComponent = topology.components.first(where: { $0.id == connection.fromComponentId }),
              let toComponent = topology.components.first(where: { $0.id == connection.toComponentId }) else {
            return false
        }
        
        let serverTypes: Set<NetworkComponent.ComponentType> = [.server, .webServer, .databaseServer, .mailServer, .fileServer, .dnsServer, .dhcpServer, .businessServer, .nilterniusServer]
        let clientTypes: Set<NetworkComponent.ComponentType> = [.mobile, .desktop, .tablet, .laptop]
        
        let fromIsServer = serverTypes.contains(fromComponent.componentType)
        let toIsServer = serverTypes.contains(toComponent.componentType)
        let fromIsClient = clientTypes.contains(fromComponent.componentType)
        let toIsClient = clientTypes.contains(toComponent.componentType)
        
        // Provjeri da li je direktna konekcija između servera i client komponente
        if (fromIsServer && toIsClient) || (fromIsClient && toIsServer) {
            return true
        }
        
        // Provjeri da li je direktna konekcija između servera i NAS-a
        if (fromIsServer && toComponent.componentType == .nas) || (fromComponent.componentType == .nas && toIsServer) {
            return true
        }
        
        return false
    }
    
    /// Provjerava da li je komponenta dio neispravne konekcije
    /// - Parameters:
    ///   - component: Komponenta za provjeru
    ///   - topology: Topologija koja sadrži komponente
    /// - Returns: true ako je komponenta dio neispravne konekcije
    static func isComponentInInvalidConnection(_ component: NetworkComponent, in topology: NetworkTopology) -> Bool {
        let connections = topology.getConnections(for: component.id)
        return connections.contains { connection in
            isInvalidConnection(connection, in: topology)
        }
    }
}

