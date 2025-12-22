//
//  NetworkComponentView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit
import Combine

// Helper za AnyShape - omogućava korištenje različitih Shape tipova
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = shape.path(in:)
    }
    
    func path(in rect: CGRect) -> Path {
        return _path(rect)
    }
}

struct NetworkComponentView: View {
    @ObservedObject var component: NetworkComponent
    var topology: NetworkTopology? = nil // Optional - potrebno za provjeru konekcija
    var iconColor: Color? = nil // Optional override color based on area
    var pinColor: Color? = nil // Optional override color for connection pins
    var hoveredPoint: ConnectionPoint? = nil
    var onIconTap: (() -> Void)? = nil // Callback za klik na ikonu
    var isTestMode: Bool = false // Test mode - prikazuje krug umjesto kvadrata
    
    @State private var isIconPressed = false
    
    // Provjeri ima li komponenta konekcije
    // Ako topology nije proslijeđen, pretpostavi da nema konekcija (siva boja)
    private var hasConnections: Bool {
        guard let topology = topology else { return false } // Ako nema topology, nema konekcija
        let connections = topology.getConnections(for: component.id)
        return !connections.isEmpty
    }
    
    private var isAreaComponent: Bool {
        component.componentType == .userArea ||
        component.componentType == .businessArea ||
        component.componentType == .businessPrivateArea ||
        component.componentType == .nilterniusArea
    }
    
    var body: some View {
        // Izračunaj broj konekcija za ovu komponentu
        let componentConnections = topology?.getConnections(for: component.id) ?? []
        let connectionCount = componentConnections.count
        
        return VStack(spacing: 4) {
            // Koristi custom ikonu ako postoji, inače SF Symbol
            iconView
            
            // Natpis samo za komponente koje NISU Area (Area komponente imaju natpis ispod donje strelice)
            if !isAreaComponent {
                Text(component.name)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
        .padding(6)
        .frame(width: 70, height: 70) // Smanjeno sa 90x90 na 70x70
        .background(Color.black.opacity(0.6))
        .clipShape(componentShape)
        .overlay(borderOverlay)
        .overlay(connectionPointOverlay)
        .contentShape(expandedContentShape)
        .id("\(component.id.uuidString)-\(connectionCount)") // Ažuriraj view kada se konekcije promijene za ovu komponentu
    }
    
    private var componentShape: AnyShape {
        if isTestMode {
            return AnyShape(Circle())
        } else {
            return AnyShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        if isTestMode {
            Circle()
                .stroke(Color(red: 1.0, green: 0.36, blue: 0.0), lineWidth: 2)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .stroke(computedBorderColor, lineWidth: 2)
        }
    }
    
    @ViewBuilder
    private var connectionPointOverlay: some View {
        // Connection point - prikazuje se samo najbliži pin kada je miš blizu
        // Sakrij pinove u test modu
        if !isTestMode, let point = hoveredPoint {
            Circle()
                .fill(connectionPointColor)
                .frame(width: 14, height: 14)
                .offset(
                    x: point == .left ? -45 : (point == .right ? 45 : 0),
                    y: point == .top ? -45 : (point == .bottom ? 45 : 0)
                )
        }
    }
    
    private var expandedContentShape: Path {
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
    }
    
    @ViewBuilder
    private var iconView: some View {
        Group {
            if let customIconName = ComponentIconHelper.customIconName(for: component.componentType),
               let nsImage = ComponentIconHelper.loadCustomIcon(named: customIconName) {
                // Koristi NSImage za učitavanje iz foldera
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(computedIconColor) // Primijeni boju i na custom ikone
            } else {
                Image(systemName: ComponentIconHelper.icon(for: component.componentType))
                    .font(.title3)
                    .foregroundColor(computedIconColor)
            }
        }
        .scaleEffect(isIconPressed ? 0.9 : 1.0)
        .opacity(isIconPressed ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isIconPressed)
        .contentShape(Rectangle())
        .simultaneousGesture(
            // Tap gesture - klik na ikonu
            TapGesture()
                .onEnded { _ in
                    onIconTap?()
                }
        )
        .simultaneousGesture(
            // Press gesture za visual feedback
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isIconPressed {
                        isIconPressed = true
                    }
                }
                .onEnded { _ in
                    isIconPressed = false
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
    
    // Izračunaj boju ikone - siva ako nije spojena, narančasta u test modu, inače normalna
    private var computedIconColor: Color {
        // Ako je test mode, koristi narančastu boju
        if isTestMode {
            return Color(red: 1.0, green: 0.36, blue: 0.0)
        }
        
        // Ako nema konekcija, koristi sivu boju (bez obzira na tip komponente ili iconColor parametar)
        if !hasConnections {
            return Color.gray
        }
        
        // Inače koristi normalnu boju (ali samo ako ima konekcije)
        // iconColor parametar se ignorira ako nema konekcija - sve mora biti sivo
        // Za User i Area komponente, koristi custom boju ako je postavljena
        if component.componentType == .user ||
           component.componentType == .userArea ||
           component.componentType == .businessArea ||
           component.componentType == .businessPrivateArea ||
           component.componentType == .nilterniusArea {
            return component.customColor ?? Color(red: 1.0, green: 0.36, blue: 0.0) // Orange default
        }
        // Za sve ostale komponente, koristi default boju iz ComponentColorHelper
        return ComponentColorHelper.color(for: component.componentType)
    }
    
    // Izračunaj boju okvira - siva ako nije spojena, narančasta u test modu, inače normalna
    private var computedBorderColor: Color {
        // Ako je test mode, koristi narančastu boju
        if isTestMode {
            return Color(red: 1.0, green: 0.36, blue: 0.0)
        }
        
        // Ako nema konekcija, koristi sivu boju (bez obzira na tip komponente)
        if !hasConnections {
            return Color.gray
        }
        
        // Inače koristi normalnu boju (ali samo ako ima konekcije)
        // Za User i Area komponente, koristi custom boju ako je postavljena
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

