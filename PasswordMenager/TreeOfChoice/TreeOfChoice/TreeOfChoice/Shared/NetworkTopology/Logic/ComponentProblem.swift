//
//  ComponentProblem.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Protokol za probleme komponenti u mreži
/// Svaki problem može se primijeniti na komponentu i riješiti
protocol ComponentProblem: AnyObject {
    var name: String { get }
    var description: String { get }
    var severity: ProblemSeverity { get }
    
    /// Primijeni problem na komponentu
    func apply(to component: NetworkComponent)
    
    /// Riješi problem na komponenti
    func resolve()
}

/// Težina problema
enum ProblemSeverity: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Router Problems

/// Router je isključen
class PowerOff: ComponentProblem {
    let name = "Power Off"
    let description = "Router is powered off"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement power off logic
    }
    
    func resolve() {
        // TODO: Implement power on logic
    }
}

/// Router se restartira
class RestartInProgress: ComponentProblem {
    let name = "Restart In Progress"
    let description = "Router is restarting"
    let severity: ProblemSeverity = .medium
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement restart logic
    }
    
    func resolve() {
        // TODO: Implement restart completion logic
    }
}

/// Gubitak konfiguracije
class ConfigurationLoss: ComponentProblem {
    let name = "Configuration Loss"
    let description = "Router has lost its configuration"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement configuration loss logic
    }
    
    func resolve() {
        // TODO: Implement configuration restore logic
    }
}

/// Promjena IP adrese
class IPAddressChange: ComponentProblem {
    let name = "IP Address Change"
    let description = "Router IP address has changed"
    let severity: ProblemSeverity = .medium
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement IP change logic
    }
    
    func resolve() {
        // TODO: Implement IP restore logic
    }
}

/// Duplikat IP adrese
class DuplicateIPAddress: ComponentProblem {
    let name = "Duplicate IP Address"
    let description = "Router has duplicate IP address"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement duplicate IP logic
    }
    
    func resolve() {
        // TODO: Implement duplicate IP resolution logic
    }
}

/// Promjena MAC adrese
class MACAddressChange: ComponentProblem {
    let name = "MAC Address Change"
    let description = "Router MAC address has changed"
    let severity: ProblemSeverity = .medium
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement MAC change logic
    }
    
    func resolve() {
        // TODO: Implement MAC restore logic
    }
}

/// Nevažeća routing tablica
class InvalidRoutingTable: ComponentProblem {
    let name = "Invalid Routing Table"
    let description = "Router has invalid routing table entries"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement invalid routing table logic
    }
    
    func resolve() {
        // TODO: Implement routing table fix logic
    }
}

/// Routing loop
class RoutingLoop: ComponentProblem {
    let name = "Routing Loop"
    let description = "Router is causing routing loops"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement routing loop logic
    }
    
    func resolve() {
        // TODO: Implement routing loop resolution logic
    }
}

/// Preopterećenje CPU-a
class CPUOverload: ComponentProblem {
    let name = "CPU Overload"
    let description = "Router CPU is overloaded"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement CPU overload logic
    }
    
    func resolve() {
        // TODO: Implement CPU load reduction logic
    }
}

/// Pregrijavanje
class Overheating: ComponentProblem {
    let name = "Overheating"
    let description = "Router is overheating"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement overheating logic
    }
    
    func resolve() {
        // TODO: Implement cooling logic
    }
}

/// Interface je down
class InterfaceDown: ComponentProblem {
    let name = "Interface Down"
    let description = "Router interface is down"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement interface down logic
    }
    
    func resolve() {
        // TODO: Implement interface up logic
    }
}

/// Gubitak paketa
class PacketLoss: ComponentProblem {
    let name = "Packet Loss"
    let description = "Router is experiencing packet loss"
    let severity: ProblemSeverity = .medium
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement packet loss logic
    }
    
    func resolve() {
        // TODO: Implement packet loss resolution logic
    }
}

/// Visoka latencija
class HighLatency: ComponentProblem {
    let name = "High Latency"
    let description = "Router is experiencing high latency"
    let severity: ProblemSeverity = .medium
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement high latency logic
    }
    
    func resolve() {
        // TODO: Implement latency reduction logic
    }
}

// MARK: - Gateway Problems

/// Firewall blokira promet
class FirewallBlockingTraffic: ComponentProblem {
    let name = "Firewall Blocking Traffic"
    let description = "Gateway firewall is blocking traffic"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement firewall blocking logic
    }
    
    func resolve() {
        // TODO: Implement firewall unblock logic
    }
}

/// NAT ne radi
class NATNotWorking: ComponentProblem {
    let name = "NAT Not Working"
    let description = "Gateway NAT is not functioning"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement NAT failure logic
    }
    
    func resolve() {
        // TODO: Implement NAT fix logic
    }
}

/// DNS forwarding ne radi
class DNSForwardingNotWorking: ComponentProblem {
    let name = "DNS Forwarding Not Working"
    let description = "Gateway DNS forwarding is not functioning"
    let severity: ProblemSeverity = .medium
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement DNS forwarding failure logic
    }
    
    func resolve() {
        // TODO: Implement DNS forwarding fix logic
    }
}

/// Zastarjeli firmware
class FirmwareOutdated: ComponentProblem {
    let name = "Firmware Outdated"
    let description = "Gateway firmware is outdated"
    let severity: ProblemSeverity = .low
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement outdated firmware logic
    }
    
    func resolve() {
        // TODO: Implement firmware update logic
    }
}

/// Oštećen firmware
class FirmwareCorruption: ComponentProblem {
    let name = "Firmware Corruption"
    let description = "Gateway firmware is corrupted"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement firmware corruption logic
    }
    
    func resolve() {
        // TODO: Implement firmware restore logic
    }
}

/// Neovlašten pristup
class UnauthorizedAccess: ComponentProblem {
    let name = "Unauthorized Access"
    let description = "Gateway has unauthorized access attempts"
    let severity: ProblemSeverity = .critical
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement unauthorized access logic
    }
    
    func resolve() {
        // TODO: Implement access blocking logic
    }
}

