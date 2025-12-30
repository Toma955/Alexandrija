//
//  Problems.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// ⚠️ Problemi (Problems) – degradacija
/// Ovi problemi predstavljaju degradaciju performansi, ali komponenta i dalje funkcionira
/// 
/// Note: HighLatency, PacketLoss već postoje u Shared/NetworkTopology/Logic/ComponentProblem.swift

// MARK: - Unstable Link Problem

/// Nestabilan link
class UnstableLink: ComponentProblem {
    let name = "Unstable Link"
    let description = "Link connection is unstable"
    let severity: ProblemSeverity = .medium
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement unstable link logic
    }
    
    func resolve() {
        // TODO: Implement link stabilization logic
    }
}

// MARK: - Flapping Port Problem

/// Port flapping (stalno se pali/gasi)
class FlappingPort: ComponentProblem {
    let name = "Flapping Port"
    let description = "Port is flapping (continuously going up and down)"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement flapping port logic
    }
    
    func resolve() {
        // TODO: Implement port stabilization logic
    }
}

// MARK: - Weak WiFi Problem

/// Slab WiFi signal
class WeakWiFi: ComponentProblem {
    let name = "Weak WiFi"
    let description = "WiFi signal strength is weak"
    let severity: ProblemSeverity = .medium
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement weak WiFi logic
    }
    
    func resolve() {
        // TODO: Implement WiFi signal improvement logic
    }
}

// MARK: - Congestion Problem

/// Preopterećenje mreže
class Congestion: ComponentProblem {
    let name = "Congestion"
    let description = "Network is congested"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement congestion logic
    }
    
    func resolve() {
        // TODO: Implement congestion reduction logic
    }
}

// MARK: - Oversubscription Problem

/// Preplaćivanje (više korisnika nego što mreža može podržati)
class Oversubscription: ComponentProblem {
    let name = "Oversubscription"
    let description = "Network is oversubscribed"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement oversubscription logic
    }
    
    func resolve() {
        // TODO: Implement oversubscription reduction logic
    }
}

// MARK: - QoS Degraded Problem

/// Degradacija QoS-a (Quality of Service)
class QoSDegraded: ComponentProblem {
    let name = "QoS Degraded"
    let description = "Quality of Service is degraded"
    let severity: ProblemSeverity = .medium
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement QoS degradation logic
    }
    
    func resolve() {
        // TODO: Implement QoS restoration logic
    }
}

// MARK: - Broadcast Storm Problem

/// Broadcast oluja
class BroadcastStorm: ComponentProblem {
    let name = "Broadcast Storm"
    let description = "Broadcast storm detected"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement broadcast storm logic
    }
    
    func resolve() {
        // TODO: Implement broadcast storm mitigation logic
    }
}

// MARK: - VLAN Mismatch Problem

/// Neusklađenost VLAN-a
class VLANMismatch: ComponentProblem {
    let name = "VLAN Mismatch"
    let description = "VLAN configuration mismatch detected"
    let severity: ProblemSeverity = .medium
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement VLAN mismatch logic
    }
    
    func resolve() {
        // TODO: Implement VLAN configuration fix logic
    }
}

// MARK: - MAC Overflow Problem

/// MAC tablica je prepuna
class MACOverflow: ComponentProblem {
    let name = "MAC Overflow"
    let description = "MAC address table is full"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement MAC overflow logic
    }
    
    func resolve() {
        // TODO: Implement MAC table cleanup logic
    }
}

// MARK: - High CPU Problem

/// Visoka CPU upotreba
class HighCPU: ComponentProblem {
    let name = "High CPU"
    let description = "Component CPU usage is high"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement high CPU logic
    }
    
    func resolve() {
        // TODO: Implement CPU load reduction logic
    }
}

// MARK: - High Memory Usage Problem

/// Visoka upotreba memorije
class HighMemoryUsage: ComponentProblem {
    let name = "High Memory Usage"
    let description = "Component memory usage is high"
    let severity: ProblemSeverity = .high
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement high memory usage logic
    }
    
    func resolve() {
        // TODO: Implement memory optimization logic
    }
}

// MARK: - Configuration Drift Problem

/// Konfiguracija je odstupila od očekivane
class ConfigurationDrift: ComponentProblem {
    let name = "Configuration Drift"
    let description = "Component configuration has drifted from expected state"
    let severity: ProblemSeverity = .medium
    
    func apply(to component: NetworkComponent) {
        // TODO: Implement configuration drift logic
    }
    
    func resolve() {
        // TODO: Implement configuration restoration logic
    }
}

