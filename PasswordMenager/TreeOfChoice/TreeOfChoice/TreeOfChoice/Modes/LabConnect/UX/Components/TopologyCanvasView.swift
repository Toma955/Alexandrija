//
//  TopologyCanvasView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct TopologyCanvasView: View {
    @ObservedObject var topology: NetworkTopology
    @ObservedObject var simulation: NetworkSimulation
    @Binding var selectedComponent: NetworkComponent?
    @Binding var showComponentDetail: Bool
    @Binding var connectingFrom: NetworkComponent?
    @Binding var draggingConnection: (from: NetworkComponent, fromPoint: CGPoint, toPoint: CGPoint)?
    @Binding var hoveredConnectionPoint: (component: NetworkComponent, point: ConnectionPoint)?
    @Binding var mouseLocation: CGPoint
    
    let onComponentTap: (NetworkComponent) -> Void
    let onComponentDrag: (NetworkComponent, CGPoint, GeometryProxy) -> Void
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    let onConnectionDragUpdate: (CGPoint) -> Void
    let onConnectionDragEnd: (CGPoint, GeometryProxy) -> Void
    var onConnectionDelete: ((NetworkConnection) -> Void)? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                GridBackgroundView(geometry: geometry)
                    .frame(width: geometry.size.width)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5)
                
                // A and B sides (background only)
                ClientSidesView(geometry: geometry)
                    .allowsHitTesting(false)
                
                // Network components layer
                networkComponentsLayer(geometry: geometry)
                
                // Connections layer
                connectionsLayer(geometry: geometry)
                
                // Dragging connection line (temporary while dragging)
                if let dragging = draggingConnection {
                    ConnectionLine(
                        from: dragging.fromPoint,
                        to: dragging.toPoint,
                        type: .wired
                    )
                }
                
                // Client components layer (on top so taps work)
                clientComponentsLayer(geometry: geometry)
                
                // Animated packets layer
                packetsLayer(geometry: geometry)
                
                // Connection mode indicator
                if connectingFrom != nil {
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.1))
            .onDrop(of: [.text], delegate: ComponentDropDelegate(
                topology: topology,
                geometry: geometry
            ))
            .simultaneousGesture(
                // Global gesture to update dragging connection (only when dragging connection, not component)
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
    }
    
    // MARK: - Layers
    
    private func networkComponentsLayer(geometry: GeometryProxy) -> some View {
        ForEach(topology.components.filter { $0.isClientA != true && $0.isClientB != true }) { component in
            ComponentView(
                component: component,
                topology: topology,
                simulation: simulation,
                geometry: geometry,
                hoveredPoint: hoveredConnectionPoint?.component.id == component.id ? hoveredConnectionPoint?.point : nil,
                onTap: { onComponentTap($0) },
                onDrag: { comp, location in onComponentDrag(comp, location, geometry) },
                onConnectionDragStart: { comp, start, current in onConnectionDragStart(comp, start, current) },
                onConnectionDragUpdate: nil, // TopologyCanvasView doesn't handle connection drag updates directly
                onPinClick: nil, // TopologyCanvasView doesn't handle pin clicks directly
                onDragUpdate: nil,
                onDelete: nil
            )
        }
    }
    
    private func clientComponentsLayer(geometry: GeometryProxy) -> some View {
        Group {
            if let clientA = topology.clientA {
                ClientComponentView(
                    component: clientA,
                    topology: topology,
                    simulation: simulation,
                    geometry: geometry,
                    x: 65,
                    y: geometry.size.height - 80,
                    connectingFrom: connectingFrom,
                    hoveredPoint: hoveredConnectionPoint?.component.id == clientA.id ? hoveredConnectionPoint?.point : nil,
                    onTypeChange: { changeClientType($0, to: $1) },
                    onTap: { onComponentTap($0) },
                    onConnectionDragStart: { comp, start, current in onConnectionDragStart(comp, start, current) },
                    onPinClick: nil,
                    onConnectionDragUpdate: nil
                )
            }
            if let clientB = topology.clientB {
                ClientComponentView(
                    component: clientB,
                    topology: topology,
                    simulation: simulation,
                    geometry: geometry,
                    x: geometry.size.width - 65,
                    y: geometry.size.height - 80,
                    connectingFrom: connectingFrom,
                    hoveredPoint: hoveredConnectionPoint?.component.id == clientB.id ? hoveredConnectionPoint?.point : nil,
                    onTypeChange: { changeClientType($0, to: $1) },
                    onTap: { onComponentTap($0) },
                    onConnectionDragStart: { comp, start, current in onConnectionDragStart(comp, start, current) },
                    onPinClick: nil,
                    onConnectionDragUpdate: nil
                )
            }
        }
    }
    
    private func connectionsLayer(geometry: GeometryProxy) -> some View {
        ForEach(topology.connections) { connection in
            ConnectionView(
                connection: connection,
                topology: topology,
                geometry: geometry,
                onDelete: onConnectionDelete
            )
        }
    }
    
    private func packetsLayer(geometry: GeometryProxy) -> some View {
        ForEach(simulation.packets) { animatedPacket in
            PacketView(animatedPacket: animatedPacket, topology: topology, geometry: geometry)
        }
    }
    
    // MARK: - Helpers
    
    private func updateHoveredConnectionPoint(at location: CGPoint, geometry: GeometryProxy) {
        for component in topology.components {
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
        topology.objectWillChange.send()
    }
}

