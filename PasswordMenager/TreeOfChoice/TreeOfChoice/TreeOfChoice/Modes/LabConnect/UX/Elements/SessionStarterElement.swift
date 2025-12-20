//
//  SessionStarterElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Element koji predstavlja Session Starter - parent element za pokretanje sesija
/// Odgovoran za upravljanje sesijama i njihovim pokretanjem
class SessionStarterElement: ObservableObject {
    @Published var isActive: Bool = false
    @Published var currentSessionId: UUID?
    @Published var isStarting: Bool = false
    @Published var selectedMode: String = "Default"
    @Published var selectedType: String = "Standard"
    @Published var dnsEnabled: Bool = false
    @Published var dhcpEnabled: Bool = false
    
    let availableModes = ["Default", "Advanced", "Custom"]
    let availableTypes = ["Standard", "Extended", "Basic"]
    
    init() {
        // Initialize session starter
    }
    
    func startSession() {
        isStarting = true
        // TODO: Implement session start logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isStarting = false
            self.isActive = true
            self.currentSessionId = UUID()
        }
    }
    
    func stopSession() {
        isActive = false
        currentSessionId = nil
    }
}

/// View wrapper za SessionStarterElement
struct SessionStarterElementView: View {
    @ObservedObject var sessionStarterElement: SessionStarterElement
    @EnvironmentObject private var localization: LocalizationManager
    
    var body: some View {
        VStack(spacing: 10) {
            // Red 1: Mod selector | DNS toggle switch
            HStack(spacing: 10) {
                // Mod selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mod")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Picker("", selection: $sessionStarterElement.selectedMode) {
                        ForEach(sessionStarterElement.availableModes, id: \.self) { mode in
                            Text(mode).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // DNS toggle switch
                VStack(alignment: .leading, spacing: 4) {
                    Text("DNS")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Toggle("", isOn: $sessionStarterElement.dnsEnabled)
                        .toggleStyle(.switch)
                        .tint(Color(red: 1.0, green: 0.36, blue: 0.0))
                }
                .frame(maxWidth: .infinity)
            }
            
            // Red 2: Type selector | DHCP toggle switch
            HStack(spacing: 10) {
                // Type selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Type")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Picker("", selection: $sessionStarterElement.selectedType) {
                        ForEach(sessionStarterElement.availableTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // DHCP toggle switch
                VStack(alignment: .leading, spacing: 4) {
                    Text("DHCP")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Toggle("", isOn: $sessionStarterElement.dhcpEnabled)
                        .toggleStyle(.switch)
                        .tint(Color(red: 1.0, green: 0.36, blue: 0.0))
                }
                .frame(maxWidth: .infinity)
            }
            
            // Red 3: Sync Play | Async Play
            HStack(spacing: 10) {
                // Sync Play button
                Button(action: {
                    sessionStarterElement.startSession()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.caption)
                        Text("Sync Play")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Async Play button
                Button(action: {
                    sessionStarterElement.startSession()
                }) {
                    HStack {
                        Image(systemName: "play.circle")
                            .font(.caption)
                        Text("Async Play")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(10)
    }
}

