//
//  ClientZone.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Enum za tip klijenta zone (stari enum - preimenovan da izbjegne konflikt s novim ClientType)
enum ClientZoneType {
    case clientA
    case clientB
    
    var name: String {
        switch self {
        case .clientA: return "Client A"
        case .clientB: return "Client B"
        }
    }
    
    var color: Color {
        switch self {
        case .clientA: return Color(red: 0.0, green: 0.2, blue: 1.0) // Blue
        case .clientB: return Color(red: 0.0, green: 0.9, blue: 0.1) // Green
        }
    }
}

/// Element koji predstavlja Client Zone - područje klijenta s elementom za izbor uređaja, tekstom, bojom i nazivom
/// Nasljeđuje AreaTopologyElement - automatski dobiva pinove i area područje
/// Slijedi objektno orijentirane principe
/// Koordinate se određuju prema grid koordinatama (x, y indeksi), ne prema pikselima
class ClientZone: AreaTopologyElement {
    // MARK: - Client Zone Specific Properties
    
    @Published var zoneType: ClientZoneType
    @Published var width: CGFloat
    @Published var isVisible: Bool
    
    // Grid koordinate za 4 kuta zone (x, y indeksi na gridu, ne pikseli)
    @Published var topLeftGrid: CGPoint // Grid koordinata gornjeg lijevog kuta
    @Published var topRightGrid: CGPoint // Grid koordinata gornjeg desnog kuta
    @Published var bottomLeftGrid: CGPoint // Grid koordinata donjeg lijevog kuta
    @Published var bottomRightGrid: CGPoint // Grid koordinata donjeg desnog kuta
    
    // MARK: - Computed Properties
    
    var name: String {
        zoneType.name
    }
    
    var color: Color {
        zoneType.color
    }
    
    var backgroundColor: Color {
        color.opacity(0.1)
    }
    
    var borderColor: Color {
        color
    }
    
    // MARK: - Initialization
    
    init(component: NetworkComponent? = nil, zoneType: ClientZoneType, width: CGFloat = 90, 
         topLeftGrid: CGPoint? = nil, topRightGrid: CGPoint? = nil, 
         bottomLeftGrid: CGPoint? = nil, bottomRightGrid: CGPoint? = nil) {
        self.zoneType = zoneType
        self.width = width
        self.isVisible = true
        
        // Prvo inicijaliziraj sve stored properties
        let defaultTopLeft: CGPoint
        if let topLeft = topLeftGrid {
            defaultTopLeft = topLeft
        } else {
            // Default pozicija ovisno o tipu zone
            defaultTopLeft = zoneType == .clientA ? CGPoint(x: 0, y: 2) : CGPoint(x: 0, y: 2)
        }
        self.topLeftGrid = defaultTopLeft
        
        let defaultTopRight: CGPoint
        if let topRight = topRightGrid {
            defaultTopRight = topRight
        } else {
            let gridWidth = Int(width / GridSnapHelper.gridSpacing)
            defaultTopRight = CGPoint(x: defaultTopLeft.x + CGFloat(gridWidth), y: defaultTopLeft.y)
        }
        self.topRightGrid = defaultTopRight
        
        let defaultBottomLeft: CGPoint
        if let bottomLeft = bottomLeftGrid {
            defaultBottomLeft = bottomLeft
        } else {
            // Default visina - 20 redova
            defaultBottomLeft = CGPoint(x: defaultTopLeft.x, y: defaultTopLeft.y + 20)
        }
        self.bottomLeftGrid = defaultBottomLeft
        
        let defaultBottomRight: CGPoint
        if let bottomRight = bottomRightGrid {
            defaultBottomRight = bottomRight
        } else {
            defaultBottomRight = CGPoint(x: defaultTopRight.x, y: defaultBottomLeft.y)
        }
        self.bottomRightGrid = defaultBottomRight
        
        // Kreiraj ili koristi postojeći component
        let finalComponent: NetworkComponent
        if let component = component {
            finalComponent = component
        } else {
            finalComponent = NetworkComponent(
                componentType: .laptop,
                position: .zero,
                name: zoneType.name,
                isClientA: zoneType == .clientA,
                isClientB: zoneType == .clientB
            )
        }
        
        // Inicijaliziraj AreaTopologyElement s private visibility
        super.init(
            component: finalComponent,
            visibility: .private, // Client zones su private (u zonama)
            areaWidth: width,
            areaHeight: CGFloat((defaultBottomLeft.y - defaultTopLeft.y) * GridSnapHelper.gridSpacing)
        )
    }
    
    // MARK: - Override Methods
    
    override func getStatus() -> String {
        "\(zoneType.name) Zone"
    }
    
    override func getMetadata() -> [String: Any] {
        var metadata = super.getMetadata()
        metadata["zoneType"] = zoneType.name
        metadata["width"] = width
        metadata["gridCoordinates"] = [
            "topLeft": ["x": topLeftGrid.x, "y": topLeftGrid.y],
            "topRight": ["x": topRightGrid.x, "y": topRightGrid.y],
            "bottomLeft": ["x": bottomLeftGrid.x, "y": bottomLeftGrid.y],
            "bottomRight": ["x": bottomRightGrid.x, "y": bottomRightGrid.y]
        ]
        return metadata
    }
    
    // MARK: - Client Zone Specific Methods
    
    func changeDeviceType(to type: NetworkComponent.ComponentType) {
        guard type.canBeClient else { return }
        component.componentType = type
        component.name = name
        component.objectWillChange.send()
        objectWillChange.send()
    }
    
    func updateComponent(_ newComponent: NetworkComponent) {
        component = newComponent
        objectWillChange.send()
    }
    
    // MARK: - Override AreaElement
    
    override var areaColor: Color {
        color // Koristi zone color umjesto component custom color
    }
}

/// View wrapper za ClientZone - prikazuje područje klijenta s elementom za izbor uređaja, tekstom, bojom i nazivom
struct ClientZoneView: View {
    @ObservedObject var clientZone: ClientZone
    let geometry: GeometryProxy
    let topology: NetworkTopology
    let simulation: NetworkSimulation
    let connectingFrom: NetworkComponent?
    let hoveredConnectionPoint: (component: NetworkComponent, point: ConnectionPoint)?
    let onClientTap: (NetworkComponent) -> Void
    let onClientTypeChange: (NetworkComponent, NetworkComponent.ComponentType) -> Void
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    let onResize: (CGFloat) -> Void
    
    // Calculate position for device selector component - RELATIVE to zone, not global
    private var componentXRelative: CGFloat {
        // Center of zone (relative to zone, not global)
        return clientZone.width / 2
    }
    
    private var componentYRelative: CGFloat {
        // Position in bottom half of zone
        // Since we're in a ZStack with VStack that has Spacer, we need to calculate relative to zone height
        // We'll use GeometryReader to get zone height
        return 0 // Will be calculated in GeometryReader
    }
    
    // Convert grid koordinate u piksel pozicije
    private func gridToPixel(_ gridPoint: CGPoint) -> CGPoint {
        return CGPoint(
            x: gridPoint.x * GridSnapHelper.gridSpacing,
            y: gridPoint.y * GridSnapHelper.gridSpacing
        )
    }
    
    // Calculate zone corner coordinates in pixels from grid coordinates
    private var zoneCornerCoordinates: (topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) {
        let topLeft = gridToPixel(clientZone.topLeftGrid)
        let topRight = gridToPixel(clientZone.topRightGrid)
        let bottomLeft = gridToPixel(clientZone.bottomLeftGrid)
        let bottomRight = gridToPixel(clientZone.bottomRightGrid)
        
        return (topLeft, topRight, bottomLeft, bottomRight)
    }
    
    // Calculate zone position and size from grid coordinates
    private var zoneFrame: (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let corners = zoneCornerCoordinates
        let x = corners.topLeft.x
        let y = corners.topLeft.y
        let width = corners.topRight.x - corners.topLeft.x
        let height = corners.bottomLeft.y - corners.topLeft.y
        
        return (x, y, width, height)
    }
    
    // Calculate global position for gestures (needed for connection dragging)
    private var componentXGlobal: CGFloat {
        let frame = zoneFrame
        return frame.x + (frame.width / 2)
    }
    
    private var componentYGlobal: CGFloat {
        let frame = zoneFrame
        return frame.y + (frame.height / 2)
    }
    
    var body: some View {
        if clientZone.isVisible {
            GeometryReader { zoneGeometry in
                ZStack {
                    // Device selector component - positioned relative to zone
                    // Use component from topology if available, otherwise use from clientZone
                    let component = (clientZone.zoneType == .clientA ? topology.clientA : topology.clientB) ?? clientZone.component
                    
                    // Calculate Y position relative to zone - bottom half (originalna pozicija)
                    let zoneHeight = zoneGeometry.size.height
                    let bottomHalfStart = zoneHeight * 0.5
                    let bottomHalfHeight = zoneHeight * 0.5
                    let padding: CGFloat = 20
                    let componentYInZone = bottomHalfStart + (bottomHalfHeight / 2) - padding // Originalna pozicija
                    
                    ClientDeviceSelectorView(
                        component: component,
                        topology: topology,
                        simulation: simulation,
                        geometry: geometry,
                        x: componentXGlobal, // Global X for gestures
                        y: componentYGlobal, // Global Y for gestures
                        xRelative: componentXRelative, // Relative X within zone
                        yRelative: componentYInZone, // Relative Y within zone
                        color: clientZone.color,
                        connectingFrom: connectingFrom,
                        hoveredPoint: hoveredConnectionPoint?.component.id == component.id ? hoveredConnectionPoint?.point : nil,
                        onTypeChange: { _, type in
                            clientZone.changeDeviceType(to: type)
                            onClientTypeChange(component, type)
                        },
                        onTap: { _ in onClientTap(component) },
                        onConnectionDragStart: onConnectionDragStart
                    )
                    
                    // Resize handles na svim rubovima - prikazuju se kada se miš približi rubu
                    // Top edge
                    ZoneResizeHandleView(
                        clientZone: clientZone,
                        zoneGeometry: zoneGeometry,
                        edge: .top,
                        onResize: { newHeight in
                            // Resize height (možemo dodati height property u ClientZone ako treba)
                        }
                    )
                    
                    // Bottom edge
                    ZoneResizeHandleView(
                        clientZone: clientZone,
                        zoneGeometry: zoneGeometry,
                        edge: .bottom,
                        onResize: { newHeight in
                            // Resize height
                        }
                    )
                    
                    // Left edge (za Client B) ili Right edge (za Client A)
                    ZoneResizeHandleView(
                        clientZone: clientZone,
                        zoneGeometry: zoneGeometry,
                        edge: clientZone.zoneType == .clientA ? .right : .left,
                        onResize: onResize
                    )
                }
                .padding(8) // Padding da ne dira rubove
            }
            .frame(width: zoneFrame.width, height: zoneFrame.height)
            .position(x: zoneFrame.x + zoneFrame.width / 2, y: zoneFrame.y + zoneFrame.height / 2)
            .background(clientZone.backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(clientZone.borderColor, style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
            .overlay(
                // Natpis - samo Client A ili Client B
                VStack {
                    HStack {
                        Text("\(clientZone.name)")
                            .font(.headline.bold())
                            .foregroundColor(clientZone.color)
                            .padding(8)
                        Spacer()
                    }
                    Spacer()
                }
            )
            .clipped()
        }
    }
}

/// View za label tekst klijenta
struct ClientLabelView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.headline.bold())
            .foregroundColor(color)
    }
}

/// View za element izbora uređaja (device selector) s pinovima za spajanje
struct ClientDeviceSelectorView: View {
    @ObservedObject var component: NetworkComponent
    @ObservedObject var topology: NetworkTopology
    @ObservedObject var simulation: NetworkSimulation
    let geometry: GeometryProxy
    let x: CGFloat // Global X for gestures
    let y: CGFloat // Global Y for gestures
    let xRelative: CGFloat // Relative X within zone
    let yRelative: CGFloat // Relative Y within zone
    let color: Color
    let connectingFrom: NetworkComponent?
    let hoveredPoint: ConnectionPoint?
    let onTypeChange: (NetworkComponent, NetworkComponent.ComponentType) -> Void
    let onTap: (NetworkComponent) -> Void
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    
    private let types: [NetworkComponent.ComponentType] = [.laptop, .desktop, .tablet, .mobile]
    
    var body: some View {
        let currentIndex = types.firstIndex(of: component.componentType) ?? 0
        let nextType = types[(currentIndex + 1) % types.count]
        let componentCenter = CGPoint(x: x, y: y)
        
        return NetworkComponentView(component: component, topology: topology, iconColor: color, pinColor: color, hoveredPoint: hoveredPoint)
            .frame(width: 90, height: 90)
            .contentShape(Rectangle())
            .position(x: xRelative, y: yRelative) // Use relative position within zone
            .zIndex(10)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        // Check if starting from connection point (within 20px radius)
                        let connectionPointRadius: CGFloat = 20
                        let startDx = value.startLocation.x - 45
                        let startDy = value.startLocation.y - 45
                        let distanceFromCenter = sqrt(startDx * startDx + startDy * startDy)
                        
                        // Check if near a connection point (45px from center)
                        if abs(distanceFromCenter - 45) < connectionPointRadius || distanceFromCenter < connectionPointRadius {
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
                    }
            )
    }
}

/// View za resize handle na rubovima klijentske zone - prikazuje se kada se miš približi rubu
struct ZoneResizeHandleView: View {
    @ObservedObject var clientZone: ClientZone
    let zoneGeometry: GeometryProxy
    let edge: Edge
    let onResize: (CGFloat) -> Void
    
    @State private var isHovering = false
    @State private var isResizing = false
    @State private var dragStartValue: CGFloat = 0
    @State private var mouseLocation: CGPoint = .zero
    
    private let handleSize: CGFloat = 24
    private let hoverThreshold: CGFloat = 15 // Udaljenost od ruba kada se handle prikazuje
    
    enum Edge {
        case top
        case bottom
        case left
        case right
    }
    
    var body: some View {
        let (handleX, handleY, isNearEdge): (CGFloat, CGFloat, Bool) = {
            switch edge {
            case .top:
                let x = zoneGeometry.size.width / 2
                let y: CGFloat = 0
                let near = abs(mouseLocation.y) < hoverThreshold
                return (x, y, near)
            case .bottom:
                let x = zoneGeometry.size.width / 2
                let y = zoneGeometry.size.height
                let near = abs(mouseLocation.y - zoneGeometry.size.height) < hoverThreshold
                return (x, y, near)
            case .left:
                let x: CGFloat = 0
                let y = zoneGeometry.size.height / 2
                let near = abs(mouseLocation.x) < hoverThreshold
                return (x, y, near)
            case .right:
                let x = zoneGeometry.size.width
                let y = zoneGeometry.size.height / 2
                let near = abs(mouseLocation.x - zoneGeometry.size.width) < hoverThreshold
                return (x, y, near)
            }
        }()
        
        Circle()
            .fill(clientZone.color.opacity((isHovering || isResizing || isNearEdge) ? 0.8 : 0.0))
            .frame(width: handleSize, height: handleSize)
            .overlay(
                // Strelica ovisno o rubu
                Group {
                    switch edge {
                    case .top, .bottom:
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 8))
                            Image(systemName: "arrow.down")
                                .font(.system(size: 8))
                        }
                    case .left, .right:
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 8))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8))
                        }
                    }
                }
                .foregroundColor(.white)
                .opacity((isHovering || isResizing || isNearEdge) ? 1.0 : 0.0)
            )
            .position(x: handleX, y: handleY)
            .contentShape(Circle())
            .onHover { hovering in
                isHovering = hovering
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    mouseLocation = location
                case .ended:
                    mouseLocation = .zero
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isResizing {
                            isResizing = true
                            dragStartValue = getCurrentValue()
                        }
                        
                        let delta: CGFloat
                        switch edge {
                        case .top:
                            delta = value.translation.height
                        case .bottom:
                            delta = -value.translation.height
                        case .left:
                            delta = value.translation.width
                        case .right:
                            delta = -value.translation.width
                        }
                        
                        let newValue = dragStartValue + delta
                        // Snap to grid
                        let snappedValue = GridSnapHelper.snapToGrid(CGPoint(x: newValue, y: 0)).x
                        
                        // Za left/right edge resize-ujemo width, za top/bottom možemo dodati height property
                        if edge == .left || edge == .right {
                            let finalWidth = max(80, min(200, snappedValue))
                            onResize(finalWidth)
                        } else {
                            // Za top/bottom možemo dodati height resize u budućnosti
                            // Za sada samo width
                        }
                    }
                    .onEnded { _ in
                        isResizing = false
                    }
            )
    }
    
    private func getCurrentValue() -> CGFloat {
        switch edge {
        case .top, .bottom:
            return zoneGeometry.size.height
        case .left, .right:
            return clientZone.width
        }
    }
}

