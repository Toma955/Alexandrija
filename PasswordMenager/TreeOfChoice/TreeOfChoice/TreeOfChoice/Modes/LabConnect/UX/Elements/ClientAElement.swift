//
//  ClientAElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Element koji predstavlja Client A
/// Odgovoran za prikaz i upravljanje Client A komponentom
class ClientAElement: ObservableObject {
    @Published var component: NetworkComponent
    
    init(component: NetworkComponent? = nil) {
        if let component = component {
            self.component = component
        } else {
            self.component = NetworkComponent(
                componentType: .laptop,
                position: .zero,
                name: "Client A",
                isClientA: true,
                isClientB: nil
            )
        }
    }
    
    func changeType(to type: NetworkComponent.ComponentType) {
        guard type.canBeClient else { return }
        component.componentType = type
        component.name = "Client A"
        component.objectWillChange.send()
    }
}

/// View wrapper za ClientAElement
struct ClientAElementView: View {
    @ObservedObject var clientAElement: ClientAElement
    let geometry: GeometryProxy
    let topology: NetworkTopology
    let simulation: NetworkSimulation
    let onTap: (NetworkComponent) -> Void
    let connectingFrom: NetworkComponent?
    let hoveredPoint: ConnectionPoint?
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    
    var body: some View {
        ClientComponentView(
            component: clientAElement.component,
            topology: topology,
            simulation: simulation,
            geometry: geometry,
            x: 65,
            y: geometry.size.height - 80,
            connectingFrom: connectingFrom,
            hoveredPoint: hoveredPoint,
            onTypeChange: { _, type in clientAElement.changeType(to: type) },
            onTap: onTap,
            onConnectionDragStart: onConnectionDragStart
        )
    }
}


