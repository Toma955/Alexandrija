//
//  BaseTopologyElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Enum za vidljivost elementa
enum ElementVisibility {
    case `public`
    case `private`
}

/// Base klasa za sve topology elemente
/// Upravlja logikom pojedine komponente u topologiji
class BaseTopologyElement: ObservableObject {
    @Published var editMode: Bool = true
    @Published var settingsMode: Bool = false
    @Published var topology: NetworkTopology?
    
    let component: NetworkComponent
    let visibility: ElementVisibility
    
    /// Connection points za ovu komponentu
    var connectionPoints: [ConnectionPoint] {
        // Standardni pinovi za sve komponente
        return [.top, .bottom, .left, .right, .topLeft, .topRight, .bottomLeft, .bottomRight]
    }
    
    init(component: NetworkComponent, visibility: ElementVisibility, topology: NetworkTopology? = nil) {
        self.component = component
        self.visibility = visibility
        self.topology = topology
    }
    
    /// Vraća boju ikone ovisno o mode-u
    func getIconColor() -> Color {
        if settingsMode {
            // Config mode: narančasta boja
            return Color(red: 1.0, green: 0.36, blue: 0.0)
        } else {
            // Edit mode: siva boja
            return .gray
        }
    }
    
    /// Vraća poziciju pina za dani connection point
    func getPinPosition(_ point: ConnectionPoint, componentCenter: CGPoint) -> CGPoint {
        return ConnectionPointDetector.position(for: point, componentCenter: componentCenter)
    }
    
    /// Otvara settings menu
    func openSettings() {
        settingsMode = true
        objectWillChange.send()
    }
    
    /// Prikazuje settings menu view
    func showSettingsMenu() -> some View {
        ComponentSettingsView(component: component, topology: topology)
    }
}

/// View za settings menu komponente
struct ComponentSettingsView: View {
    @ObservedObject var component: NetworkComponent
    var topology: NetworkTopology?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Component Settings")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Name: \(component.name)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Type: \(component.componentType.displayName)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .frame(width: 300, height: 200)
        .background(Color.black.opacity(0.8))
    }
}

