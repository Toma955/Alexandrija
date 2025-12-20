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
    @State private var isResizingArea: Bool = false
    @State private var resizeStartSize: CGSize = .zero
    @State private var resizeStartCenter: CGPoint = .zero
    @State private var resizeCorner: AreaResizeCorner? = nil
    @State private var resizeEdge: AreaResizeEdge? = nil
    @State private var draggingHandlePosition: CGPoint? = nil // Pozicija strelice koja se vuče (prati miš)
    
    enum AreaResizeCorner {
        case topRight, bottomRight, bottomLeft, topLeft
    }
    
    enum AreaResizeEdge {
        case top, right, bottom, left
    }
    
    var body: some View {
        let absoluteX = calculateAbsoluteX()
        let absoluteY = calculateAbsoluteY()
        let iconColor = determineIconColor(absoluteX: absoluteX)
        let isAreaComponent = component.componentType == .userArea ||
                             component.componentType == .businessArea ||
                             component.componentType == .businessPrivateArea ||
                             component.componentType == .nilterniusArea
        
        return ZStack {
            // Isprekidani narančasti kvadrat za area komponente
            if isAreaComponent {
                let areaWidth = component.areaWidth ?? 120
                let areaHeight = component.areaHeight ?? 120
                let areaColor = component.customColor ?? Color(red: 1.0, green: 0.36, blue: 0.0)
                
                let areaCenter = calculateAreaCenter(
                    absoluteX: absoluteX,
                    absoluteY: absoluteY,
                    areaWidth: areaWidth,
                    areaHeight: areaHeight
                )
                
                ZStack {
                    // Isprekidani kvadrat
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(areaColor, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .frame(width: areaWidth, height: areaHeight)
                    
                    // Strelice na kutovima
                    if isResizingArea, let corner = resizeCorner, let dragPos = draggingHandlePosition {
                        // Prikaži strelicu koja se vuče na poziciji miša
                        areaResizeHandleAtPosition(corner: corner, position: dragPos, areaColor: areaColor, areaCenter: areaCenter)
                        // Prikaži ostale strelice na normalnim pozicijama
                        if corner != .topRight {
                            areaResizeHandle(corner: .topRight, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if corner != .bottomRight {
                            areaResizeHandle(corner: .bottomRight, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if corner != .bottomLeft {
                            areaResizeHandle(corner: .bottomLeft, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if corner != .topLeft {
                            areaResizeHandle(corner: .topLeft, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                    } else {
                        // Prikaži sve strelice na normalnim pozicijama
                        areaResizeHandle(corner: .topRight, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        areaResizeHandle(corner: .bottomRight, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        areaResizeHandle(corner: .bottomLeft, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        areaResizeHandle(corner: .topLeft, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                    }
                    
                    // Strelice na sredinama stranica
                    if isResizingArea, let edge = resizeEdge, let dragPos = draggingHandlePosition {
                        // Prikaži strelicu koja se vuče na poziciji miša
                        areaEdgeResizeHandleAtPosition(edge: edge, position: dragPos, areaColor: areaColor, areaCenter: areaCenter)
                        // Prikaži ostale strelice na normalnim pozicijama
                        if edge != .top {
                            areaEdgeResizeHandle(edge: .top, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if edge != .right {
                            areaEdgeResizeHandle(edge: .right, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if edge != .bottom {
                            areaEdgeResizeHandle(edge: .bottom, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if edge != .left {
                            areaEdgeResizeHandle(edge: .left, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                    } else {
                        // Prikaži sve strelice na normalnim pozicijama
                        areaEdgeResizeHandle(edge: .top, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        areaEdgeResizeHandle(edge: .right, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        areaEdgeResizeHandle(edge: .bottom, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        areaEdgeResizeHandle(edge: .left, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                    }
                    
                    // Natpis ispod donje strelice
                    Text(component.name)
                        .font(.caption)
                        .foregroundColor(areaColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .offset(y: areaHeight / 2 + 25)
                }
                .position(x: areaCenter.x, y: areaCenter.y)
                .allowsHitTesting(true)
            }
            
            // Komponenta
            NetworkComponentView(
            component: component,
            iconColor: iconColor,
            hoveredPoint: hoveredPoint
        )
        .position(
                x: absoluteX + (isDragging && !isResizingArea ? dragOffset.width : 0),
                y: absoluteY + (isDragging && !isResizingArea ? dragOffset.height : 0)
        )
        }
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
                    
                    // Provjeri je li klik na strelicu za resize (corner) - ima prioritet nad edge
                    if isAreaComponent, let corner = detectAreaResizeCorner(at: startLocationGlobal, componentCenter: componentCenter, areaWidth: component.areaWidth ?? 120, areaHeight: component.areaHeight ?? 120) {
                        if !isResizingArea || resizeCorner != corner {
                            isResizingArea = true
                            resizeCorner = corner
                            resizeEdge = nil
                            resizeStartSize = CGSize(width: component.areaWidth ?? 120, height: component.areaHeight ?? 120)
                            resizeStartCenter = componentCenter
                            draggingHandlePosition = currentLocationGlobal // Strelice prate miš
                        }
                        
                        // Ažuriraj poziciju strelice da prati miš
                        draggingHandlePosition = currentLocationGlobal
                        
                        let dragDelta = CGSize(width: currentLocationGlobal.x - startLocationGlobal.x, height: currentLocationGlobal.y - startLocationGlobal.y)
                        var newWidth = resizeStartSize.width
                        var newHeight = resizeStartSize.height
                        let minSize: CGFloat = 100
                        
                        switch corner {
                        case .topRight:
                            // Top i right se pomiču, bottom-left kut ostaje na istom mjestu
                            newWidth = max(minSize, resizeStartSize.width + dragDelta.width)
                            newHeight = max(minSize, resizeStartSize.height - dragDelta.height)
                        case .bottomRight:
                            // Bottom i right se pomiču, top-left kut ostaje na istom mjestu
                            newWidth = max(minSize, resizeStartSize.width + dragDelta.width)
                            newHeight = max(minSize, resizeStartSize.height + dragDelta.height)
                        case .bottomLeft:
                            // Bottom i left se pomiču, top-right kut ostaje na istom mjestu
                            newWidth = max(minSize, resizeStartSize.width - dragDelta.width)
                            newHeight = max(minSize, resizeStartSize.height + dragDelta.height)
                        case .topLeft:
                            // Top i left se pomiču, bottom-right kut ostaje na istom mjestu
                            newWidth = max(minSize, resizeStartSize.width - dragDelta.width)
                            newHeight = max(minSize, resizeStartSize.height - dragDelta.height)
                        }
                        
                        component.areaWidth = newWidth
                        component.areaHeight = newHeight
                    }
                    // Provjeri je li klik na strelicu za resize (edge) - samo ako nije corner resize aktivan
                    else if isAreaComponent, !isResizingArea || resizeCorner == nil, let edge = detectAreaResizeEdge(at: startLocationGlobal, componentCenter: componentCenter, areaWidth: component.areaWidth ?? 120, areaHeight: component.areaHeight ?? 120) {
                        if !isResizingArea || resizeEdge != edge {
                            isResizingArea = true
                            resizeEdge = edge
                            resizeCorner = nil
                            resizeStartSize = CGSize(width: component.areaWidth ?? 120, height: component.areaHeight ?? 120)
                            resizeStartCenter = componentCenter
                            draggingHandlePosition = currentLocationGlobal // Strelice prate miš
                        }
                        
                        // Ažuriraj poziciju strelice da prati miš
                        draggingHandlePosition = currentLocationGlobal
                        
                        let dragDelta = CGSize(width: currentLocationGlobal.x - startLocationGlobal.x, height: currentLocationGlobal.y - startLocationGlobal.y)
                        var newWidth = resizeStartSize.width
                        var newHeight = resizeStartSize.height
                        let minSize: CGFloat = 100
                        
                        switch edge {
                        case .top:
                            // Top se pomiče, bottom ostaje na istom mjestu
                            newHeight = max(minSize, resizeStartSize.height - dragDelta.height)
                        case .right:
                            // Right se pomiče, left ostaje na istom mjestu
                            newWidth = max(minSize, resizeStartSize.width + dragDelta.width)
                        case .bottom:
                            // Bottom se pomiče, top ostaje na istom mjestu
                            newHeight = max(minSize, resizeStartSize.height + dragDelta.height)
                        case .left:
                            // Left se pomiče, right ostaje na istom mjestu
                            newWidth = max(minSize, resizeStartSize.width - dragDelta.width)
                        }
                        
                        component.areaWidth = newWidth
                        component.areaHeight = newHeight
                    }
                    // Provjeri je li klik na connection point (koristi ConnectionPointDetector s globalnim koordinatama)
                    else if let connectionPoint = ConnectionPointDetector.detect(at: startLocationGlobal, componentCenter: componentCenter) {
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
                        // Provjeri je li klik na komponentu (crno područje), ne na kvadrat ili strelice
                        let componentSize: CGFloat = 70
                        let componentRect = CGRect(
                            x: componentCenter.x - componentSize / 2,
                            y: componentCenter.y - componentSize / 2,
                            width: componentSize,
                            height: componentSize
                        )
                        
                        if componentRect.contains(startLocationGlobal) {
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
                }
                .onEnded { value in
                    // Ako je bio area resize, resetiraj state
                    if isResizingArea {
                        isResizingArea = false
                        resizeCorner = nil
                        resizeEdge = nil
                        draggingHandlePosition = nil
                    }
                    
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
                            // Final position update - bez grid snap za Area komponente (smooth drag)
                            if isAreaComponent {
                                onDrag(component, finalDragLocation)
                            } else {
                                // Grid snap samo za regularne komponente
                                let snappedPosition = GridSnapHelper.snapToGrid(finalDragLocation)
                                onDrag(component, snappedPosition)
                            }
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
    
    private func calculateAreaCenter(absoluteX: CGFloat, absoluteY: CGFloat, areaWidth: CGFloat, areaHeight: CGFloat) -> CGPoint {
        // Jednostavno koristi poziciju komponente - bez centriranja
        let areaCenterX = absoluteX + (isDragging && !isResizingArea ? dragOffset.width : 0)
        let areaCenterY = absoluteY + (isDragging && !isResizingArea ? dragOffset.height : 0)
        
        return CGPoint(x: areaCenterX, y: areaCenterY)
    }
    
    @ViewBuilder
    private func areaResizeHandle(corner: AreaResizeCorner, areaWidth: CGFloat, areaHeight: CGFloat, areaColor: Color, areaCenter: CGPoint) -> some View {
        let offset = offsetForCorner(corner, areaWidth: areaWidth, areaHeight: areaHeight)
        ZStack {
            Circle()
                .fill(areaColor)
                .frame(width: 16, height: 16)
            
            Image(systemName: "arrow.up.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(cornerAngle(for: corner) - 45))
        }
        .offset(x: offset.width, y: offset.height)
        .allowsHitTesting(true)
    }
    
    @ViewBuilder
    private func areaResizeHandleAtPosition(corner: AreaResizeCorner, position: CGPoint, areaColor: Color, areaCenter: CGPoint) -> some View {
        // Izračunaj offset od areaCenter do position
        let offset = CGSize(width: position.x - areaCenter.x, height: position.y - areaCenter.y)
        ZStack {
            Circle()
                .fill(areaColor)
                .frame(width: 16, height: 16)
            
            Image(systemName: "arrow.up.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(cornerAngle(for: corner) - 45))
        }
        .offset(x: offset.width, y: offset.height)
    }
    
    private func offsetForCorner(_ corner: AreaResizeCorner, areaWidth: CGFloat, areaHeight: CGFloat) -> CGSize {
        let handleOffset: CGFloat = 8 // Offset za strelicu izvan kvadrata
        switch corner {
        case .topRight:
            return CGSize(width: areaWidth / 2 + handleOffset, height: -areaHeight / 2 - handleOffset)
        case .bottomRight:
            return CGSize(width: areaWidth / 2 + handleOffset, height: areaHeight / 2 + handleOffset)
        case .bottomLeft:
            return CGSize(width: -areaWidth / 2 - handleOffset, height: areaHeight / 2 + handleOffset)
        case .topLeft:
            return CGSize(width: -areaWidth / 2 - handleOffset, height: -areaHeight / 2 - handleOffset)
        }
    }
    
    private func cornerAngle(for corner: AreaResizeCorner) -> Double {
        switch corner {
        case .topRight: return 45
        case .bottomRight: return 135
        case .bottomLeft: return 225
        case .topLeft: return 315
        }
    }
    
    @ViewBuilder
    private func areaEdgeResizeHandle(edge: AreaResizeEdge, areaWidth: CGFloat, areaHeight: CGFloat, areaColor: Color, areaCenter: CGPoint) -> some View {
        let offset = offsetForEdge(edge, areaWidth: areaWidth, areaHeight: areaHeight)
        ZStack {
            Circle()
                .fill(areaColor)
                .frame(width: 16, height: 16)
            
            Image(systemName: "arrow.up")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(edgeAngle(for: edge)))
        }
        .offset(x: offset.width, y: offset.height)
        .allowsHitTesting(true)
    }
    
    @ViewBuilder
    private func areaEdgeResizeHandleAtPosition(edge: AreaResizeEdge, position: CGPoint, areaColor: Color, areaCenter: CGPoint) -> some View {
        // Izračunaj offset od areaCenter do position
        let offset = CGSize(width: position.x - areaCenter.x, height: position.y - areaCenter.y)
        ZStack {
            Circle()
                .fill(areaColor)
                .frame(width: 16, height: 16)
            
            Image(systemName: "arrow.up")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(edgeAngle(for: edge)))
        }
        .offset(x: offset.width, y: offset.height)
    }
    
    private func offsetForEdge(_ edge: AreaResizeEdge, areaWidth: CGFloat, areaHeight: CGFloat) -> CGSize {
        let handleOffset: CGFloat = 8 // Offset za strelicu izvan kvadrata
        switch edge {
        case .top:
            return CGSize(width: 0, height: -areaHeight / 2 - handleOffset)
        case .right:
            return CGSize(width: areaWidth / 2 + handleOffset, height: 0)
        case .bottom:
            return CGSize(width: 0, height: areaHeight / 2 + handleOffset)
        case .left:
            return CGSize(width: -areaWidth / 2 - handleOffset, height: 0)
        }
    }
    
    private func edgeAngle(for edge: AreaResizeEdge) -> Double {
        switch edge {
        case .top: return 0
        case .right: return 90
        case .bottom: return 180
        case .left: return 270
        }
    }
    
    private func detectAreaResizeEdge(at location: CGPoint, componentCenter: CGPoint, areaWidth: CGFloat, areaHeight: CGFloat) -> AreaResizeEdge? {
        let handleRadius: CGFloat = 12
        let handleOffset: CGFloat = 8 // Offset za strelicu izvan kvadrata
        let edges: [(CGSize, AreaResizeEdge)] = [
            (CGSize(width: 0, height: -areaHeight / 2 - handleOffset), .top),
            (CGSize(width: areaWidth / 2 + handleOffset, height: 0), .right),
            (CGSize(width: 0, height: areaHeight / 2 + handleOffset), .bottom),
            (CGSize(width: -areaWidth / 2 - handleOffset, height: 0), .left)
        ]
        
        for (offset, edge) in edges {
            let handlePosition = CGPoint(x: componentCenter.x + offset.width, y: componentCenter.y + offset.height)
            let dx = location.x - handlePosition.x
            let dy = location.y - handlePosition.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance <= handleRadius {
                return edge
            }
        }
        
        return nil
    }
    
    private func detectAreaResizeCorner(at location: CGPoint, componentCenter: CGPoint, areaWidth: CGFloat, areaHeight: CGFloat) -> AreaResizeCorner? {
        let handleRadius: CGFloat = 12
        let handleOffset: CGFloat = 8 // Offset za strelicu izvan kvadrata
        let corners: [(CGSize, AreaResizeCorner)] = [
            (CGSize(width: areaWidth / 2 + handleOffset, height: -areaHeight / 2 - handleOffset), .topRight),
            (CGSize(width: areaWidth / 2 + handleOffset, height: areaHeight / 2 + handleOffset), .bottomRight),
            (CGSize(width: -areaWidth / 2 - handleOffset, height: areaHeight / 2 + handleOffset), .bottomLeft),
            (CGSize(width: -areaWidth / 2 - handleOffset, height: -areaHeight / 2 - handleOffset), .topLeft)
        ]
        
        for (offset, corner) in corners {
            let handlePosition = CGPoint(x: componentCenter.x + offset.width, y: componentCenter.y + offset.height)
            let dx = location.x - handlePosition.x
            let dy = location.y - handlePosition.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance <= handleRadius {
                return corner
            }
        }
        
        return nil
    }
}

