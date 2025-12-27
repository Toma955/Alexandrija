//
//  ElementDisplayView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Zajednički view za prikaz elementa u palette-i i na topologiji
/// Koristi ElementDisplayInfo za konzistentan prikaz
struct ElementDisplayView: View {
    let element: BaseTopologyElement
    let displayMode: DisplayMode
    var iconColor: Color? = nil
    var hoveredPoint: ConnectionPoint? = nil
    var onIconTap: (() -> Void)? = nil
    var isTestMode: Bool = false
    
    enum DisplayMode {
        case palette  // Prikaz u palette-i
        case topology // Prikaz na topologiji
    }
    
    private let displayInfo: ElementDisplayInfo
    
    init(
        element: BaseTopologyElement,
        displayMode: DisplayMode,
        iconColor: Color? = nil,
        hoveredPoint: ConnectionPoint? = nil,
        onIconTap: (() -> Void)? = nil,
        isTestMode: Bool = false
    ) {
        self.element = element
        self.displayMode = displayMode
        self.iconColor = iconColor
        self.hoveredPoint = hoveredPoint
        self.onIconTap = onIconTap
        self.isTestMode = isTestMode
        self.displayInfo = element.displayInfo
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Ikona
            iconView
            
            // Naziv
            nameView
            
            // Dodatne informacije (samo na topologiji)
            if displayMode == .topology {
                additionalInfoView
            }
        }
    }
    
    // MARK: - Subviews
    
    private var iconView: some View {
        Group {
            if ComponentIconHelper.hasCustomIcon(for: element.component.componentType),
               let customIconName = ComponentIconHelper.customIconName(for: element.component.componentType),
               let customImage = ComponentIconHelper.loadCustomIcon(named: customIconName) {
                // Custom icon
                Image(nsImage: customImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: displayMode == .palette ? 40 : 32, height: displayMode == .palette ? 40 : 32)
                    .foregroundColor(iconColor ?? .white)
            } else {
                // SF Symbol icon
                Image(systemName: displayInfo.icon)
                    .font(.system(size: displayMode == .palette ? 32 : 24, weight: .medium))
                    .foregroundColor(iconColor ?? .white)
            }
        }
        .onTapGesture {
            onIconTap?()
        }
    }
    
    private var nameView: some View {
        Text(displayInfo.name)
            .font(.caption)
            .foregroundColor(.white)
            .lineLimit(1)
            .frame(maxWidth: displayMode == .palette ? 80 : 70)
    }
    
    @ViewBuilder
    private var additionalInfoView: some View {
        // Status badge
        if !displayInfo.status.isEmpty {
            Text(displayInfo.status)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.5))
                .cornerRadius(4)
        }
        
        // Connection count (ako ima konekcija)
        if displayInfo.connectionCount > 0 {
            HStack(spacing: 2) {
                Image(systemName: "link")
                    .font(.caption2)
                Text("\(displayInfo.connectionCount)")
                    .font(.caption2)
            }
            .foregroundColor(.white.opacity(0.6))
        }
        
        // Area indicator (ako ima area)
        if displayInfo.hasArea {
            Image(systemName: "square.dashed")
                .font(.caption2)
                .foregroundColor(.orange.opacity(0.7))
        }
    }
}

