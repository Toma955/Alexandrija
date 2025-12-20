//
//  ComponentPaletteView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ComponentPaletteView: View {
    @Binding var draggedComponent: NetworkComponent?
    
    // Sve komponente koje trebaju biti u paleti
    private var allComponents: [NetworkComponent.ComponentType] {
        NetworkComponent.ComponentType.allCases.filter { 
            ($0.category == .infrastructure && $0 != .modem) || 
            $0 == .nilterniusServer || 
            $0 == .businessServer ||
            $0 == .user ||
            $0 == .nas ||
            $0 == .cloud ||
            $0 == .dnsServer ||
            $0 == .dhcpServer ||
            $0 == .isp ||
            $0 == .cellTower ||
            $0 == .satelliteGateway ||
            $0 == .userArea ||
            $0 == .businessArea ||
            $0 == .businessPrivateArea ||
            $0 == .nilterniusArea
        }
    }
    
    // Gornji red - prva polovica komponenti (10 komponenti)
    private var topRowComponents: [NetworkComponent.ComponentType] {
        let components = allComponents
        let midPoint = components.count / 2
        return Array(components.prefix(midPoint))
    }
    
    // Donji red - druga polovica komponenti (10 komponenti, uključujući Area komponente)
    private var bottomRowComponents: [NetworkComponent.ComponentType] {
        let components = allComponents
        let midPoint = components.count / 2
        return Array(components.suffix(from: midPoint))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 8) {
                    // Gornji red - ravnomjerno raspoređene ikone
                    HStack(spacing: 8) {
                        ForEach(topRowComponents, id: \.self) { componentType in
                            ComponentPaletteItem(componentType: componentType)
                                .frame(width: calculateItemWidth(
                                    containerWidth: geometry.size.width,
                                    itemCount: topRowComponents.count,
                                    spacing: 8,
                                    padding: 32
                                ))
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
                    
                    // Donji red - Area komponente, ravnomjerno raspoređene
                    HStack(spacing: 8) {
                        ForEach(bottomRowComponents, id: \.self) { componentType in
                            ComponentPaletteItem(componentType: componentType)
                                .frame(width: calculateItemWidth(
                                    containerWidth: geometry.size.width,
                                    itemCount: bottomRowComponents.count,
                                    spacing: 8,
                                    padding: 32
                                ))
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
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .offset(y: -30)
                .frame(minWidth: geometry.size.width)
            }
        }
        .background(Color.black.opacity(0.4))
    }
    
    private func calculateItemWidth(containerWidth: CGFloat, itemCount: Int, spacing: CGFloat, padding: CGFloat) -> CGFloat {
        let availableWidth = containerWidth - padding
        let totalSpacing = CGFloat(itemCount - 1) * spacing
        let itemWidth = (availableWidth - totalSpacing) / CGFloat(itemCount)
        return max(80, itemWidth) // Minimum 80 points
    }
}

