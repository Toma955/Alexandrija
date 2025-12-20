//
//  ZoneElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Element koji predstavlja zonu (Client A, Client B, ili Middle)
/// Odgovoran za prikaz i upravljanje zonama
enum ZoneType {
    case clientA
    case clientB
    case middle
}

class ZoneElement: ObservableObject {
    @Published var zoneType: ZoneType
    @Published var width: CGFloat
    @Published var isActive: Bool = true
    
    init(zoneType: ZoneType, width: CGFloat = 110) {
        self.zoneType = zoneType
        self.width = width
    }
    
    var color: Color {
        switch zoneType {
        case .clientA:
            return Color(red: 0.0, green: 0.2, blue: 1.0) // Blue
        case .clientB:
            return Color(red: 0.0, green: 0.9, blue: 0.1) // Green
        case .middle:
            return Color(red: 1.0, green: 0.36, blue: 0.0) // Orange
        }
    }
    
    var title: String {
        switch zoneType {
        case .clientA:
            return "Client A"
        case .clientB:
            return "Client B"
        case .middle:
            return "Topology"
        }
    }
}

/// View wrapper za ZoneElement - prikazuje zonu s Client A ili Client B unutar nje
struct ZoneElementView: View {
    @ObservedObject var zoneElement: ZoneElement
    let geometry: GeometryProxy
    let clientComponent: NetworkComponent?
    let topology: NetworkTopology
    let simulation: NetworkSimulation
    let connectingFrom: NetworkComponent?
    let hoveredConnectionPoint: (component: NetworkComponent, point: ConnectionPoint)?
    let onClientTap: (NetworkComponent) -> Void
    let onClientTypeChange: (NetworkComponent, NetworkComponent.ComponentType) -> Void
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    
    // Calculate client position: 2/3 of window height, centered in bottom half of zone
    private var clientHeight: CGFloat {
        geometry.size.height * (2.0 / 3.0)
    }
    
    private var clientY: CGFloat {
        // Bottom half starts at 50% of height
        let bottomHalfStart = geometry.size.height * 0.5
        // Center client vertically in bottom half
        let bottomHalfHeight = geometry.size.height * 0.5
        let padding: CGFloat = 20
        // Position in center of bottom half, with padding from bottom
        return bottomHalfStart + (bottomHalfHeight / 2) - padding
    }
    
    private var clientX: CGFloat {
        // Center client horizontally in zone
        let padding: CGFloat = 10
        if zoneElement.zoneType == .clientA {
            // Center in Client A zone (left zone, width: 130)
            return padding + (zoneElement.width / 2)
        } else {
            // Center in Client B zone (right zone, width: 130)
            // Zone starts at (geometry.size.width - padding - zoneElement.width)
            return (geometry.size.width - padding - zoneElement.width) + (zoneElement.width / 2)
        }
    }
    
    var body: some View {
        ZStack {
            // Zone background
            VStack(spacing: 8) {
                Text(zoneElement.title)
                    .font(.headline.bold())
                    .foregroundColor(zoneElement.color)
                    .padding(.top, 8)
                
                Spacer()
            }
            .frame(width: zoneElement.width)
            .frame(maxHeight: .infinity)
            .background(zoneElement.color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(zoneElement.color, style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
            
            // Client component positioned in corner
            if let client = clientComponent {
                ClientComponentView(
                    component: client,
                    topology: topology,
                    simulation: simulation,
                    geometry: geometry,
                    x: clientX,
                    y: clientY,
                    connectingFrom: connectingFrom,
                    hoveredPoint: hoveredConnectionPoint?.component.id == client.id ? hoveredConnectionPoint?.point : nil,
                    onTypeChange: onClientTypeChange,
                    onTap: onClientTap,
                    onConnectionDragStart: onConnectionDragStart
                )
            }
        }
        .contentShape(Rectangle())
    }
}

