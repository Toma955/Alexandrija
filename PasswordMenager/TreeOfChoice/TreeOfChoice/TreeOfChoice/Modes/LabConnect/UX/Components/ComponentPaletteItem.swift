//
//  ComponentPaletteItem.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ComponentPaletteItem: View {
    let componentType: NetworkComponent.ComponentType
    
    // Podijeli naziv na riječi za prikaz u 2 reda
    private var nameLines: [String] {
        let name = componentType.displayName
        let words = name.split(separator: " ")
        
        if words.count <= 1 {
            return [name]
        } else if words.count == 2 {
            return [String(words[0]), String(words[1])]
        } else {
            // Ako ima više riječi, podijeli na pola
            let midPoint = words.count / 2
            let firstLine = words.prefix(midPoint).joined(separator: " ")
            let secondLine = words.suffix(from: midPoint).joined(separator: " ")
            return [firstLine, secondLine]
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: ComponentIconHelper.icon(for: componentType))
                .font(.title2)
                .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.0)) // Orange color
                .frame(width: 40, height: 40)
            
            // Naziv u 2 reda
            VStack(spacing: 2) {
                ForEach(Array(nameLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 70)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

