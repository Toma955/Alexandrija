//
//  ElementSettingsMenu.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Parent klasa/protokol za menu/postavke elemenata
/// Svi elementi nasljeđuju ovu klasu i automatski dobivaju menu za postavke
/// Menu se otvara kada se klikne na Button u Config mode-u
protocol ElementSettingsMenuProtocol {
    /// Komponenta za koju se prikazuju postavke
    var component: NetworkComponent { get }
    
    /// Topology reference (opcionalno)
    var topology: NetworkTopology? { get }
    
    /// Prikazuje menu/postavke za element
    /// Override u subklasama za specifične postavke
    func showSettingsMenu() -> AnyView
}

/// Bazna implementacija menu/postavki za elemente
/// Svi elementi nasljeđuju ovu klasu i automatski dobivaju menu
class ElementSettingsMenu: ObservableObject, ElementSettingsMenuProtocol {
    // MARK: - Properties
    
    @Published var component: NetworkComponent
    weak var topology: NetworkTopology?
    
    // MARK: - Initialization
    
    init(component: NetworkComponent, topology: NetworkTopology? = nil) {
        self.component = component
        self.topology = topology
    }
    
    // MARK: - ElementSettingsMenuProtocol Implementation
    
    /// Prikazuje menu/postavke za element
    /// Default implementacija - override u subklasama za specifične postavke
    func showSettingsMenu() -> AnyView {
        // Default: prikaži osnovne postavke
        // Pass component as @ObservedObject for binding support
        return AnyView(
            SettingsMenuView(component: component, topology: topology, customView: customSettingsView())
        )
    }
}

// MARK: - Settings Menu View

struct SettingsMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var component: NetworkComponent // Changed to @ObservedObject for binding
    let topology: NetworkTopology?
    let customView: AnyView
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header s close button-om
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(component.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(component.componentType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Close button - crveni krug s bijelim X
                Button(action: {
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close")
            }
            .padding(.bottom, 8)
                
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Custom settings view - override u subklasama za specifične postavke
            customView
            
            Spacer()
        }
        .padding(20)
        .frame(width: 450, height: 600) // Povećan frame za više sadržaja
        .background(Color.black.opacity(0.9))
        .cornerRadius(12)
    }
}

extension ElementSettingsMenu {
    /// Custom settings view - override u subklasama
    /// Default: prikaži osnovne postavke
    func customSettingsView() -> AnyView {
        // Pass component reference for binding support
        let content = NetworkAddressSettingsView(component: component, topology: topology)
        return AnyView(content)
    }
}

// MARK: - Network Address Settings View

private struct NetworkAddressSettingsView: View {
    @ObservedObject var component: NetworkComponent
    let topology: NetworkTopology?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Component Properties
                VStack(alignment: .leading, spacing: 12) {
                    Text("Properties")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Editable Name field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        TextField("Component Name", text: Binding(
                            get: { component.name },
                            set: { component.name = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    }
                    
                    SettingsPropertyRow(label: "Type", value: component.componentType.rawValue)
                    SettingsPropertyRow(label: "Position", value: "X: \(Int(component.position.x)), Y: \(Int(component.position.y))")
                    
                    if let areaWidth = component.areaWidth, let areaHeight = component.areaHeight {
                        SettingsPropertyRow(label: "Area Size", value: "\(Int(areaWidth)) x \(Int(areaHeight))")
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Connection Type - samo prikaz (ne može se birati)
                // Svi elementi imaju connection type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connection Type")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Zaokruženi button s tipom konekcije (samo prikaz, ne može se kliknuti)
                    HStack {
                        Text(component.connectionType?.displayName ?? "Public")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20) // Zaokruženi button
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Device Type Selector - samo za User Area
                if component.componentType == .userArea {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Device Type")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // Grid s 4 ikone: Tablet, Mobile, Desktop, Laptop
                        HStack(spacing: 16) {
                            ForEach([NetworkComponent.ComponentType.tablet, .mobile, .desktop, .laptop], id: \.self) { deviceType in
                                Button(action: {
                                    component.selectedDeviceType = deviceType
                                }) {
                                    VStack(spacing: 6) {
                                        // Ikona
                                        Image(systemName: ComponentIconHelper.icon(for: deviceType))
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(component.selectedDeviceType == deviceType ? .white : .white.opacity(0.6))
                                            .frame(width: 40, height: 40)
                                            .background(
                                                Circle()
                                                    .fill(component.selectedDeviceType == deviceType ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                                            )
                                        
                                        // Label
                                        Text(deviceType.displayName)
                                            .font(.caption2)
                                            .foregroundColor(component.selectedDeviceType == deviceType ? .white : .white.opacity(0.6))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                
                // Network Addresses
                VStack(alignment: .leading, spacing: 12) {
                    Text("Network Addresses")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // MAC Address
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MAC Address")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        TextField("00:1B:44:11:3A:B7", text: Binding(
                            get: { component.macAddress ?? "" },
                            set: { component.macAddress = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    }
                    
                    // Private IP Addresses
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Private IP Addresses")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.9))
                        
                        // Private IPv4
                        VStack(alignment: .leading, spacing: 4) {
                            Text("IPv4")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            TextField("192.168.1.100", text: Binding(
                                get: { component.privateIPv4 ?? "" },
                                set: { component.privateIPv4 = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                        }
                        
                        // Private IPv6
                        VStack(alignment: .leading, spacing: 4) {
                            Text("IPv6")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            TextField("fe80::1", text: Binding(
                                get: { component.privateIPv6 ?? "" },
                                set: { component.privateIPv6 = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                        }
                    }
                    
                    // Public IP Addresses
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Public IP Addresses")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.9))
                        
                        // Public IPv4
                        VStack(alignment: .leading, spacing: 4) {
                            Text("IPv4")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            TextField("203.0.113.1", text: Binding(
                                get: { component.publicIPv4 ?? "" },
                                set: { component.publicIPv4 = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                        }
                        
                        // Public IPv6
                        VStack(alignment: .leading, spacing: 4) {
                            Text("IPv6")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            TextField("2001:db8::1", text: Binding(
                                get: { component.publicIPv6 ?? "" },
                                set: { component.publicIPv6 = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                        }
                    }
                }
                
                // Connected Components
                if let topology = topology {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    let connections = topology.getConnections(for: component.id)
                    let connectedComponents = connections.compactMap { connection -> NetworkComponent? in
                        // Pronađi povezanu komponentu (from ili to, ali ne trenutnu)
                        if connection.fromComponentId == component.id {
                            return topology.components.first { $0.id == connection.toComponentId }
                        } else if connection.toComponentId == component.id {
                            return topology.components.first { $0.id == connection.fromComponentId }
                        }
                        return nil
                    }
                    
                    if !connectedComponents.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Connected Components")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Lista povezanih komponenti
                            ForEach(connectedComponents, id: \.id) { connectedComponent in
                                HStack {
                                    // Ikonica komponente (mali krug)
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(connectedComponent.name)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        
                                        Text(connectedComponent.componentType.displayName)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    // Strelica ili ikona za navigaciju
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Connected Components")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("No connected components")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                
                // Area Color Picker - samo za Area kategorije (ZADNJI - na kraju)
                if component.componentType.category == .area {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Area Color")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // Grid boja za odabir - sve boje su vidljive, sve su zeleni krug na sivoj pozadini
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(NetworkComponent.AreaColor.allCases, id: \.self) { colorOption in
                                VStack(spacing: 4) {
                                    Button(action: {
                                        component.selectedAreaColor = colorOption
                                    }) {
                                        ZStack {
                                            // Siva pozadina (uvijek za sve boje) - VIDLJIVA
                                            Circle()
                                                .fill(Color.gray.opacity(0.6)) // Povećana opacity da se vidi
                                                .frame(width: 44, height: 44)
                                            
                                            // Svaka boja prikazuje svoju boju (ne zelenu) - VIDLJIV
                                            // Ako je izabrana, prikaži tu boju, inače prikaži zelenu kao default
                                            Circle()
                                                .fill(colorOption.color) // UVIJEK prikaži boju opcije, ne zelenu
                                                .frame(width: 36, height: 36)
                                            
                                            // Bijeli border ako je izabrana
                                            if component.selectedAreaColor == colorOption {
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                                    .frame(width: 40, height: 40)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // Label za boju
                                    Text(colorOption.displayName)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Supporting Views

private struct SettingsPropertyRow: View {
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

