//
//  ClientView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Nova ClientView komponenta - kvadrat unutar lijevog i desnog područja
/// Pozicioniran: 10px od bijele vertikalne linije, 5px od ruba ekrana
struct ClientView: View {
    @ObservedObject var component: NetworkComponent
    @ObservedObject var topology: NetworkTopology
    @ObservedObject var simulation: NetworkSimulation
    let geometry: GeometryProxy
    let isLeftSide: Bool // true za lijevu stranu, false za desnu
    let connectingFrom: NetworkComponent?
    let hoveredPoint: ConnectionPoint?
    let onTypeChange: (NetworkComponent, NetworkComponent.ComponentType) -> Void
    let onTap: (NetworkComponent) -> Void
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    let onPinClick: ((NetworkComponent, ConnectionPoint, CGPoint) -> Void)?
    let onConnectionDragUpdate: ((CGPoint) -> Void)?
    
    private let types: [NetworkComponent.ComponentType] = [.laptop, .desktop, .tablet, .mobile]
    private let marginFromDivider: CGFloat = 10 // 10px od bijele vertikalne linije
    private let marginFromEdge: CGFloat = 5 // 5px od ruba ekrana
    private let marginFromTop: CGFloat = 20 // 20px od gornjeg elementa
    private let dividerX: CGFloat = 300 // Pozicija bijele vertikalne linije
    
    // Širina i visina kvadrata - povećana veličina
    // Prostor između 5px od ruba i 10px od linije = 300 - 5 - 10 = 285px
    // Ali kvadrat može biti veći i centriran u tom prostoru
    private var squareSize: CGFloat {
        300 // Povećano sa 285px na 300px
    }
    
    var body: some View {
        // Siva boja za oba klijenta
        let iconColor: Color = .gray
        
        let currentIndex = types.firstIndex(of: component.componentType) ?? 0
        let nextType = types[(currentIndex + 1) % types.count]
        
        // Izračunaj poziciju
        let (x, y) = calculatePosition()
        let componentCenter = CGPoint(x: x, y: y)
        
        return NetworkComponentView(
            component: component,
            topology: topology,
            iconColor: iconColor,
            hoveredPoint: hoveredPoint,
            onIconTap: {
                if connectingFrom == nil {
                    onTypeChange(component, nextType)
                } else {
                    onTap(component)
                }
            },
            isTestMode: false
        )
        .frame(width: squareSize, height: squareSize)
        .contentShape(Rectangle())
        .position(x: x, y: y)
        .zIndex(10) // Ensure it's on top
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    // Check if starting from connection point
                    let componentFrameCenter = CGPoint(x: squareSize / 2, y: squareSize / 2)
                    let startLocation = CGPoint(
                        x: x + (value.startLocation.x - componentFrameCenter.x),
                        y: y + (value.startLocation.y - componentFrameCenter.y)
                    )
                    
                    // Provjeri je li klik na connection point
                    if let connectionPoint = ConnectionPointDetector.detect(at: startLocation, componentCenter: componentCenter) {
                        let pinPosition = ConnectionPointDetector.position(for: connectionPoint, componentCenter: componentCenter)
                        let globalLocation = CGPoint(
                            x: x + (value.location.x - componentFrameCenter.x),
                            y: y + (value.location.y - componentFrameCenter.y)
                        )
                        
                        if onPinClick != nil {
                            onPinClick?(component, connectionPoint, pinPosition)
                        }
                        
                        onConnectionDragUpdate?(globalLocation)
                    }
                }
        )
    }
    
    private func calculatePosition() -> (x: CGFloat, y: CGFloat) {
        let screenWidth = geometry.size.width
        
        // Y pozicija - 20px od gornjeg elementa (header)
        // Header ima padding 24px i tekst, pa je oko 80-100px visine
        // Trebamo: header visina + 20px + polovica visine kvadrata
        let headerHeight: CGFloat = 100 // Približna visina headera
        let y = headerHeight + marginFromTop + (squareSize / 2) // header + 20px + polovica visine
        
        // X pozicija - točno 5px od ruba i 10px od linije
        let x: CGFloat
        if isLeftSide {
            // Lijevo područje: lijevi rub na 5px, desni rub na 290px (300 - 10)
            // Centar: 5 + (285 / 2) = 5 + 142.5 = 147.5px
            x = marginFromEdge + (squareSize / 2) // 5 + 142.5 = 147.5px
        } else {
            // Desno područje: lijevi rub na (width - 300 + 10) = width - 290, desni rub na width - 5
            // Centar: (width - 290) + (285 / 2) = width - 290 + 142.5 = width - 147.5px
            let leftEdge = (screenWidth - dividerX) + marginFromDivider // width - 300 + 10 = width - 290
            x = leftEdge + (squareSize / 2) // width - 290 + 142.5 = width - 147.5px
        }
        
        return (x: x, y: y)
    }
}

