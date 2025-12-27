//
//  ElementDisplayInfo.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Struktura koja sadrži sve informacije za prikaz elementa
/// Koristi se i u palette-i i na topologiji
struct ElementDisplayInfo {
    let icon: String
    let name: String
    let category: NetworkComponent.ComponentCategory
    let status: String
    let metadata: [String: Any]
    let hasArea: Bool
    let connectionCount: Int
    
    init(
        icon: String,
        name: String,
        category: NetworkComponent.ComponentCategory,
        status: String = "Ready",
        metadata: [String: Any] = [:],
        hasArea: Bool = false,
        connectionCount: Int = 0
    ) {
        self.icon = icon
        self.name = name
        self.category = category
        self.status = status
        self.metadata = metadata
        self.hasArea = hasArea
        self.connectionCount = connectionCount
    }
}

