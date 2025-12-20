//
//  ComponentPaletteItem.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ComponentPaletteItem: View {
    let componentType: NetworkComponent.ComponentType
    
    // Split name into 2 lines
    private var nameLines: [String] {
        let name = componentType.displayName
        let words = name.split(separator: " ")
        if words.count <= 1 {
            return [name]
        }
        let midPoint = words.count / 2
        let firstLine = words.prefix(midPoint).joined(separator: " ")
        let secondLine = words.suffix(from: midPoint).joined(separator: " ")
        return [firstLine, secondLine]
    }

    var body: some View {
        // Standard layout for all components (including DNS and DHCP servers)
        VStack(spacing: 3) {
            Image(systemName: ComponentIconHelper.icon(for: componentType))
                .font(.title2) // Povećano sa .title3 na .title2
                .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.0)) // Orange color
                .frame(width: 40, height: 40) // Povećano sa 32x32 na 40x40

            // Name in 2 lines
            VStack(spacing: 2) {
                ForEach(Array(nameLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Poštuj frame dimenzije
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(Color.black.opacity(0.3)) // Crna boja umjesto sive
        .cornerRadius(6)
    }
}

