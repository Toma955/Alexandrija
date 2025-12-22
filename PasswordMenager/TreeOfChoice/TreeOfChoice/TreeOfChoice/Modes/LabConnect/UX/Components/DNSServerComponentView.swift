//
//  DNSServerComponentView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit

/// View za DNS Server komponentu
struct DNSServerComponentView: View {
    @ObservedObject var component: NetworkComponent
    var iconColor: Color? = nil
    var pinColor: Color? = nil
    var hoveredPoint: ConnectionPoint? = nil
    
    var body: some View {
        NetworkComponentView(
            component: component,
            iconColor: iconColor,
            pinColor: pinColor,
            hoveredPoint: hoveredPoint
        )
    }
}
