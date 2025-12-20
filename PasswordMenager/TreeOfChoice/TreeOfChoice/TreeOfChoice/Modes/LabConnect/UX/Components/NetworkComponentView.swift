//
//  NetworkComponentView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct NetworkComponentView: View {
    @ObservedObject var component: NetworkComponent
    var iconColor: Color? = nil // Optional override color based on area
    var pinColor: Color? = nil // Optional override color for connection pins
    var hoveredPoint: ConnectionPoint? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: ComponentIconHelper.icon(for: component.componentType))
                .font(.title3) // Smanjeno sa .title2 na .title3
                .foregroundColor(iconColorForUser ?? iconColor ?? ComponentColorHelper.color(for: component.componentType))
            
            Text(component.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(6)
        .frame(width: 70, height: 70) // Smanjeno sa 90x90 na 70x70
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
        )
        .overlay(
            // Connection points on all 4 sides
            ZStack {
                // Standardni connection points (4 krugova) - za sve komponente uključujući User
                // Top point
                Circle()
                    .fill(connectionPointColor)
                    .frame(width: hoveredPoint == .top ? 14 : 7, height: hoveredPoint == .top ? 14 : 7)
                    .offset(y: -35)
                
                // Bottom point
                Circle()
                    .fill(connectionPointColor)
                    .frame(width: hoveredPoint == .bottom ? 14 : 7, height: hoveredPoint == .bottom ? 14 : 7)
                    .offset(y: 35)
                
                // Left point
                Circle()
                    .fill(connectionPointColor)
                    .frame(width: hoveredPoint == .left ? 14 : 7, height: hoveredPoint == .left ? 14 : 7)
                    .offset(x: -35)
                
                // Right point
                Circle()
                    .fill(connectionPointColor)
                    .frame(width: hoveredPoint == .right ? 14 : 7, height: hoveredPoint == .right ? 14 : 7)
                    .offset(x: 35)
                
                // Dodatni krugovi sa strelicama pod 45° samo za User i Area komponente
                if component.componentType.supportsCustomColor {
                    // Top-right (gore-desno) - strelica pod 45° gore-desno
                    userButtonWithArrow(
                        angle: 45,
                        offset: CGSize(width: 25, height: -25)
                    )
                    
                    // Bottom-right (dolje-desno) - strelica pod 45° dolje-desno
                    userButtonWithArrow(
                        angle: 135,
                        offset: CGSize(width: 25, height: 25)
                    )
                    
                    // Bottom-left (dolje-lijevo) - strelica pod 45° dolje-lijevo
                    userButtonWithArrow(
                        angle: 225,
                        offset: CGSize(width: -25, height: 25)
                    )
                    
                    // Top-left (gore-lijevo) - strelica pod 45° gore-lijevo
                    userButtonWithArrow(
                        angle: 315,
                        offset: CGSize(width: -25, height: -25)
                    )
                }
            }
        )
        .contentShape(Rectangle())
    }
    
    // Helper za User i Area komponente - koristi custom boju za ikonu (ima prioritet)
    private var iconColorForUser: Color? {
        if component.componentType.supportsCustomColor {
            // Za User i Area komponente, uvijek koristi custom boju ako je postavljena
            return component.customColor ?? Color(red: 1.0, green: 0.36, blue: 0.0) // Orange default
        }
        return nil
    }
    
    private var borderColor: Color {
        // User i Area elementi koriste custom boju ako je postavljena
        if component.componentType.supportsCustomColor {
            return component.customColor ?? Color(red: 1.0, green: 0.36, blue: 0.0) // Orange default
        }
        
        if component.isClientA == true {
            return .blue
        } else if component.isClientB == true {
            return .green
        }
        return Color.white.opacity(0.3)
    }
    
    private var connectionPointColor: Color {
        // Use provided pinColor, or determine from component type
        if let pinColor = pinColor {
            return pinColor
        }
        
        // User i Area elementi koriste custom boju ako je postavljena, inače narančasta
        if component.componentType.supportsCustomColor {
            return component.customColor ?? Color(red: 1.0, green: 0.36, blue: 0.0) // Orange default
        }
        
        // Default: gray for regular components, colored for clients
        if component.isClientA == true {
            return Color(red: 0.0, green: 0.2, blue: 1.0) // Blue
        } else if component.isClientB == true {
            return Color(red: 0.0, green: 0.9, blue: 0.1) // Green
        }
        
        return Color.gray
    }
    
    // Helper function za User komponentu - okrugli botun sa strelicom pod kutom
    @ViewBuilder
    private func userButtonWithArrow(angle: Double, offset: CGSize) -> some View {
        ZStack {
            // Okrugli botun
            Circle()
                .fill(connectionPointColor)
                .frame(width: 16, height: 16)
            
            // Strelica prema vani pod kutom od 45°
            Image(systemName: "arrow.up.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(angle - 45)) // Rotiraj strelicu za željeni kut
        }
        .offset(offset)
    }
}

