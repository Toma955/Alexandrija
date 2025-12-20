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
    
    var body: some View {
        Group {
            if let from = topology.components.first(where: { $0.id == connection.fromComponentId }),
               let to = topology.components.first(where: { $0.id == connection.toComponentId }) {
                let fromPos = ComponentPositionManager.getAbsolutePosition(for: from, in: geometry)
                let toPos = ComponentPositionManager.getAbsolutePosition(for: to, in: geometry)
                
                // Find the best connection point on each component based on direction
                let fromPoint = findBestConnectionPoint(componentCenter: fromPos, targetCenter: toPos)
                let toPoint = findBestConnectionPoint(componentCenter: toPos, targetCenter: fromPos)
                
                ConnectionLine(from: fromPoint, to: toPoint, type: connection.connectionType)
                    .zIndex(1)
            }
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
}

