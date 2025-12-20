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
                // Pinovi su na 45px od centra (usklađeno s ConnectionPointDetector)
                // Top point
                Circle()
                    .fill(connectionPointColor)
                    .frame(width: hoveredPoint == .top ? 14 : 7, height: hoveredPoint == .top ? 14 : 7)
                    .offset(y: -45)
                
                // Bottom point
                Circle()
                    .fill(connectionPointColor)
                    .frame(width: hoveredPoint == .bottom ? 14 : 7, height: hoveredPoint == .bottom ? 14 : 7)
                    .offset(y: 45)
                
                // Left point
                Circle()
                    .fill(connectionPointColor)
                    .frame(width: hoveredPoint == .left ? 14 : 7, height: hoveredPoint == .left ? 14 : 7)
                    .offset(x: -45)
                
                // Right point
                Circle()
                    .fill(connectionPointColor)
                    .frame(width: hoveredPoint == .right ? 14 : 7, height: hoveredPoint == .right ? 14 : 7)
                    .offset(x: 45)
                
                // Dodatni krugovi sa strelicama pod 45° za User i Area komponente
                if component.componentType == .user || 
                   component.componentType == .userArea ||
                   component.componentType == .businessArea ||
                   component.componentType == .businessPrivateArea ||
                   component.componentType == .nilterniusArea {
                    // Top-right (gore-desno) - strelica pod 45° gore-desno
                    userButtonWithArrow(
                        angle: 45,
                        offset: CGSize(width: 35, height: -35)
                    )
                    
                    // Bottom-right (dolje-desno) - strelica pod 45° dolje-desno
                    userButtonWithArrow(
                        angle: 135,
                        offset: CGSize(width: 35, height: 35)
                    )
                    
                    // Bottom-left (dolje-lijevo) - strelica pod 45° dolje-lijevo
                    userButtonWithArrow(
                        angle: 225,
                        offset: CGSize(width: -35, height: 35)
                    )
                    
                    // Top-left (gore-lijevo) - strelica pod 45° gore-lijevo
                    userButtonWithArrow(
                        angle: 315,
                        offset: CGSize(width: -35, height: -35)
                    )
                }
            }
        )
        .contentShape(
            // Proširi hit area da uključuje pinove (45px + 25px hit radius = 70px od centra)
            // Koristimo Path da definiramo veći pravokutnik koji uključuje pinove
            Path { path in
                let expandedSize: CGFloat = 200 // 70 + 45*2 + 25*2 (hit radius) + padding
                let rect = CGRect(
                    x: -expandedSize/2,
                    y: -expandedSize/2,
                    width: expandedSize,
                    height: expandedSize
                )
                path.addRoundedRect(in: rect, cornerSize: CGSize(width: 12, height: 12))
            }
        )
    }
    
    // Helper za User i Area komponente - koristi custom boju za ikonu (ima prioritet)
    private var iconColorForUser: Color? {
        if component.componentType == .user ||
           component.componentType == .userArea ||
           component.componentType == .businessArea ||
           component.componentType == .businessPrivateArea ||
           component.componentType == .nilterniusArea {
            // Za User i Area komponente, uvijek koristi custom boju ako je postavljena
            return component.customColor ?? Color(red: 1.0, green: 0.36, blue: 0.0) // Orange default
        }
        return nil
    }
    
    private var borderColor: Color {
        // User i Area elementi koriste custom boju ako je postavljena
        if component.componentType == .user ||
           component.componentType == .userArea ||
           component.componentType == .businessArea ||
           component.componentType == .businessPrivateArea ||
           component.componentType == .nilterniusArea {
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
        // Sve komponente imaju sive pinove
        return Color.gray
    }
    
    // Helper function za User i Area komponente - okrugli botun sa strelicom pod kutom
    @ViewBuilder
    private func userButtonWithArrow(angle: Double, offset: CGSize) -> some View {
        ZStack {
            // Okrugli botun - narančasta boja
            Circle()
                .fill(Color(red: 1.0, green: 0.36, blue: 0.0)) // Narančasta boja
                .frame(width: 16, height: 16)
            
            // Strelica prema vani pod kutom od 45° - bijela boja
            Image(systemName: "arrow.up.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white) // Bijela boja
                .rotationEffect(.degrees(angle - 45)) // Rotiraj strelicu za željeni kut
        }
        .offset(offset)
    }
}

