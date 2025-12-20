//
//  ComponentView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ComponentView: View {
    @ObservedObject var component: NetworkComponent
    @ObservedObject var topology: NetworkTopology
    @ObservedObject var simulation: NetworkSimulation
    let geometry: GeometryProxy
    let hoveredPoint: ConnectionPoint?
    let onTap: (NetworkComponent) -> Void
    let onDrag: (NetworkComponent, CGPoint) -> Void
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var dragStartPosition: CGPoint = .zero
    
    var body: some View {
        let absoluteX = calculateAbsoluteX()
        let iconColor = determineIconColor(absoluteX: absoluteX)
        
        return NetworkComponentView(
            component: component,
            iconColor: iconColor,
            hoveredPoint: hoveredPoint
        )
        .position(
            x: absoluteX + (isDragging ? dragOffset.width : 0),
            y: calculateAbsoluteY() + (isDragging ? dragOffset.height : 0)
        )
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    let componentCenter = CGPoint(x: absoluteX, y: calculateAbsoluteY())
                    
                    // Check if starting from connection point (within 20px radius)
                    let connectionPointRadius: CGFloat = 20
                    let startDx = value.startLocation.x
                    let startDy = value.startLocation.y
                    let distanceFromCenter = sqrt(startDx * startDx + startDy * startDy)
                    
                    // Check if near a connection point (45px from center)
                    if abs(distanceFromCenter - 45) < connectionPointRadius {
                        // Starting connection drag from connection point
                        let globalLocation = CGPoint(
                            x: absoluteX + value.location.x,
                            y: calculateAbsoluteY() + value.location.y
                        )
                        let connectionPointPos = ConnectionPointDetector.closestPoint(from: componentCenter, to: globalLocation)
                        onConnectionDragStart(component, connectionPointPos, globalLocation)
                    } else {
                        // Normal component drag - icon stays fixed to mouse
                        if !isDragging {
                            isDragging = true
                            // Remember starting position when drag begins
                            dragStartPosition = CGPoint(x: absoluteX, y: calculateAbsoluteY())
                        }
                        
                        // Update drag offset - icon follows mouse exactly
                        dragOffset = CGSize(
                            width: value.location.x - value.startLocation.x,
                            height: value.location.y - value.startLocation.y
                        )
                        
                        // DO NOT call onDrag during drag - icon position is only visual via dragOffset
                        // Position will be updated only on drop (onEnded)
                    }
                }
                .onEnded { value in
                    if isDragging {
                        // Calculate final position based on drag start position + offset
                        let finalX = dragStartPosition.x + dragOffset.width
                        let finalY = dragStartPosition.y + dragOffset.height
                        let finalPosition = CGPoint(x: finalX, y: finalY)
                        
                        // Snap to nearest grid point
                        let snappedPosition = GridSnapHelper.snapToGrid(finalPosition)
                        
                        // Update component to snapped position (only now, not during drag)
                        onDrag(component, snappedPosition)
                        
                        // Reset drag state
                        isDragging = false
                        dragOffset = .zero
                        dragStartPosition = .zero
                    }
                }
        )
        .onTapGesture {
            onTap(component)
        }
    }
    
    private func calculateAbsoluteX() -> CGFloat {
        // Calculate absolute X based on zones
        let zoneWidth: CGFloat = 110
        let padding: CGFloat = 10
        let middleAreaStart = padding + zoneWidth
        
        if component.isClientA == true {
            // Client A: centered in zone
            return padding + (zoneWidth / 2)
        } else if component.isClientB == true {
            // Client B: centered in zone
            return (geometry.size.width - padding - zoneWidth) + (zoneWidth / 2)
        } else {
            // Component in middle area - position is relative to middle area start
            if component.position.x < 0 {
                // Component is in Client A zone (negative offset)
                return middleAreaStart + component.position.x
            } else if component.position.x > geometry.size.width - (padding * 2) - (zoneWidth * 2) {
                // Component is in Client B zone
                let offsetFromB = component.position.x - (geometry.size.width - (padding * 2) - (zoneWidth * 2))
                return geometry.size.width - padding - zoneWidth + offsetFromB
            } else {
                // Component is in middle area
                return middleAreaStart + component.position.x
            }
        }
    }
    
    private func calculateAbsoluteY() -> CGFloat {
        // Calculate absolute Y - Client A and B are 2/3 of window height, in bottom half
        if component.isClientA == true || component.isClientB == true {
            let clientHeight = geometry.size.height * (2.0 / 3.0)
            let bottomHalfStart = geometry.size.height * 0.5
            let padding: CGFloat = 20
            return bottomHalfStart + (clientHeight / 2) - padding
        } else {
            return component.position.y
        }
    }
    
    private func determineIconColor(absoluteX: CGFloat) -> Color {
        // User i Area elementi koriste custom boju ako je postavljena, inače narančasta
        if component.componentType.supportsCustomColor {
            return component.customColor ?? Color(red: 1.0, green: 0.36, blue: 0.0) // Orange default
        }
        
        let zoneWidth: CGFloat = 110
        let padding: CGFloat = 10
        let isInClientAArea = absoluteX >= padding && absoluteX <= padding + zoneWidth
        let isInClientBArea = absoluteX >= geometry.size.width - padding - zoneWidth && absoluteX <= geometry.size.width - padding
        
        if isInClientAArea {
            return Color(red: 0.0, green: 0.2, blue: 1.0) // Blue
        } else if isInClientBArea {
            return Color(red: 0.0, green: 0.9, blue: 0.1) // Green
        } else {
            return .gray
        }
    }
    
}

