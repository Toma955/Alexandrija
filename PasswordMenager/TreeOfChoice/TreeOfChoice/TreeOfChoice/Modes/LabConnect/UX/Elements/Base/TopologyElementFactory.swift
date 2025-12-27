//
//  TopologyElementFactory.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Factory za kreiranje TopologyElement objekata
/// Automatski određuje da li element treba biti AreaTopologyElement ili RegularTopologyElement
class TopologyElementFactory {
    
    /// Kreira TopologyElement za dani NetworkComponent
    /// Automatski određuje tip na temelju naziva komponente
    static func createElement(
        for component: NetworkComponent,
        visibility: ElementVisibility = .public,
        topology: NetworkTopology? = nil
    ) -> BaseTopologyElement {
        // Provjeri da li komponenta ima "Area" u nazivu
        let hasArea = component.componentType.rawValue.lowercased().contains("area")
        
        if hasArea {
            // Kreiraj AreaTopologyElement
            return AreaTopologyElement(
                component: component,
                visibility: visibility,
                topology: topology,
                areaWidth: component.areaWidth,
                areaHeight: component.areaHeight
            )
        } else {
            // Kreiraj RegularTopologyElement
            return RegularTopologyElement(
                component: component,
                visibility: visibility,
                topology: topology
            )
        }
    }
    
    /// Kreira TopologyElement za ClientZone
    static func createClientZone(
        component: NetworkComponent? = nil,
        zoneType: ClientZoneType,
        width: CGFloat = 90,
        topLeftGrid: CGPoint? = nil,
        topRightGrid: CGPoint? = nil,
        bottomLeftGrid: CGPoint? = nil,
        bottomRightGrid: CGPoint? = nil
    ) -> ClientZone {
        return ClientZone(
            component: component,
            zoneType: zoneType,
            width: width,
            topLeftGrid: topLeftGrid,
            topRightGrid: topRightGrid,
            bottomLeftGrid: bottomLeftGrid,
            bottomRightGrid: bottomRightGrid
        )
    }
}

