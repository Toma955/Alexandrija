//
//  Errors.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// ❌ Greške (Errors) – hard stop
/// Ove greške predstavljaju kritične probleme koji zaustavljaju funkcionalnost komponente
/// 
/// Note: PowerOff, InterfaceDown, FirmwareCorruption već postoje u Shared/NetworkTopology/Logic/ComponentProblem.swift

// MARK: - No Link Error

/// Nema linka na interfejsu
class NoLink: ComponentProblem {
    let name = "No Link"
    let description = "No link detected on interface"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement no link logic
    }
    
    func resolve() {
        // TODO: Implement link restoration logic
    }
}

// MARK: - Port Down Error

/// Port je down
class PortDown: ComponentProblem {
    let name = "Port Down"
    let description = "Port is down"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement port down logic
    }
    
    func resolve() {
        // TODO: Implement port up logic
    }
}

// MARK: - No IP Error

/// Komponenta nema IP adresu
class NoIP: ComponentProblem {
    let name = "No IP"
    let description = "Component has no IP address assigned"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement no IP logic
    }
    
    func resolve() {
        // TODO: Implement IP assignment logic
    }
}

// MARK: - DHCP Failure Error

/// DHCP ne radi
class DHCPFailure: ComponentProblem {
    let name = "DHCP Failure"
    let description = "DHCP service is not functioning"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement DHCP failure logic
    }
    
    func resolve() {
        // TODO: Implement DHCP restoration logic
    }
}

// MARK: - DNS Failure Error

/// DNS ne radi
class DNSFailure: ComponentProblem {
    let name = "DNS Failure"
    let description = "DNS service is not functioning"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement DNS failure logic
    }
    
    func resolve() {
        // TODO: Implement DNS restoration logic
    }
}

// MARK: - Gateway Unreachable Error

/// Gateway je nedostupan
class GatewayUnreachable: ComponentProblem {
    let name = "Gateway Unreachable"
    let description = "Gateway is unreachable"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement gateway unreachable logic
    }
    
    func resolve() {
        // TODO: Implement gateway reachability restoration logic
    }
}

// MARK: - Routing Table Error

/// Greška u routing tablici
class RoutingTableError: ComponentProblem {
    let name = "Routing Table Error"
    let description = "Routing table has errors"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement routing table error logic
    }
    
    func resolve() {
        // TODO: Implement routing table fix logic
    }
}

// MARK: - STP Failure Error

/// STP (Spanning Tree Protocol) ne radi
class STPFailure: ComponentProblem {
    let name = "STP Failure"
    let description = "Spanning Tree Protocol is not functioning"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement STP failure logic
    }
    
    func resolve() {
        // TODO: Implement STP restoration logic
    }
}

// MARK: - Hardware Failure Error

/// Hardverski kvar
class HardwareFailure: ComponentProblem {
    let name = "Hardware Failure"
    let description = "Component has hardware failure"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement hardware failure logic
    }
    
    func resolve() {
        // TODO: Implement hardware repair logic
    }
}

// MARK: - Authentication Failure Error

/// Greška u autentifikaciji
class AuthenticationFailure: ComponentProblem {
    let name = "Authentication Failure"
    let description = "Component authentication has failed"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement authentication failure logic
    }
    
    func resolve() {
        // TODO: Implement authentication restoration logic
    }
}

