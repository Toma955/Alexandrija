//
//  BaseComponentTopologyView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit

/// Base view za prikaz mrežne komponente u topologiji
/// Prikazuje komponentu s ikonom, pinovima za konekcije i podrškom za test mode
struct BaseComponentTopologyView: View {
    @ObservedObject var component: NetworkComponent
    var topology: NetworkTopology? = nil
    var iconColor: Color? = nil
    var pinColor: Color? = nil
    var hoveredPoint: ConnectionPoint? = nil
    var onIconTap: (() -> Void)? = nil
    var isTestMode: Bool = false
    var isEditMode: Bool = false
    var displayable: Any? = nil // Za buduće proširenje
    
    private let componentSize: CGFloat = 70
    private let connectionPointDistance: CGFloat = 45
    private let connectionPointRadius: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Background shape - kvadrat ili krug u test modu
            if isTestMode {
                Circle()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: componentSize, height: componentSize)
                    .overlay(
                        Circle()
                            .stroke(iconColor ?? .gray, lineWidth: 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.8))
                    .frame(width: componentSize, height: componentSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(iconColor ?? .gray, lineWidth: 2)
                    )
            }
            
            // Component icon
            componentIcon
                .onTapGesture {
                    onIconTap?()
                }
            
            // Connection points (pins) - samo ako nije test mode
            if !isTestMode {
                connectionPoints
            }
        }
        .frame(width: componentSize, height: componentSize)
    }
    
    // MARK: - Component Icon
    
    private var componentIcon: some View {
        Group {
            if ComponentIconHelper.hasCustomIcon(for: component.componentType),
               let customIconName = ComponentIconHelper.customIconName(for: component.componentType),
               let customImage = ComponentIconHelper.loadCustomIcon(named: customIconName) {
                // Custom icon
                Image(nsImage: customImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(iconColor ?? .white)
            } else {
                // SF Symbol icon
                Image(systemName: ComponentIconHelper.icon(for: component.componentType))
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(iconColor ?? .white)
            }
        }
    }
    
    // MARK: - Connection Points
    
    private var connectionPoints: some View {
        ZStack {
            // Top pin
            connectionPoint(at: .top)
            
            // Bottom pin
            connectionPoint(at: .bottom)
            
            // Left pin
            connectionPoint(at: .left)
            
            // Right pin
            connectionPoint(at: .right)
        }
    }
    
    private func connectionPoint(at point: ConnectionPoint) -> some View {
        let position = ConnectionPointDetector.position(
            for: point,
            componentCenter: CGPoint(x: componentSize / 2, y: componentSize / 2)
        )
        
        let isHovered = hoveredPoint == point
        let pinColorToUse = pinColor ?? iconColor ?? .gray
        
        return Circle()
            .fill(isHovered ? pinColorToUse : pinColorToUse.opacity(0.6))
            .frame(width: connectionPointRadius * 2, height: connectionPointRadius * 2)
            .overlay(
                Circle()
                    .stroke(isHovered ? Color.white : Color.clear, lineWidth: 2)
            )
            .position(x: position.x, y: position.y)
    }
}

