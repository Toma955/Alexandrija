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
    let onConnectionDragUpdate: ((CGPoint) -> Void)?
    let onPinClick: ((NetworkComponent, ConnectionPoint, CGPoint) -> Void)?
    let onDragUpdate: ((NetworkComponent, CGPoint) -> Void)?
    let onDelete: ((NetworkComponent) -> Void)?
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var dragStartPosition: CGPoint = .zero
    @State private var draggingConnection: Bool = false
    @State private var pinClickStarted: Bool = false // Provjera da se pinClick pozove samo jednom
    
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
            // JEDAN gesture s minimumDistance: 0 da hvata i klik i drag
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let absoluteY = calculateAbsoluteY()
                    let componentCenter = CGPoint(x: absoluteX, y: absoluteY)
                    
                    // KLJUČNO: value.startLocation i value.location su GLOBALNE koordinate (relativne na parent view/canvas)
                    // jer ComponentView koristi .position() modifier
                    let startLocationGlobal = value.startLocation
                    let currentLocationGlobal = value.location
                    
                    // Provjeri je li klik na connection point (koristi ConnectionPointDetector s globalnim koordinatama)
                    if let connectionPoint = ConnectionPointDetector.detect(at: startLocationGlobal, componentCenter: componentCenter) {
                        let pinPosition = ConnectionPointDetector.position(for: connectionPoint, componentCenter: componentCenter)
                        
                        // KLJUČNO: Kada se klikne na pin, pozovi onPinClick (samo jednom)
                        if !pinClickStarted && onPinClick != nil {
                            pinClickStarted = true
                            draggingConnection = true
                            onPinClick?(component, connectionPoint, pinPosition)
                        }
                        
                        // Ažuriraj toPoint kontinuirano dok se vuče (krug prati miš)
                        if draggingConnection {
                            onConnectionDragUpdate?(currentLocationGlobal)
                        }
                    } else {
                        // Normal component drag - track offset
                        if !isDragging {
                            isDragging = true
                            dragStartPosition = CGPoint(x: absoluteX, y: absoluteY)
                        }
                        dragOffset = CGSize(
                            width: value.location.x - value.startLocation.x,
                            height: value.location.y - value.startLocation.y
                        )
                        
                        // Pass current drag location for delete button detection
                        let globalLocation = CGPoint(
                            x: absoluteX + dragOffset.width,
                            y: absoluteY + dragOffset.height
                        )
                        onDragUpdate?(component, globalLocation)
                    }
                }
                .onEnded { value in
                    // Ako je bio connection drag, resetiraj state
                    if draggingConnection {
                        draggingConnection = false
                        pinClickStarted = false
                    }
                    
                    if isDragging {
                        // Check if dropped over delete button
                        let deleteButtonY = geometry.size.height - 60
                        let deleteButtonRadius: CGFloat = 30
                        let deleteButtonCenterX = geometry.size.width / 2
                        
                        let finalDragLocation = CGPoint(
                            x: dragStartPosition.x + dragOffset.width,
                            y: dragStartPosition.y + dragOffset.height
                        )
                        
                        let dx = finalDragLocation.x - deleteButtonCenterX
                        let dy = finalDragLocation.y - deleteButtonY
                        let distance = sqrt(dx * dx + dy * dy)
                        
                        if distance <= deleteButtonRadius {
                            onDelete?(component)
                        } else {
                            // Final position update with grid snap
                            let snappedPosition = GridSnapHelper.snapToGrid(finalDragLocation)
                            onDrag(component, snappedPosition)
                        }
                        
                        // Reset drag state
                        isDragging = false
                        dragOffset = .zero
                    }
                }
        )
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
        // User element koristi custom boju ako je postavljena, inače narančasta
        if component.componentType == .user {
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

