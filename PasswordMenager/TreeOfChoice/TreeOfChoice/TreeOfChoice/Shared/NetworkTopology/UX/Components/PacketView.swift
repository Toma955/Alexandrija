//
//  PacketView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za animirani paket
struct PacketView: View {
    @ObservedObject var animatedPacket: AnimatedPacket
    let topology: NetworkTopology
    let geometry: GeometryProxy
    
    var body: some View {
        let position = getPacketPosition()
        
        Circle()
            .fill(Color(red: 1.0, green: 0.36, blue: 0.0))
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .position(position)
            .shadow(color: Color(red: 1.0, green: 0.36, blue: 0.0), radius: 4)
    }
    
    private func getPacketPosition() -> CGPoint {
        guard !animatedPacket.path.isEmpty else { return .zero }
        
        let totalSegments = animatedPacket.path.count - 1
        let currentSegment = Int(animatedPacket.progress * Double(totalSegments))
        let segmentProgress = (animatedPacket.progress * Double(totalSegments)) - Double(currentSegment)
        
        guard currentSegment < totalSegments else {
            // Packet at destination
            if let lastId = animatedPacket.path.last,
               let lastComponent = topology.components.first(where: { $0.id == lastId }) {
                return getAbsolutePosition(for: lastComponent, in: geometry)
            }
            return .zero
        }
        
        let fromId = animatedPacket.path[currentSegment]
        let toId = animatedPacket.path[currentSegment + 1]
        
        guard let fromComponent = topology.components.first(where: { $0.id == fromId }),
              let toComponent = topology.components.first(where: { $0.id == toId }) else {
            return .zero
        }
        
        let fromPos = getAbsolutePosition(for: fromComponent, in: geometry)
        let toPos = getAbsolutePosition(for: toComponent, in: geometry)
        
        return CGPoint(
            x: fromPos.x + (toPos.x - fromPos.x) * CGFloat(segmentProgress),
            y: fromPos.y + (toPos.y - fromPos.y) * CGFloat(segmentProgress)
        )
    }
    
    private func getAbsolutePosition(for component: NetworkComponent, in geometry: GeometryProxy) -> CGPoint {
        if component.isClientA == true {
            return CGPoint(x: geometry.size.width * 0.1, y: geometry.size.height * 0.5)
        } else if component.isClientB == true {
            return CGPoint(x: geometry.size.width * 0.9, y: geometry.size.height * 0.5)
        } else {
            return CGPoint(
                x: geometry.size.width * 0.2 + component.position.x,
                y: component.position.y
            )
        }
    }
}




