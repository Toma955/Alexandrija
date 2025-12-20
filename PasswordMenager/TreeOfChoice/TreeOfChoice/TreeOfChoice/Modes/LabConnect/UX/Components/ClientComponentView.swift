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
    let onPinClick: ((NetworkComponent, ConnectionPoint, CGPoint) -> Void)?
    let onConnectionDragUpdate: ((CGPoint) -> Void)?
    
    private let types: [NetworkComponent.ComponentType] = [.laptop, .desktop, .tablet, .mobile]
    
    var body: some View {
        let iconColor: Color = component.isClientA == true ?
            Color(red: 0.0, green: 0.2, blue: 1.0) : // Blue
            Color(red: 0.0, green: 0.9, blue: 0.1)  // Green
        
        let currentIndex = types.firstIndex(of: component.componentType) ?? 0
        let nextType = types[(currentIndex + 1) % types.count]
        
        let componentCenter = CGPoint(x: x, y: y)
        
        return NetworkComponentView(component: component, iconColor: iconColor, hoveredPoint: hoveredPoint)
            .frame(width: 90, height: 90)
            .contentShape(Rectangle())
            .position(x: x, y: y)
            .zIndex(10) // Ensure it's on top
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        // Check if starting from connection point
                        // Component frame je 90x90, centar je na 45,45
                        let componentFrameCenter = CGPoint(x: 45, y: 45)
                        let startLocation = CGPoint(
                            x: x + (value.startLocation.x - componentFrameCenter.x),
                            y: y + (value.startLocation.y - componentFrameCenter.y)
                        )
                        
                        // Provjeri je li klik na connection point (koristi ConnectionPointDetector)
                        if let connectionPoint = ConnectionPointDetector.detect(at: startLocation, componentCenter: componentCenter) {
                            // Klik na pin - stvori krug momentalno
                            let pinPosition = ConnectionPointDetector.position(for: connectionPoint, componentCenter: componentCenter)
                            let globalLocation = CGPoint(
                                x: x + (value.location.x - componentFrameCenter.x),
                                y: y + (value.location.y - componentFrameCenter.y)
                            )
                            
                            // Stvori krug momentalno (samo jednom)
                            if onPinClick != nil {
                                onPinClick?(component, connectionPoint, pinPosition)
                            }
                            
                            // Ažuriraj poziciju kruga da prati miš
                            onConnectionDragUpdate?(globalLocation)
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

