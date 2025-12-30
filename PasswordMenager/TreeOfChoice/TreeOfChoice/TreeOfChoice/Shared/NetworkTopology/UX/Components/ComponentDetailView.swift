//
//  ComponentDetailView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Detaljni view za prikaz i uređivanje komponente
struct ComponentDetailView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject var component: NetworkComponent
    @ObservedObject var topology: NetworkTopology
    @Binding var isPresented: Bool
    @State private var selectedAgent: AgentType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(component.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(component.componentType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Component Properties
            VStack(alignment: .leading, spacing: 12) {
                Text(localization.text("topology.properties"))
                    .font(.headline)
                    .foregroundColor(.white)
                
                PropertyRow(label: localization.text("topology.type"), value: component.componentType.displayName)
                PropertyRow(label: localization.text("topology.position"), value: "X: \(Int(component.position.x)), Y: \(Int(component.position.y))")
                
                if component.isClientA == true {
                    PropertyRow(label: localization.text("topology.client"), value: "Client A")
                } else if component.isClientB == true {
                    PropertyRow(label: localization.text("topology.client"), value: "Client B")
                }
            }
            
            // Agent Assignment
            VStack(alignment: .leading, spacing: 12) {
                Text(localization.text("topology.agent"))
                    .font(.headline)
                    .foregroundColor(.white)
                
                let currentAgent = topology.getAgent(for: component.id)
                
                HStack(spacing: 12) {
                    ForEach([AgentType.watchman, .connection, .counterintelligence, .security, .intelligence, .analysis, .monitoring], id: \.self) { agent in
                        AgentButton(
                            agent: agent,
                            isSelected: currentAgent == agent,
                            action: {
                                if currentAgent == agent {
                                    topology.removeAgent(from: component.id)
                                } else {
                                    topology.assignAgent(to: component.id, agent: agent)
                                }
                            }
                        )
                    }
                }
            }
            
            // Capabilities (if logic exists)
            if let logic = getLogic(for: component.componentType) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localization.text("topology.capabilities"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(logic.getCapabilities(), id: \.name) { capability in
                        CapabilityRow(capability: capability)
                    }
                }
            }
            
            // Connections
            let connections = topology.getConnections(for: component.id)
            if !connections.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localization.text("topology.connections"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(connections) { connection in
                        ConnectionRow(
                            connection: connection,
                            topology: topology,
                            currentComponentId: component.id
                        )
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    topology.components.removeAll { $0.id == component.id }
                    topology.connections.removeAll { 
                        $0.fromComponentId == component.id || $0.toComponentId == component.id 
                    }
                    topology.removeAgent(from: component.id)
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text(localization.text("topology.delete"))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 400, height: 600)
        .background(Color.black.opacity(0.9))
        .cornerRadius(12)
        .onAppear {
            selectedAgent = topology.getAgent(for: component.id)
        }
    }
    
    private func getLogic(for type: NetworkComponent.ComponentType) -> NetworkComponentLogic? {
        switch type {
        case .mobile: return MobileLogic(componentType: .mobile)
        case .router: return RouterLogic(componentType: .router)
        case .firewall: return FirewallLogic(componentType: .firewall)
        case .nilternius: return NilterniusLogic(componentType: .nilternius)
        default: return nil
        }
    }
}

// MARK: - Supporting Views

struct PropertyRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
    }
}

struct AgentButton: View {
    let agent: AgentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: agent.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : agent.color)
                
                Text(agent.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(width: 70, height: 70)
            .background(isSelected ? agent.color : Color.white.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct CapabilityRow: View {
    let capability: ComponentCapability
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(capability.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(capability.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }
}

struct ConnectionRow: View {
    let connection: NetworkConnection
    @ObservedObject var topology: NetworkTopology
    let currentComponentId: UUID
    
    var body: some View {
        HStack {
            if let otherComponent = topology.components.first(where: { 
                $0.id == (connection.fromComponentId == currentComponentId ? connection.toComponentId : connection.fromComponentId)
            }) {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.blue)
                
                Text(otherComponent.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(connection.connectionType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }
}

