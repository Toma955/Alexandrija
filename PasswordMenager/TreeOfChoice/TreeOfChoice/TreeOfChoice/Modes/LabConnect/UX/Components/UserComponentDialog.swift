//
//  UserComponentDialog.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct UserComponentDialog: View {
    @ObservedObject var component: NetworkComponent
    @Binding var isPresented: Bool
    
    @State private var name: String
    @State private var selectedDeviceType: NetworkComponent.ComponentType
    @State private var selectedColor: Color
    
    // 4 boje za izbor
    private let availableColors: [Color] = [
        Color(red: 1.0, green: 0.36, blue: 0.0), // Narančasta (default)
        Color(red: 0.0, green: 0.2, blue: 1.0),   // Plava
        Color(red: 0.0, green: 0.9, blue: 0.1),  // Zelena
        Color(red: 1.0, green: 0.0, blue: 0.0)  // Crvena
    ]
    
    // Uređaji za izbor
    private let deviceTypes: [NetworkComponent.ComponentType] = [.mobile, .desktop, .tablet, .laptop]
    
    init(component: NetworkComponent, isPresented: Binding<Bool>) {
        self.component = component
        self._isPresented = isPresented
        _name = State(initialValue: component.name)
        _selectedDeviceType = State(initialValue: component.componentType)
        
        // Postavi default boju ako nema custom boje
        if let customColor = component.customColor {
            _selectedColor = State(initialValue: customColor)
        } else {
            _selectedColor = State(initialValue: Color(red: 1.0, green: 0.36, blue: 0.0)) // Narančasta
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Naslov
            Text("User Settings")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            // Naziv
            VStack(alignment: .leading, spacing: 8) {
                Text("Name:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Enter name", text: $name)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
            
            // Izbor uređaja
            VStack(alignment: .leading, spacing: 8) {
                Text("Device Type:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    ForEach(deviceTypes, id: \.self) { deviceType in
                        Button(action: {
                            selectedDeviceType = deviceType
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: ComponentIconHelper.icon(for: deviceType))
                                    .font(.title3)
                                    .foregroundColor(selectedDeviceType == deviceType ? selectedColor : .gray)
                                
                                Text(deviceType.displayName)
                                    .font(.caption)
                                    .foregroundColor(selectedDeviceType == deviceType ? selectedColor : .gray)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedDeviceType == deviceType ? selectedColor.opacity(0.2) : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedDeviceType == deviceType ? selectedColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Izbor boje
            VStack(alignment: .leading, spacing: 8) {
                Text("Color:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    ForEach(Array(availableColors.enumerated()), id: \.offset) { index, color in
                        Button(action: {
                            selectedColor = color
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 3)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Gumbi
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .foregroundColor(.white)
                
                Button("Save") {
                    saveChanges()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedColor)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(selectedColor, lineWidth: 2)
        )
    }
    
    private func saveChanges() {
        // Ažuriraj naziv
        component.name = name
        
        // Ažuriraj tip uređaja
        component.componentType = selectedDeviceType
        
        // Ažuriraj boju
        component.customColor = selectedColor
    }
}

