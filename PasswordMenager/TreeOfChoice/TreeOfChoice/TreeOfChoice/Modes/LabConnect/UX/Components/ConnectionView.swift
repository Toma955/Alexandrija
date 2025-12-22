//
//  ConnectionView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ConnectionView: View {
    let connection: NetworkConnection
    @ObservedObject var topology: NetworkTopology
    let geometry: GeometryProxy
    var isTestMode: Bool = false // Test mode - narančasta boja konekcija
    let onDelete: ((NetworkConnection) -> Void)?
    
    // Provjeri da li je konekcija neispravna (između servera i client komponenti)
    private var isInvalidConnection: Bool {
        ConnectionRuleValidator.isInvalidConnection(connection, in: topology)
    }
    
    var body: some View {
        Group {
            if let from = topology.components.first(where: { $0.id == connection.fromComponentId }),
               let to = topology.components.first(where: { $0.id == connection.toComponentId }) {
                let fromPos = ComponentPositionManager.getAbsolutePosition(for: from, in: geometry)
                let toPos = ComponentPositionManager.getAbsolutePosition(for: to, in: geometry)
                
                // Koristi spremljene pinove ako postoje, inače automatski odaberi najbolji
                let fromPoint = getFromPoint(fromPos: fromPos, toPos: toPos)
                let toPoint = getToPoint(fromPos: fromPos, toPos: toPos)
                
                // Izračunaj točke na rubu kvadrata (35px od centra - polovica od 70x70)
                let fromEdgePoint = getEdgePoint(componentCenter: fromPos, pinPoint: fromPoint, componentSize: 35)
                let toEdgePoint = getEdgePoint(componentCenter: toPos, pinPoint: toPoint, componentSize: 35)
                
                ZStack {
                    // Glavna linija od pina do pina
                    ConnectionLine(
                        from: fromPoint,
                        to: toPoint,
                        type: connection.connectionType,
                        isTestMode: isTestMode,
                        isInvalid: isInvalidConnection,
                        fromPin: connection.fromConnectionPoint,
                        toPin: connection.toConnectionPoint
                    )
                    
                    // Mala linija od ruba kvadrata do pina (from) - uvijek ravna
                    ConnectionLine(
                        from: fromEdgePoint,
                        to: fromPoint,
                        type: connection.connectionType,
                        isTestMode: isTestMode,
                        isInvalid: isInvalidConnection
                    )
                    
                    // Mala linija od pina do ruba kvadrata (to) - uvijek ravna
                    ConnectionLine(
                        from: toPoint,
                        to: toEdgePoint,
                        type: connection.connectionType,
                        isTestMode: isTestMode,
                        isInvalid: isInvalidConnection
                    )
                }
                .zIndex(1)
            }
        }
    }
    
    private func getFromPoint(fromPos: CGPoint, toPos: CGPoint) -> CGPoint {
        if let fromPin = connection.fromConnectionPoint {
            return ConnectionPointDetector.position(for: fromPin, componentCenter: fromPos)
        } else {
            return findBestConnectionPoint(componentCenter: fromPos, targetCenter: toPos)
        }
    }
    
    private func getToPoint(fromPos: CGPoint, toPos: CGPoint) -> CGPoint {
        if let toPin = connection.toConnectionPoint {
            return ConnectionPointDetector.position(for: toPin, componentCenter: toPos)
        } else {
            return findBestConnectionPoint(componentCenter: toPos, targetCenter: fromPos)
        }
    }
    
    // Find the best connection point (top/bottom/left/right) based on direction to target
    private func findBestConnectionPoint(componentCenter: CGPoint, targetCenter: CGPoint) -> CGPoint {
        let dx = targetCenter.x - componentCenter.x
        let dy = targetCenter.y - componentCenter.y
        
        // Determine which side is closest to the target
        let absDx = abs(dx)
        let absDy = abs(dy)
        
        let connectionPoint: ConnectionPoint
        if absDx > absDy {
            // Horizontal direction is stronger
            connectionPoint = dx > 0 ? .right : .left
        } else {
            // Vertical direction is stronger
            connectionPoint = dy > 0 ? .bottom : .top
        }
        
        return ConnectionPointDetector.position(for: connectionPoint, componentCenter: componentCenter)
    }
    
    // Izračunaj točku na rubu kvadrata u smjeru prema pinu
    private func getEdgePoint(componentCenter: CGPoint, pinPoint: CGPoint, componentSize: CGFloat) -> CGPoint {
        let dx = pinPoint.x - componentCenter.x
        let dy = pinPoint.y - componentCenter.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0 else {
            return componentCenter
        }
        
        // Normaliziraj vektor i pomnoži s veličinom komponente (rub kvadrata)
        let normalizedDx = dx / distance
        let normalizedDy = dy / distance
        
        return CGPoint(
            x: componentCenter.x + normalizedDx * componentSize,
            y: componentCenter.y + normalizedDy * componentSize
        )
    }
}

