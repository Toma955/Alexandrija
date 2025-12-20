//
//  TopologyViewElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Glavni element koji koordinira sve elemente vezane za prikaz i logiku topologije
/// Centralni element koji upravlja TopologyElement, ZoneElement, ClientElement, itd.
class TopologyViewElement: ObservableObject {
    // Core elements
    @Published var topologyElement: TopologyElement
    @Published var clientAreaElement: ClientAreaElement
    
    // UI State
    @Published var selectedComponent: NetworkComponent?
    @Published var showComponentDetail: Bool = false
    @Published var showUserDialog: Bool = false
    @Published var selectedUserComponent: NetworkComponent?
    @Published var connectingFrom: NetworkComponent?
    @Published var draggingConnection: (from: NetworkComponent, fromPoint: CGPoint, toPoint: CGPoint)?
    @Published var hoveredConnectionPoint: (component: NetworkComponent, point: ConnectionPoint)?
    @Published var mouseLocation: CGPoint = .zero
    
    init() {
        // Initialize topology
        let topology = NetworkTopology()
        let simulation = NetworkSimulation()
        simulation.setTopology(topology)
        
        self.topologyElement = TopologyElement(topology: topology, simulation: simulation)
        
        // Initialize clients
        let clientA = NetworkComponent(
            componentType: .laptop,
            position: .zero,
            name: "Client A",
            isClientA: true,
            isClientB: nil
        )
        let clientB = NetworkComponent(
            componentType: .laptop,
            position: .zero,
            name: "Client B",
            isClientA: nil,
            isClientB: true
        )
        
        // Initialize Client Area Element with clients (koristi ClientZone objekte)
        self.clientAreaElement = ClientAreaElement(clientA: clientA, clientB: clientB)
        
        // Add clients to topology
        topology.clientA = clientA
        topology.clientB = clientB
        topology.components.append(contentsOf: [clientA, clientB])
        
        // Sync ClientZone components with topology
        clientAreaElement.clientAZone.updateComponent(clientA)
        clientAreaElement.clientBZone.updateComponent(clientB)
    }
    
    // MARK: - Component Management
    
    func handleComponentTap(_ component: NetworkComponent) {
        if let from = connectingFrom {
            if from.id != component.id {
                topologyElement.addConnection(from: from.id, to: component.id)
            }
            connectingFrom = nil
        } else {
            // Ako je User ili Area komponenta, otvori User dialog
            if component.componentType.supportsCustomColor {
                selectedUserComponent = component
                showUserDialog = true
            } else {
                selectedComponent = component
                showComponentDetail = true
            }
        }
    }
    
    func handleComponentDrag(_ component: NetworkComponent, location: CGPoint, geometry: GeometryProxy) {
        // Constrain to zones - Client A and B stay centered in their zones, others in middle
        let constrainedX: CGFloat
        let constrainedY: CGFloat
        
        let zoneWidth: CGFloat = 110
        let padding: CGFloat = 10
        let middleAreaStart = padding + zoneWidth
        
        if component.isClientA == true {
            // Client A: centered in zone, in bottom half
            let bottomHalfStart = geometry.size.height * 0.5
            let bottomHalfHeight = geometry.size.height * 0.5
            let verticalPadding: CGFloat = 20
            constrainedY = bottomHalfStart + (bottomHalfHeight / 2) - verticalPadding
            constrainedX = padding + (zoneWidth / 2) // Center of Client A zone with padding
        } else if component.isClientB == true {
            // Client B: centered in zone, in bottom half
            let bottomHalfStart = geometry.size.height * 0.5
            let bottomHalfHeight = geometry.size.height * 0.5
            let verticalPadding: CGFloat = 20
            constrainedY = bottomHalfStart + (bottomHalfHeight / 2) - verticalPadding
            constrainedX = (geometry.size.width - padding - zoneWidth) + (zoneWidth / 2) // Center of Client B zone with padding
        } else {
            // Other components stay in middle area
            // Snap to grid
            let snappedLocation = GridSnapHelper.snapToGrid(location)
            constrainedX = max(middleAreaStart + 45, min(geometry.size.width - padding - zoneWidth - 45, snappedLocation.x))
            constrainedY = max(45, min(geometry.size.height - 45, snappedLocation.y))
            
            // Calculate relative position for middle area
            let newPosition = ComponentPositionManager.calculateRelativePosition(
                absoluteX: constrainedX,
                absoluteY: constrainedY,
                geometry: geometry
            )
            
            component.position = newPosition
            component.objectWillChange.send()
            topologyElement.topology.objectWillChange.send()
            return
        }
        
        // For Client A and B, position is fixed in corners
        component.position = CGPoint(x: constrainedX, y: constrainedY)
        component.objectWillChange.send()
        topologyElement.topology.objectWillChange.send()
    }
    
    func handleConnectionDragStart(_ component: NetworkComponent, fromPoint: CGPoint, toPoint: CGPoint) {
        if draggingConnection == nil {
            draggingConnection = (from: component, fromPoint: fromPoint, toPoint: toPoint)
        }
    }
    
    func handleConnectionDragUpdate(_ location: CGPoint) {
        if let dragging = draggingConnection {
            draggingConnection = (from: dragging.from, fromPoint: dragging.fromPoint, toPoint: location)
        }
    }
    
    func handleConnectionDragEnd(_ location: CGPoint, geometry: GeometryProxy) {
        guard let dragging = draggingConnection else { return }
        
        if let targetComponent = ComponentPositionManager.findComponent(
            at: location,
            in: topologyElement.topology.components,
            geometry: geometry,
            exclude: dragging.from
        ) {
            let targetCenter = ComponentPositionManager.getAbsolutePosition(for: targetComponent, in: geometry)
            if ConnectionPointDetector.detect(at: location, componentCenter: targetCenter) != nil {
                topologyElement.addConnection(from: dragging.from.id, to: targetComponent.id)
            }
        }
        
        draggingConnection = nil
    }
    
    func updateSimulation() {
        topologyElement.updateSimulation()
    }
}

/// View wrapper za TopologyViewElement - glavni view za topologiju
struct TopologyViewElementView: View {
    @ObservedObject var topologyViewElement: TopologyViewElement
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            // Background grid
            GridBackgroundView(geometry: geometry)
                .frame(width: geometry.size.width)
                .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5)
            
            // Network components layer
            networkComponentsLayer
            
            // Connections layer
            connectionsLayer
            
            // Dragging connection line (temporary while dragging)
            if let dragging = topologyViewElement.draggingConnection {
                ConnectionLine(
                    from: dragging.fromPoint,
                    to: dragging.toPoint,
                    type: .wired
                )
            }
            
            // Animated packets layer
            packetsLayer
            
            // Connection mode indicator
            if topologyViewElement.connectingFrom != nil {
                connectionModeIndicator
            }
            
            // User dialog overlay
            if topologyViewElement.showUserDialog, let userComponent = topologyViewElement.selectedUserComponent {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            topologyViewElement.showUserDialog = false
                        }
                    
                    UserComponentDialog(
                        component: userComponent,
                        isPresented: $topologyViewElement.showUserDialog
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.1))
        .onDrop(of: [.text], delegate: ComponentDropDelegate(
            topology: topologyViewElement.topologyElement.topology,
            geometry: geometry
        ))
        .simultaneousGesture(
            // Global gesture to update dragging connection
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    topologyViewElement.mouseLocation = value.location
                    
                    // Only handle if dragging connection, not component
                    if topologyViewElement.draggingConnection != nil {
                        topologyViewElement.handleConnectionDragUpdate(value.location)
                        updateHoveredConnectionPoint(at: value.location, geometry: geometry)
                    } else {
                        updateHoveredConnectionPoint(at: value.location, geometry: geometry)
                    }
                }
                .onEnded { value in
                    if topologyViewElement.draggingConnection != nil {
                        topologyViewElement.handleConnectionDragEnd(value.location, geometry: geometry)
                    }
                    topologyViewElement.hoveredConnectionPoint = nil
                }
        )
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                topologyViewElement.mouseLocation = location
                updateHoveredConnectionPoint(at: location, geometry: geometry)
            case .ended:
                if topologyViewElement.draggingConnection == nil {
                    topologyViewElement.hoveredConnectionPoint = nil
                }
            }
        }
        .onTapGesture {
            if topologyViewElement.connectingFrom != nil {
                topologyViewElement.connectingFrom = nil
            }
            if topologyViewElement.draggingConnection != nil {
                topologyViewElement.draggingConnection = nil
            }
        }
    }
    
    // MARK: - Layers
    
    private var networkComponentsLayer: some View {
        ForEach(topologyViewElement.topologyElement.topology.components.filter { $0.isClientA != true && $0.isClientB != true }) { component in
            ComponentView(
                component: component,
                topology: topologyViewElement.topologyElement.topology,
                simulation: topologyViewElement.topologyElement.simulation,
                geometry: geometry,
                hoveredPoint: topologyViewElement.hoveredConnectionPoint?.component.id == component.id ? topologyViewElement.hoveredConnectionPoint?.point : nil,
                onTap: { topologyViewElement.handleComponentTap($0) },
                onDrag: { comp, location in topologyViewElement.handleComponentDrag(comp, location: location, geometry: geometry) },
                onConnectionDragStart: { comp, start, current in topologyViewElement.handleConnectionDragStart(comp, fromPoint: start, toPoint: current) }
            )
        }
    }
    
    private var connectionsLayer: some View {
        ForEach(topologyViewElement.topologyElement.topology.connections) { connection in
            ConnectionView(
                connection: connection,
                topology: topologyViewElement.topologyElement.topology,
                geometry: geometry
            )
        }
    }
    
    private var packetsLayer: some View {
        ForEach(topologyViewElement.topologyElement.simulation.packets) { animatedPacket in
            PacketView(animatedPacket: animatedPacket, topology: topologyViewElement.topologyElement.topology, geometry: geometry)
        }
    }
    
    private var connectionModeIndicator: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connection Mode")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Tap on another component to connect")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("(Tap anywhere else to cancel)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(12)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.yellow, lineWidth: 2)
                )
                Spacer()
            }
            .padding(16)
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func updateHoveredConnectionPoint(at location: CGPoint, geometry: GeometryProxy) {
        // Check all components including Client A and Client B
        for component in topologyViewElement.topologyElement.topology.components {
            let componentCenter = ComponentPositionManager.getAbsolutePosition(for: component, in: geometry)
            
            if let connectionPoint = ConnectionPointDetector.detect(at: location, componentCenter: componentCenter) {
                topologyViewElement.hoveredConnectionPoint = (component: component, point: connectionPoint)
                return
            }
        }
        
        if topologyViewElement.draggingConnection == nil {
            topologyViewElement.hoveredConnectionPoint = nil
        }
    }
    
    private func changeClientType(_ component: NetworkComponent, to type: NetworkComponent.ComponentType) {
        guard type.canBeClient else { return }
        component.componentType = type
        component.name = component.isClientA == true ? "Client A" : "Client B"
        component.objectWillChange.send()
        topologyViewElement.topologyElement.topology.objectWillChange.send()
    }
}



