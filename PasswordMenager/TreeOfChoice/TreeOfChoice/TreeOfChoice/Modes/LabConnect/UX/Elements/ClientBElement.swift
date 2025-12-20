//
//  ClientBElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Element koji predstavlja Client B
/// Odgovoran za prikaz i upravljanje Client B komponentom
class ClientBElement: ObservableObject {
    @Published var component: NetworkComponent
    
    init(component: NetworkComponent? = nil) {
        if let component = component {
            self.component = component
        } else {
            self.component = NetworkComponent(
                componentType: .laptop,
                position: .zero,
                name: "Client B",
                isClientA: nil,
                isClientB: true
            )
        }
    }
    
    func changeType(to type: NetworkComponent.ComponentType) {
        guard type.canBeClient else { return }
        component.componentType = type
        component.name = "Client B"
        component.objectWillChange.send()
    }
}

/// View wrapper za ClientBElement
struct ClientBElementView: View {
    @ObservedObject var clientBElement: ClientBElement
    let geometry: GeometryProxy
    let topology: NetworkTopology
    let simulation: NetworkSimulation
    let onTap: (NetworkComponent) -> Void
    let connectingFrom: NetworkComponent?
    let hoveredPoint: ConnectionPoint?
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    let onPinClick: ((NetworkComponent, ConnectionPoint, CGPoint) -> Void)?
    let onConnectionDragUpdate: ((CGPoint) -> Void)?
    
    var body: some View {
        ClientComponentView(
            component: clientBElement.component,
            topology: topology,
            simulation: simulation,
            geometry: geometry,
            x: geometry.size.width - 65,
            y: geometry.size.height - 80,
            connectingFrom: connectingFrom,
            hoveredPoint: hoveredPoint,
            onTypeChange: { _, type in clientBElement.changeType(to: type) },
            onTap: onTap,
            onConnectionDragStart: onConnectionDragStart,
            onPinClick: onPinClick,
            onConnectionDragUpdate: onConnectionDragUpdate
        )
    }
}


