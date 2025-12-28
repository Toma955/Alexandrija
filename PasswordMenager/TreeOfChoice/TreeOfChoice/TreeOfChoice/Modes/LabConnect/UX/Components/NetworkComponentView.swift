//
//  NetworkComponentView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit
import Combine

/// Wrapper view koji koristi BaseComponentTopologyView
/// Održava kompatibilnost s postojećim kodom
struct NetworkComponentView: View {
    @ObservedObject var component: NetworkComponent
    var topology: NetworkTopology? = nil
    var iconColor: Color? = nil
    var pinColor: Color? = nil
    var hoveredPoint: ConnectionPoint? = nil
    var onIconTap: (() -> Void)? = nil
    var isTestMode: Bool = false
    var isEditMode: Bool = false
    
    var body: some View {
        BaseComponentTopologyView(
            component: component,
            topology: topology,
            iconColor: iconColor,
            pinColor: pinColor,
            hoveredPoint: hoveredPoint,
            onIconTap: onIconTap,
            isTestMode: isTestMode,
            isEditMode: isEditMode,
            displayable: nil
        )
    }
}

