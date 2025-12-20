//
//  ClientComponentView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ClientComponentView: View {
    @ObservedObject var component: NetworkComponent
    @ObservedObject var topology: NetworkTopology
    @ObservedObject var simulation: NetworkSimulation
    let geometry: GeometryProxy
    let x: CGFloat
    let y: CGFloat
    let connectingFrom: NetworkComponent?
    let hoveredPoint: ConnectionPoint?
    let onTypeChange: (NetworkComponent, NetworkComponent.ComponentType) -> Void
    let onTap: (NetworkComponent) -> Void
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    
    private let types: [NetworkComponent.ComponentType] = [.laptop, .desktop, .tablet, .mobile]
    
    var body: some View {
        let iconColor: Color = component.isClientA == true ?
            Color(red: 0.0, green: 0.2, blue: 1.0) : // Blue
            Color(red: 0.0, green: 0.9, blue: 0.1)  // Green
        
        let pinColor: Color = component.isClientA == true ?
            Color(red: 0.0, green: 0.2, blue: 1.0) : // Blue
            Color(red: 0.0, green: 0.9, blue: 0.1)  // Green
        
        let currentIndex = types.firstIndex(of: component.componentType) ?? 0
        let nextType = types[(currentIndex + 1) % types.count]
        
        let componentCenter = CGPoint(x: x, y: y)
        
        return NetworkComponentView(component: component, iconColor: iconColor, pinColor: pinColor, hoveredPoint: hoveredPoint)
            .frame(width: 90, height: 90)
            .contentShape(Rectangle())
            .position(x: x, y: y)
            .zIndex(10) // Ensure it's on top
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        // Check if starting from connection point (within 20px radius)
                        let connectionPointRadius: CGFloat = 20
                        // Calculate distance from center of component (45px is connection point distance)
                        let startDx = value.startLocation.x - 45 // Offset from component center
                        let startDy = value.startLocation.y - 45
                        let distanceFromCenter = sqrt(startDx * startDx + startDy * startDy)
                        
                        // Check if near a connection point (45px from center)
                        if abs(distanceFromCenter - 45) < connectionPointRadius || distanceFromCenter < connectionPointRadius {
                            // Starting connection drag from connection point
                            // Convert local coordinates to global
                            let globalStart = CGPoint(
                                x: x + value.startLocation.x - 45,
                                y: y + value.startLocation.y - 45
                            )
                            let globalCurrent = CGPoint(
                                x: x + value.location.x - 45,
                                y: y + value.location.y - 45
                            )
                            let connectionPointPos = ConnectionPointDetector.closestPoint(from: componentCenter, to: globalStart)
                            onConnectionDragStart(component, connectionPointPos, globalCurrent)
                        }
                    }
            )
            .simultaneousGesture(
                // Tap gesture for type change or connection
                TapGesture()
                    .onEnded { _ in
                        if connectingFrom == nil {
                            onTypeChange(component, nextType)
                        } else {
                            onTap(component)
                        }
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        guard !simulation.isRunning else { return }
                        // Connection mode handled by parent
                    }
            )
    }
}

