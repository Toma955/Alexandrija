//
//  ClientTypePickerView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za odabir tipa klijenta
struct ClientTypePickerView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject var component: NetworkComponent
    let onTypeChanged: (NetworkComponent.ComponentType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let clientTypes: [NetworkComponent.ComponentType] = [.laptop, .desktop, .tablet, .mobile]
    
    var body: some View {
        VStack(spacing: 24) {
            Text(localization.text("topology.selectClientType"))
                .font(.title2.bold())
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                ForEach(clientTypes, id: \.self) { type in
                    Button(action: {
                        onTypeChanged(type)
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: iconForType(type))
                                .font(.system(size: 48))
                                .foregroundColor(component.componentType == type ? .white : .blue)
                            
                            Text(type.displayName)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(width: 120, height: 140)
                        .background(component.componentType == type ? Color.blue : Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(component.componentType == type ? Color.blue : Color.clear, lineWidth: 3)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button(action: { dismiss() }) {
                Text(localization.text("topology.cancel"))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(width: 600, height: 300)
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
    }
    
    private func iconForType(_ type: NetworkComponent.ComponentType) -> String {
        switch type {
        case .mobile: return "iphone"
        case .desktop: return "desktopcomputer"
        case .tablet: return "ipad"
        case .laptop: return "laptopcomputer"
        default: return "circle"
        }
    }
}














