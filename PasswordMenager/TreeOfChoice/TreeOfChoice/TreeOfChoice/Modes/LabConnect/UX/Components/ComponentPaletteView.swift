//
//  ComponentPaletteView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ComponentPaletteView: View {
    @Binding var draggedComponent: NetworkComponent?
    
    // Sve regularne komponente (bez Area komponenti, DNS i DHCP)
    private var regularComponents: [NetworkComponent.ComponentType] {
        NetworkComponent.ComponentType.allCases.filter { 
            ($0.category == .infrastructure && $0 != .modem) || 
            $0 == .nilterniusServer || 
            $0 == .businessServer ||
            $0 == .user ||
            $0 == .nas ||
            $0 == .cloud ||
            $0 == .isp ||
            $0 == .cellTower ||
            $0 == .satelliteGateway
        }
    }
    
    // Gornji red - 9 regularnih komponenti + DNS Server na kraju (10 ukupno)
    private var topRowComponents: [NetworkComponent.ComponentType] {
        var components = Array(regularComponents.prefix(9))
        // Zamijeni Server (indeks 1 - 2. polje) sa Cell Tower
        if components.count > 1, components[1] == .server {
            components[1] = .cellTower
        }
        // Zamijeni Router (indeks 2 - 3. polje) sa Satellite Gateway
        // Prvo pronađi Router i Satellite Gateway u regularComponents
        let suffixComponents = Array(regularComponents.suffix(from: 9))
        if let routerIndex = components.firstIndex(of: .router),
           let satelliteIndex = suffixComponents.firstIndex(of: .satelliteGateway) {
            // Zamijeni Router sa Satellite Gateway
            components[routerIndex] = .satelliteGateway
        }
        return components + [NetworkComponent.ComponentType.dnsServer]
    }
    
    // Donji red - 4 Area komponente + 5 regularnih + DHCP Server na kraju (10 ukupno)
    private var bottomRowComponents: [NetworkComponent.ComponentType] {
        var suffixComponents = Array(regularComponents.suffix(from: 9))
        var areaComponents: [NetworkComponent.ComponentType] = [.userArea, .businessArea, .businessPrivateArea, .nilterniusArea]
        
        // Zamijeni Cell Tower sa Serverom u suffixComponents
        if let cellTowerIndex = suffixComponents.firstIndex(of: .cellTower) {
            suffixComponents[cellTowerIndex] = NetworkComponent.ComponentType.server
        }
        
        // Zamijeni Satellite Gateway (6. polje = indeks 5 u bottomRowComponents) sa Routerom
        // Satellite Gateway je u suffixComponents, a Router je u topRowComponents
        let topComponents = Array(regularComponents.prefix(9))
        if let satelliteIndex = suffixComponents.firstIndex(of: .satelliteGateway),
           let routerIndex = topComponents.firstIndex(of: .router) {
            // Zamijeni Satellite Gateway sa Routerom
            suffixComponents[satelliteIndex] = NetworkComponent.ComponentType.router
        }
        
        var allBottom = areaComponents + suffixComponents + [.dhcpServer]
        return allBottom
    }
    
    var body: some View {
        VStack(spacing: 20) { // 20px razmak između redova
            topRow
            bottomRow
        }
        .padding(.horizontal, 8)
        .padding(.top, 10) // 10px od vrha
        .padding(.bottom, 10) // 10px od dna
        .frame(maxWidth: .infinity)
        .frame(height: 200) // Fiksna visina: 80 + 20 + 80 + 10 + 10 = 200px
        .background(Color(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0))
        .cornerRadius(16)
        .padding(.horizontal, 4) // Smanji kvadrat sa lijeve i desne strane (NAKON background-a da ne utječe na visinu)
    }
    
    @ViewBuilder
    private var topRow: some View {
        HStack(spacing: 6) {
            ForEach(topRowComponents, id: \.self) { componentType in
                paletteItem(for: componentType, isServer: componentType == .dnsServer)
            }
        }
    }
    
    @ViewBuilder
    private var bottomRow: some View {
        HStack(spacing: 6) {
            ForEach(bottomRowComponents, id: \.self) { componentType in
                paletteItem(for: componentType, isServer: componentType == .dhcpServer)
            }
        }
    }
    
    @ViewBuilder
    private func paletteItem(for componentType: NetworkComponent.ComponentType, isServer: Bool) -> some View {
        if isServer {
            ComponentPaletteItem(componentType: componentType)
                .frame(width: 110, height: 80) // Vraćeno na originalnu visinu
                .onDrag {
                    draggedComponent = NetworkComponent(
                        componentType: componentType,
                        position: .zero,
                        name: componentType.displayName
                    )
                    return NSItemProvider(object: componentType.rawValue as NSString)
                }
        } else {
            ComponentPaletteItem(componentType: componentType)
                .frame(height: 80) // Vraćeno na originalnu visinu
                .frame(maxWidth: .infinity)
                .onDrag {
                    draggedComponent = NetworkComponent(
                        componentType: componentType,
                        position: .zero,
                        name: componentType.displayName
                    )
                    return NSItemProvider(object: componentType.rawValue as NSString)
                }
        }
    }
}

