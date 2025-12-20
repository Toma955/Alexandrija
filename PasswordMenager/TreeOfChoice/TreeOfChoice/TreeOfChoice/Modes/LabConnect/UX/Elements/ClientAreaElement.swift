//
//  ClientAreaElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Element koji predstavlja Client Area - parent element koji sadrži Client A i Client B
/// Odgovoran za upravljanje područjem klijenata i njihovim pozicioniranjem
/// Koristi ClientZone objekte koji slijede OOP principe
class ClientAreaElement: ObservableObject {
    @Published var clientAZone: ClientZone
    @Published var clientBZone: ClientZone
    @Published var width: CGFloat = 90 // Width per client zone (smanjeno sa 110 na 90)
    @Published var height: CGFloat = 0 // Calculated based on window
    @Published var position: CGPoint = .zero
    @Published var isVisible: Bool = true
    
    init(clientA: NetworkComponent? = nil, clientB: NetworkComponent? = nil) {
        // Client A - default grid koordinate: lijevo, gore
        let clientATopLeft = CGPoint(x: 0, y: 2) // Grid koordinata (0, 2)
        let clientAGridWidth: CGFloat = 4 // 4 grid jedinice širine (4 * 20px = 80px, ali width je 90px)
        let clientATopRight = CGPoint(x: clientATopLeft.x + clientAGridWidth, y: clientATopLeft.y)
        let clientAHeight: CGFloat = 20 // 20 grid jedinica visine
        let clientABottomLeft = CGPoint(x: clientATopLeft.x, y: clientATopLeft.y + clientAHeight)
        let clientABottomRight = CGPoint(x: clientATopRight.x, y: clientABottomLeft.y)
        
        // Client B - default grid koordinate: desno, gore (izračunat će se dinamički u view-u)
        // Za sada postavljamo default, ali će se ažurirati u view-u na temelju geometry.size.width
        let clientBTopLeft = CGPoint(x: 0, y: 2) // Privremeno, ažurira se u view-u
        let clientBGridWidth: CGFloat = 4
        let clientBTopRight = CGPoint(x: clientBTopLeft.x + clientBGridWidth, y: clientBTopLeft.y)
        let clientBHeight: CGFloat = 20
        let clientBBottomLeft = CGPoint(x: clientBTopLeft.x, y: clientBTopLeft.y + clientBHeight)
        let clientBBottomRight = CGPoint(x: clientBTopRight.x, y: clientBBottomLeft.y)
        
        self.clientAZone = ClientZone(
            component: clientA, 
            zoneType: .clientA, 
            width: 90,
            topLeftGrid: clientATopLeft,
            topRightGrid: clientATopRight,
            bottomLeftGrid: clientABottomLeft,
            bottomRightGrid: clientABottomRight
        )
        self.clientBZone = ClientZone(
            component: clientB, 
            zoneType: .clientB, 
            width: 90,
            topLeftGrid: clientBTopLeft,
            topRightGrid: clientBTopRight,
            bottomLeftGrid: clientBBottomLeft,
            bottomRightGrid: clientBBottomRight
        )
    }
    
    func setSize(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        clientAZone.width = width
        clientBZone.width = width
    }
    
    func setPosition(_ position: CGPoint) {
        self.position = position
    }
    
    func updateClientA(_ component: NetworkComponent) {
        clientAZone.updateComponent(component)
    }
    
    func updateClientB(_ component: NetworkComponent) {
        clientBZone.updateComponent(component)
    }
}

/// View wrapper za ClientAreaElement - prikazuje Client Area s Client A i Client B unutar
/// Koristi ClientZoneView koji slijedi OOP principe
struct ClientAreaElementView: View {
    @ObservedObject var clientAreaElement: ClientAreaElement
    let geometry: GeometryProxy
    let topology: NetworkTopology
    let simulation: NetworkSimulation
    let connectingFrom: NetworkComponent?
    let hoveredConnectionPoint: (component: NetworkComponent, point: ConnectionPoint)?
    let onClientTap: (NetworkComponent) -> Void
    let onClientTypeChange: (NetworkComponent, NetworkComponent.ComponentType) -> Void
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    
    var body: some View {
        if clientAreaElement.isVisible {
            ZStack {
                // Client A Zone - pozicioniran prema grid koordinatama
                ClientZoneView(
                    clientZone: clientAreaElement.clientAZone,
                    geometry: geometry,
                    topology: topology,
                    simulation: simulation,
                    connectingFrom: connectingFrom,
                    hoveredConnectionPoint: hoveredConnectionPoint,
                    onClientTap: onClientTap,
                    onClientTypeChange: onClientTypeChange,
                    onConnectionDragStart: onConnectionDragStart,
                    onResize: { newWidth in
                        clientAreaElement.width = newWidth
                        clientAreaElement.clientAZone.width = newWidth
                    }
                )
                
                // Client B Zone - pozicioniran prema grid koordinatama
                ClientZoneView(
                    clientZone: clientAreaElement.clientBZone,
                    geometry: geometry,
                    topology: topology,
                    simulation: simulation,
                    connectingFrom: connectingFrom,
                    hoveredConnectionPoint: hoveredConnectionPoint,
                    onClientTap: onClientTap,
                    onClientTypeChange: onClientTypeChange,
                    onConnectionDragStart: onConnectionDragStart,
                    onResize: { newWidth in
                        clientAreaElement.width = newWidth
                        clientAreaElement.clientBZone.width = newWidth
                    }
                )
            }
            .onAppear {
                // Ažuriraj grid koordinate za Client B na temelju geometry.size.width
                updateClientBGridCoordinates(geometry: geometry)
            }
            .onChange(of: geometry.size.width) { _ in
                // Ažuriraj koordinate kada se promijeni širina
                updateClientBGridCoordinates(geometry: geometry)
            }
        }
    }
    
    private func updateClientBGridCoordinates(geometry: GeometryProxy) {
        let clientBGridWidth = Int(clientAreaElement.clientBZone.width / GridSnapHelper.gridSpacing)
        let totalGridCols = Int(geometry.size.width / GridSnapHelper.gridSpacing)
        let clientBTopLeftX = CGFloat(totalGridCols - clientBGridWidth)
        
        // Ažuriraj Client B koordinate ako se promijenio layout
        if clientAreaElement.clientBZone.topLeftGrid.x != clientBTopLeftX {
            let clientBTopLeft = CGPoint(x: clientBTopLeftX, y: clientAreaElement.clientBZone.topLeftGrid.y)
            let clientBTopRight = CGPoint(x: clientBTopLeft.x + CGFloat(clientBGridWidth), y: clientBTopLeft.y)
            let clientBHeight = clientAreaElement.clientBZone.bottomLeftGrid.y - clientAreaElement.clientBZone.topLeftGrid.y
            let clientBBottomLeft = CGPoint(x: clientBTopLeft.x, y: clientBTopLeft.y + clientBHeight)
            let clientBBottomRight = CGPoint(x: clientBTopRight.x, y: clientBBottomLeft.y)
            
            clientAreaElement.clientBZone.topLeftGrid = clientBTopLeft
            clientAreaElement.clientBZone.topRightGrid = clientBTopRight
            clientAreaElement.clientBZone.bottomLeftGrid = clientBBottomLeft
            clientAreaElement.clientBZone.bottomRightGrid = clientBBottomRight
        }
    }
}

