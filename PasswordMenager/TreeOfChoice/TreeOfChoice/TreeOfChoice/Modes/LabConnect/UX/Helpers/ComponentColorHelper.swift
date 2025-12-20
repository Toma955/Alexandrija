//
//  ComponentColorHelper.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ComponentColorHelper {
    static func color(for type: NetworkComponent.ComponentType) -> Color {
        switch type.category {
        case .client: return .blue
        case .infrastructure: return .green
        case .security: return .red
        case .nilternius: return Color(red: 1.0, green: 0.36, blue: 0.0)
        default: return .gray
        }
    }
}

