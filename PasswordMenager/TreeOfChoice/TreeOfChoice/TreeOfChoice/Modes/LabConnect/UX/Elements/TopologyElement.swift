//
//  TopologyElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Element koji predstavlja mrežnu topologiju
/// Odgovoran za prikaz i upravljanje topologijom mreže
class TopologyElement: ObservableObject {
    @Published var topology: NetworkTopology
    @Published var simulation: NetworkSimulation
    
    init(topology: NetworkTopology = NetworkTopology(), simulation: NetworkSimulation = NetworkSimulation()) {
        self.topology = topology
        self.simulation = simulation
        self.simulation.setTopology(topology)
    }
    
    func updateSimulation() {
        simulation.setTopology(topology)
    }
    
    func addComponent(_ component: NetworkComponent) {
        topology.components.append(component)
        topology.objectWillChange.send()
    }
    
    func removeComponent(_ component: NetworkComponent) {
        topology.components.removeAll { $0.id == component.id }
        topology.objectWillChange.send()
    }
    
    func addConnection(from: UUID, to: UUID, fromConnectionPoint: ConnectionPoint? = nil, toConnectionPoint: ConnectionPoint? = nil) {
        topology.addConnection(from: from, to: to, fromConnectionPoint: fromConnectionPoint, toConnectionPoint: toConnectionPoint)
        topology.objectWillChange.send()
    }
    
    func removeConnection(_ connection: NetworkConnection) {
        topology.removeConnection(connection)
        topology.objectWillChange.send()
    }
    
    func updateConnection(_ connection: NetworkConnection, controlPoint: CGPoint?, curveType: NetworkConnection.CurveType?) {
        if let index = topology.connections.firstIndex(where: { $0.id == connection.id }) {
            topology.connections[index].controlPoint = controlPoint
            topology.connections[index].curveType = curveType
            topology.objectWillChange.send()
        }
    }
    
    func deleteAllTopology() {
        // Remove all components except Client A and Client B
        topology.components.removeAll { component in
            component.isClientA != true && component.isClientB != true
        }
        
        // Remove all connections
        topology.connections.removeAll()
        
        // Remove all agent assignments (except for Client A and B if they have agents)
        let clientAId = topology.clientA?.id
        let clientBId = topology.clientB?.id
        topology.agentAssignments = topology.agentAssignments.filter { componentId, _ in
            componentId == clientAId || componentId == clientBId
        }
        
        topology.objectWillChange.send()
    }
    
    @MainActor
    func deleteAllConnections() {
        // Remove all connections but keep components
        // Postavi na prazan array umjesto removeAll() da SwiftUI detektira promjenu
        topology.connections = []
        topology.objectWillChange.send()
        objectWillChange.send()
        updateSimulation()
    }
}

/// View wrapper za TopologyElement
struct TopologyElementView: View {
    @ObservedObject var topologyElement: TopologyElement
    let geometry: GeometryProxy
    var isTestMode: Bool = false // Test mode - fiksira elemente i mijenja izgled
    let onComponentTap: (NetworkComponent) -> Void
    let onComponentDrag: (NetworkComponent, CGPoint, GeometryProxy) -> Void
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    let onConnectionDragUpdate: (CGPoint) -> Void
    let onConnectionDragEnd: (CGPoint, GeometryProxy) -> Void
    let onComponentDragUpdate: ((NetworkComponent, CGPoint) -> Void)?
    let onComponentDelete: ((NetworkComponent) -> Void)?
    let onPinClick: ((NetworkComponent, ConnectionPoint, CGPoint) -> Void)?
    let onConnectionDelete: ((NetworkConnection) -> Void)?
    let onConnectionAddControlPoint: ((NetworkConnection, CGPoint, NetworkConnection.CurveType) -> Void)?
    @Binding var selectedComponent: NetworkComponent?
    @Binding var showComponentDetail: Bool
    @Binding var connectingFrom: NetworkComponent?
    @Binding var draggingConnection: (from: NetworkComponent, fromPoint: CGPoint, toPoint: CGPoint)?
    @Binding var hoveredConnectionPoint: (component: NetworkComponent, point: ConnectionPoint)?
    @Binding var mouseLocation: CGPoint
    
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
            if let dragging = draggingConnection {
                ConnectionLine(
                    from: dragging.fromPoint,
                    to: dragging.toPoint,
                    type: .wired,
                    isTestMode: isTestMode
                )
            }
            
            // Client components layer (on top so taps work)
            clientComponentsLayer
            
            // Animated packets layer
            packetsLayer
            
            // Connection mode indicator
            if connectingFrom != nil {
                connectionModeIndicator
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.1))
        .onDrop(of: [.text], delegate: ComponentDropDelegate(
            topology: topologyElement.topology,
            geometry: geometry,
            isTestMode: isTestMode
        ))
        .simultaneousGesture(
            // Global gesture to update dragging connection
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    mouseLocation = value.location
                    
                    // Only handle if dragging connection, not component
                    if draggingConnection != nil {
                        onConnectionDragUpdate(value.location)
                        updateHoveredConnectionPoint(at: value.location, geometry: geometry)
                    } else {
                        updateHoveredConnectionPoint(at: value.location, geometry: geometry)
                    }
                }
                .onEnded { value in
                    if draggingConnection != nil {
                        onConnectionDragEnd(value.location, geometry)
                    }
                    hoveredConnectionPoint = nil
                }
        )
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                mouseLocation = location
                updateHoveredConnectionPoint(at: location, geometry: geometry)
            case .ended:
                if draggingConnection == nil {
                    hoveredConnectionPoint = nil
                }
            }
        }
        .onTapGesture {
            if connectingFrom != nil {
                connectingFrom = nil
            }
            if draggingConnection != nil {
                draggingConnection = nil
            }
        }
    }
    
    // MARK: - Subviews
    
    private var networkComponentsLayer: some View {
        ForEach(topologyElement.topology.components.filter { $0.isClientA != true && $0.isClientB != true }) { component in
            ComponentView(
                component: component,
                topology: topologyElement.topology,
                simulation: topologyElement.simulation,
                geometry: geometry,
                hoveredPoint: hoveredConnectionPoint?.component.id == component.id ? hoveredConnectionPoint?.point : nil,
                isTestMode: isTestMode,
                onTap: { onComponentTap($0) },
                onDrag: { comp, location in onComponentDrag(comp, location, geometry) },
                onConnectionDragStart: { comp, start, current in onConnectionDragStart(comp, start, current) },
                onConnectionDragUpdate: nil, // TopologyElement doesn't handle connection drag updates directly
                onPinClick: nil, // TopologyElement doesn't handle pin clicks directly
                onDragUpdate: onComponentDragUpdate != nil ? { comp, location in onComponentDragUpdate?(comp, location) } : nil,
                onDelete: onComponentDelete
            )
        }
    }
    
    private var clientComponentsLayer: some View {
        HStack(spacing: 0) {
            // Client A Zone
            if let clientA = topologyElement.topology.clientA {
                ZoneElementView(
                    zoneElement: ZoneElement(zoneType: .clientA, width: 110),
                    geometry: geometry,
                    clientComponent: clientA,
                    topology: topologyElement.topology,
                    simulation: topologyElement.simulation,
                    connectingFrom: connectingFrom,
                    hoveredConnectionPoint: hoveredConnectionPoint,
                    onClientTap: { _ in onComponentTap(clientA) },
                    onClientTypeChange: { _, type in changeClientType(clientA, to: type) },
                    onConnectionDragStart: { comp, start, current in onConnectionDragStart(comp, start, current) },
                    onPinClick: onPinClick,
                    onConnectionDragUpdate: onConnectionDragUpdate
                )
            }
            
            // Middle area - takes remaining space
            Spacer()
            
            // Client B Zone
            if let clientB = topologyElement.topology.clientB {
                ZoneElementView(
                    zoneElement: ZoneElement(zoneType: .clientB, width: 110),
                    geometry: geometry,
                    clientComponent: clientB,
                    topology: topologyElement.topology,
                    simulation: topologyElement.simulation,
                    connectingFrom: connectingFrom,
                    hoveredConnectionPoint: hoveredConnectionPoint,
                    onClientTap: { _ in onComponentTap(clientB) },
                    onClientTypeChange: { _, type in changeClientType(clientB, to: type) },
                    onConnectionDragStart: { comp, start, current in onConnectionDragStart(comp, start, current) },
                    onPinClick: onPinClick,
                    onConnectionDragUpdate: onConnectionDragUpdate
                )
            }
        }
    }
    
    private var connectionsLayer: some View {
        ForEach(topologyElement.topology.connections) { connection in
            ConnectionView(
                connection: connection,
                topology: topologyElement.topology,
                geometry: geometry,
                isTestMode: isTestMode,
                onDelete: { conn in topologyElement.removeConnection(conn) }
            )
        }
    }
    
    private var packetsLayer: some View {
        ForEach(topologyElement.simulation.packets) { animatedPacket in
            PacketView(animatedPacket: animatedPacket, topology: topologyElement.topology, geometry: geometry)
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
        for component in topologyElement.topology.components {
            let componentCenter = ComponentPositionManager.getAbsolutePosition(for: component, in: geometry)
            if let connectionPoint = ConnectionPointDetector.detect(at: location, componentCenter: componentCenter) {
                hoveredConnectionPoint = (component: component, point: connectionPoint)
                return
            }
        }
        
        if draggingConnection == nil {
            hoveredConnectionPoint = nil
        }
    }
    
    private func changeClientType(_ component: NetworkComponent, to type: NetworkComponent.ComponentType) {
        guard type.canBeClient else { return }
        component.componentType = type
        component.name = component.isClientA == true ? "Client A" : "Client B"
        component.objectWillChange.send()
        topologyElement.topology.objectWillChange.send()
    }
}

