//
//  ClientSimulatorElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Element koji predstavlja Client Simulator - parent element za simulaciju klijenata
/// Odgovoran za upravljanje simulacijom klijenata i njihovim ponašanjem
class ClientSimulatorElement: ObservableObject {
    @Published var isSimulating: Bool = false
    @Published var simulatedClients: [NetworkComponent] = []
    @Published var simulationSpeed: Double = 1.0
    
    init() {
        // Initialize client simulator
    }
    
    func startSimulation() {
        isSimulating = true
        // TODO: Implement client simulation logic
    }
    
    func stopSimulation() {
        isSimulating = false
    }
    
    func addSimulatedClient(_ client: NetworkComponent) {
        simulatedClients.append(client)
        objectWillChange.send()
    }
    
    func removeSimulatedClient(_ client: NetworkComponent) {
        simulatedClients.removeAll { $0.id == client.id }
        objectWillChange.send()
    }
}

/// View wrapper za ClientSimulatorElement
struct ClientSimulatorElementView: View {
    @ObservedObject var clientSimulatorElement: ClientSimulatorElement
    @EnvironmentObject private var localization: LocalizationManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Client Simulator UI
            HStack {
                Image(systemName: clientSimulatorElement.isSimulating ? "person.3.fill" : "person.3")
                    .font(.title2)
                    .foregroundColor(clientSimulatorElement.isSimulating ? .green : .white.opacity(0.7))
                
                Text(localization.text("labConnect.clientSimulator") ?? "Client Simulator")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(clientSimulatorElement.simulatedClients.count)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
    }
}

