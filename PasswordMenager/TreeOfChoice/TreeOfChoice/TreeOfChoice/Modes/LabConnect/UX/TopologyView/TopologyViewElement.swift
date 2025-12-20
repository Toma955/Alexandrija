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
    @Published var draggingConnection: (from: NetworkComponent, fromPoint: CGPoint, fromConnectionPoint: ConnectionPoint, toPoint: CGPoint)?
    @Published var hoveredConnectionPoint: (component: NetworkComponent, point: ConnectionPoint)?
    @Published var mouseLocation: CGPoint = .zero
    @Published var isDraggingComponent: Bool = false
    @Published var isDraggingOverDelete: Bool = false
    @Published var showDeleteButton: Bool = false
    
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
            // Ako je User komponenta, otvori User dialog
            if component.componentType == .user {
                selectedUserComponent = component
                showUserDialog = true
            } else {
                selectedComponent = component
                showComponentDetail = true
            }
        }
    }
    
    func handleComponentDrag(_ component: NetworkComponent, location: CGPoint, geometry: GeometryProxy) {
        // Set dragging state
        if !isDraggingComponent {
            isDraggingComponent = true
            showDeleteButton = true // Show button when drag starts
        }
        
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
            // Other components stay in middle area - allow free movement during drag
            // Don't snap during drag, only update position
            constrainedX = max(middleAreaStart + 45, min(geometry.size.width - padding - zoneWidth - 45, location.x))
            constrainedY = max(45, min(geometry.size.height - 45, location.y))
            
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
    
    func handleComponentDragEnd(_ component: NetworkComponent, finalPosition: CGPoint, geometry: GeometryProxy) {
        // Check if dropped over delete button first
        let deleteButtonY = geometry.size.height - 60
        let deleteButtonRadius: CGFloat = 30
        let deleteButtonCenterX = geometry.size.width / 2
        
        let dx = finalPosition.x - deleteButtonCenterX
        let dy = finalPosition.y - deleteButtonY
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance <= deleteButtonRadius {
            // Delete component and hide button
            deleteComponent(component)
            // Osiguraj da se button sakrije nakon brisanja
            DispatchQueue.main.async {
                self.isDraggingComponent = false
                self.isDraggingOverDelete = false
                self.showDeleteButton = false
            }
        } else {
            // Update dragging state when not deleting
            isDraggingComponent = false
            isDraggingOverDelete = false
            showDeleteButton = false // Hide button immediately when drag ends
            
            if component.isClientA != true && component.isClientB != true {
            // Snap to grid on drop (only for non-client components)
            let snappedLocation = GridSnapHelper.snapToGrid(finalPosition)
            let zoneWidth: CGFloat = 110
            let padding: CGFloat = 10
            let middleAreaStart = padding + zoneWidth
            
            let constrainedX = max(middleAreaStart + 45, min(geometry.size.width - padding - zoneWidth - 45, snappedLocation.x))
            let constrainedY = max(45, min(geometry.size.height - 45, snappedLocation.y))
            
            let newPosition = ComponentPositionManager.calculateRelativePosition(
                absoluteX: constrainedX,
                absoluteY: constrainedY,
                geometry: geometry
            )
            
                component.position = newPosition
                component.objectWillChange.send()
                topologyElement.topology.objectWillChange.send()
            }
        }
    }
    
    func handleComponentDragUpdate(_ component: NetworkComponent, location: CGPoint, geometry: GeometryProxy) {
        // Set dragging state
        if !isDraggingComponent {
            isDraggingComponent = true
            showDeleteButton = true // Show button when drag starts
        }
        
        // Check if dragging over delete button
        let deleteButtonY = geometry.size.height - 60
        let deleteButtonRadius: CGFloat = 30
        let deleteButtonCenterX = geometry.size.width / 2
        
        let dx = location.x - deleteButtonCenterX
        let dy = location.y - deleteButtonY
        let distance = sqrt(dx * dx + dy * dy)
        
        isDraggingOverDelete = distance <= deleteButtonRadius
    }
    
    func deleteComponent(_ component: NetworkComponent) {
        topologyElement.removeComponent(component)
        // Osiguraj da se delete button sakrije nakon brisanja
        DispatchQueue.main.async {
            self.isDraggingComponent = false
            self.isDraggingOverDelete = false
            self.showDeleteButton = false
        }
    }
    
    func handleConnectionDragStart(_ component: NetworkComponent, fromPoint: CGPoint, toPoint: CGPoint, geometry: GeometryProxy) {
        if draggingConnection == nil {
            // Fallback metoda - ako se koristi bez pin klika, nemamo fromConnectionPoint
            // Koristimo automatski odabir najbližeg pina
            let componentCenter = ComponentPositionManager.getAbsolutePosition(for: component, in: geometry)
            let fromConnectionPoint = ConnectionPointDetector.detect(at: fromPoint, componentCenter: componentCenter) ?? .top
            draggingConnection = (from: component, fromPoint: fromPoint, fromConnectionPoint: fromConnectionPoint, toPoint: toPoint)
        }
    }
    
    func handlePinClick(_ component: NetworkComponent, connectionPoint: ConnectionPoint, pinPosition: CGPoint) {
        // Provjeri da li pin već ima konekciju
        let existingConnections = topologyElement.topology.getConnections(for: component.id)
        if let existingConnection = existingConnections.first(where: { conn in
            // Provjeri je li konekcija na ovom pinu
            if conn.fromComponentId == component.id, let fromPin = conn.fromConnectionPoint {
                return fromPin == connectionPoint
            } else if conn.toComponentId == component.id, let toPin = conn.toConnectionPoint {
                return toPin == connectionPoint
            }
            return false
        }) {
            // Pin već ima konekciju - obriši je (odspoji pin)
            topologyElement.removeConnection(existingConnection)
        }
        
        // Započni connection dragging od klika na pin
        // Novi krug se stvara na poziciji pina i prati miš
        if draggingConnection == nil {
            // fromPoint je pozicija originalnog pina (gdje je kliknut)
            // toPoint počinje na poziciji pina (krug se stvara na pinu), zatim prati miš
            // Ako je miš dostupan, odmah postavi toPoint na poziciju miša
            let initialToPoint = mouseLocation != .zero ? mouseLocation : pinPosition
            draggingConnection = (from: component, fromPoint: pinPosition, fromConnectionPoint: connectionPoint, toPoint: initialToPoint)
        }
    }
    
    func handleConnectionDragUpdate(_ location: CGPoint, geometry: GeometryProxy) {
        guard let dragging = draggingConnection else {
            return
        }
        
        // Krug prati miš - ažuriraj toPoint da prati trenutnu poziciju miša
        var finalToPoint = location
        
        // Provjeri je li novi pin blizu drugog pina (snap to pin)
        if let targetComponent = ComponentPositionManager.findComponent(
            at: location,
            in: topologyElement.topology.components,
            geometry: geometry,
            exclude: dragging.from
        ) {
            let targetCenter = ComponentPositionManager.getAbsolutePosition(for: targetComponent, in: geometry)
            if let connectionPoint = ConnectionPointDetector.detect(at: location, componentCenter: targetCenter) {
                // Novi pin je blizu drugog pina - spoji ga na taj pin
                finalToPoint = ConnectionPointDetector.position(for: connectionPoint, componentCenter: targetCenter)
            }
        }
        
        // Ažuriraj dragging connection - krug prati miš
        // OVO JE KLJUČNO - ažuriraj @Published property da triggera UI update
        draggingConnection = (from: dragging.from, fromPoint: dragging.fromPoint, fromConnectionPoint: dragging.fromConnectionPoint, toPoint: finalToPoint)
    }
    
    func handleConnectionDragEnd(_ location: CGPoint, geometry: GeometryProxy) {
        guard let dragging = draggingConnection else { return }
        
        // Provjeri je li drop na pin drugog komponenta
        if let targetComponent = ComponentPositionManager.findComponent(
            at: location,
            in: topologyElement.topology.components,
            geometry: geometry,
            exclude: dragging.from
        ) {
            let targetCenter = ComponentPositionManager.getAbsolutePosition(for: targetComponent, in: geometry)
            if let toConnectionPoint = ConnectionPointDetector.detect(at: location, componentCenter: targetCenter) {
                // Spoji konekciju s točnim pinovima
                topologyElement.addConnection(
                    from: dragging.from.id,
                    to: targetComponent.id,
                    fromConnectionPoint: dragging.fromConnectionPoint,
                    toConnectionPoint: toConnectionPoint
                )
            } else {
                // Nije drop na pin - linija se gubi (ne stvara se konekcija)
            }
        } else {
            // Nije drop na komponentu - linija se gubi (ne stvara se konekcija)
        }
        
        // Reset dragging connection
        draggingConnection = nil
    }
    
    func updateSimulation() {
        topologyElement.updateSimulation()
    }
    
    func deleteAllTopology() {
        topologyElement.deleteAllTopology()
        // Reset UI state
        selectedComponent = nil
        showComponentDetail = false
        connectingFrom = nil
        draggingConnection = nil
        hoveredConnectionPoint = nil
        isDraggingComponent = false
        isDraggingOverDelete = false
        showDeleteButton = false
    }
}

/// View wrapper za TopologyViewElement - glavni view za topologiju
struct TopologyViewElementView: View {
    @ObservedObject var topologyViewElement: TopologyViewElement
    let geometry: GeometryProxy
    
    // Helper za provjeru je li novi pin blizu drugog pina
    private func isNearTargetPin(_ location: CGPoint) -> (component: NetworkComponent, pinPosition: CGPoint)? {
        guard let dragging = topologyViewElement.draggingConnection else { return nil }
        
        if let targetComponent = ComponentPositionManager.findComponent(
            at: location,
            in: topologyViewElement.topologyElement.topology.components,
            geometry: geometry,
            exclude: dragging.from
        ) {
            let targetCenter = ComponentPositionManager.getAbsolutePosition(for: targetComponent, in: geometry)
            if let connectionPoint = ConnectionPointDetector.detect(at: location, componentCenter: targetCenter) {
                let pinPosition = ConnectionPointDetector.position(for: connectionPoint, componentCenter: targetCenter)
                return (targetComponent, pinPosition)
            }
        }
        return nil
    }
    
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
                // Provjeri je li novi pin blizu drugog pina
                if let target = isNearTargetPin(dragging.toPoint) {
                    // Spoji liniju na drugi pin
                    ConnectionLine(
                        from: dragging.fromPoint,
                        to: target.pinPosition,
                        type: .wired
                    )
                } else {
                    // Siva vidljiva linija od originalnog pina do kruga koji prati miš
                    ConnectionLine(
                        from: dragging.fromPoint,
                        to: dragging.toPoint,
                        type: .wired
                    )
                    
                    // Novi krug koji prati miš - stvoren na poziciji pina, sada prati miš
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 14, height: 14)
                        .position(dragging.toPoint)
                }
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
            
            // Delete button at the bottom center
            if topologyViewElement.showDeleteButton {
                VStack {
                    Spacer()
                    DeleteButtonView(
                        isDraggingOver: $topologyViewElement.isDraggingOverDelete,
                        isDragging: topologyViewElement.isDraggingComponent
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 60)
                    .animation(.easeInOut(duration: 0.2), value: topologyViewElement.isDraggingOverDelete)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.1))
        .onDrop(of: [.text], delegate: ComponentDropDelegate(
            topology: topologyViewElement.topologyElement.topology,
            geometry: geometry
        ))
        .background(
            // Invisible background za hvatanje mouse events
            Color.clear
                .contentShape(Rectangle())
                .allowsHitTesting(true)
                .gesture(
                    // GLOBALNI gesture koji prati miš CIJELO VRIJEME kada postoji draggingConnection
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            topologyViewElement.mouseLocation = value.location
                            
                            // KLJUČNO: Ako postoji dragging connection, KONTINUIRANO ažuriraj toPoint da prati kursor
                            if topologyViewElement.draggingConnection != nil {
                                topologyViewElement.handleConnectionDragUpdate(value.location, geometry: geometry)
                                updateHoveredConnectionPoint(at: value.location, geometry: geometry)
                            } else {
                                updateHoveredConnectionPoint(at: value.location, geometry: geometry)
                            }
                        }
                        .onEnded { value in
                            // Ne završavaj konekciju ovdje - to se radi klikom na drugi pin
                            // Samo resetuj hovered point ako nema dragging connection
                            if topologyViewElement.draggingConnection == nil {
                                topologyViewElement.hoveredConnectionPoint = nil
                            }
                        }
                )
        )
        .simultaneousGesture(
            // SIMULTANEOUS gesture - aktivira se ISTOVREMENO s gesture-ima na komponentama
            // OVO JE KLJUČNO za praćenje miša kada se klikne na pin
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Ako postoji dragging connection, KONTINUIRANO ažuriraj poziciju kruga
                    // OVO SE POZIVA CIJELO VRIJEME dok se drži klik, BEZ OBZIRA gdje je miš
                    if topologyViewElement.draggingConnection != nil {
                        topologyViewElement.mouseLocation = value.location
                        topologyViewElement.handleConnectionDragUpdate(value.location, geometry: geometry)
                    }
                }
        )
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                topologyViewElement.mouseLocation = location
                // Ako postoji dragging connection, KONTINUIRANO ažuriraj toPoint da prati kursor (krug prati miš)
                if topologyViewElement.draggingConnection != nil {
                    // OVO JE KLJUČNO - kontinuirano ažuriraj poziciju kruga dok se drži klik
                    topologyViewElement.handleConnectionDragUpdate(location, geometry: geometry)
                }
                updateHoveredConnectionPoint(at: location, geometry: geometry)
            case .ended:
                if topologyViewElement.draggingConnection == nil {
                    topologyViewElement.hoveredConnectionPoint = nil
                }
            }
        }
        .simultaneousGesture(
            // Tap gesture za završetak konekcije klikom na pin
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    // Provjeri je li klik na pin drugog komponenta dok se vuče konekcija
                    if let dragging = topologyViewElement.draggingConnection {
                        if let targetComponent = ComponentPositionManager.findComponent(
                            at: value.location,
                            in: topologyViewElement.topologyElement.topology.components,
                            geometry: geometry,
                            exclude: dragging.from
                        ) {
                            let targetCenter = ComponentPositionManager.getAbsolutePosition(for: targetComponent, in: geometry)
                            if let connectionPoint = ConnectionPointDetector.detect(at: value.location, componentCenter: targetCenter) {
                                // Klik na pin drugog komponenta - završi konekciju
                                let pinPosition = ConnectionPointDetector.position(for: connectionPoint, componentCenter: targetCenter)
                                topologyViewElement.handleConnectionDragEnd(pinPosition, geometry: geometry)
                                return
                            }
                        }
                        // Klik negdje drugdje ili puštanje - završi konekciju
                        topologyViewElement.handleConnectionDragEnd(value.location, geometry: geometry)
                    }
                    
                    if topologyViewElement.connectingFrom != nil {
                        topologyViewElement.connectingFrom = nil
                    }
                }
        )
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
                onDrag: { comp, location in topologyViewElement.handleComponentDragEnd(comp, finalPosition: location, geometry: geometry) },
                onConnectionDragStart: { comp, start, current in topologyViewElement.handleConnectionDragStart(comp, fromPoint: start, toPoint: current, geometry: geometry) },
                onConnectionDragUpdate: { location in topologyViewElement.handleConnectionDragUpdate(location, geometry: geometry) },
                onPinClick: { comp, point, position in topologyViewElement.handlePinClick(comp, connectionPoint: point, pinPosition: position) },
                onDragUpdate: { comp, location in 
                    topologyViewElement.handleComponentDragUpdate(comp, location: location, geometry: geometry)
                },
                onDelete: { comp in topologyViewElement.deleteComponent(comp) }
            )
        }
    }
    
    private var connectionsLayer: some View {
        ForEach(topologyViewElement.topologyElement.topology.connections) { connection in
            ConnectionView(
                connection: connection,
                topology: topologyViewElement.topologyElement.topology,
                geometry: geometry,
                onDelete: { conn in topologyViewElement.topologyElement.removeConnection(conn) }
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



