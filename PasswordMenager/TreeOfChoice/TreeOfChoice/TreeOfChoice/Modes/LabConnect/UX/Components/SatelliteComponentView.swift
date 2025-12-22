//
//  SatelliteComponentView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit

/// View za Satellite (User) komponentu
struct SatelliteComponentView: View {
    @ObservedObject var component: NetworkComponent
    var iconColor: Color? = nil
    var pinColor: Color? = nil
    var hoveredPoint: ConnectionPoint? = nil
    
    var body: some View {
        // Koristi base NetworkComponentView sa custom logikom za Satellite
        NetworkComponentView(
            component: component,
            iconColor: iconColor,
            pinColor: pinColor,
            hoveredPoint: hoveredPoint
        )
    }
}
