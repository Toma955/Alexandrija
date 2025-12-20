//
//  GridBackgroundView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct GridBackgroundView: View {
    let geometry: GeometryProxy
    let clientAZone: ClientZone? // Dinamičke vrijednosti za Client A (opcionalno)
    let clientBZone: ClientZone? // Dinamičke vrijednosti za Client B (opcionalno)
    
    private let spacing: CGFloat = 20 // Gušća mreža
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    private let clientAColor = Color(red: 0.0, green: 0.2, blue: 1.0) // Blue
    private let clientBColor = Color(red: 0.0, green: 0.9, blue: 0.1) // Green
    
    init(geometry: GeometryProxy, clientAZone: ClientZone? = nil, clientBZone: ClientZone? = nil) {
        self.geometry = geometry
        self.clientAZone = clientAZone
        self.clientBZone = clientBZone
    }
    
    var body: some View {
        ZStack {
            // Draw plus signs at grid intersections
            // Dodajemo 2 dodatna reda koji će izaći izvan okvira (neće se prikazati zbog clippinga)
            let extraRows = 2
            let totalRows = Int(geometry.size.height / spacing) + extraRows
            let totalCols = Int(geometry.size.width / spacing) + extraRows
            
            ForEach(0..<totalCols, id: \.self) { xIndex in
                ForEach(0..<totalRows, id: \.self) { yIndex in
                    let x = CGFloat(xIndex) * spacing
                    let y = CGFloat(yIndex) * spacing
                    
                    // Determine color based on zone - koristi grid koordinate
                    let gridX = CGFloat(xIndex)
                    let gridY = CGFloat(yIndex)
                    let plusColor = colorForPosition(gridX: gridX, gridY: gridY)
                    
                    // Plus sign
                    Path { path in
                        let size: CGFloat = 4
                        // Horizontal line
                        path.move(to: CGPoint(x: x - size, y: y))
                        path.addLine(to: CGPoint(x: x + size, y: y))
                        // Vertical line
                        path.move(to: CGPoint(x: x, y: y - size))
                        path.addLine(to: CGPoint(x: x, y: y + size))
                    }
                    .stroke(plusColor.opacity(0.3), lineWidth: 1)
                }
            }
        }
        .clipped() // Osigurava da se mreža izvan okvira ne prikazuje
    }
    
    private func colorForPosition(gridX: CGFloat, gridY: CGFloat) -> Color {
        // Provjeri da li je grid koordinata unutar Client A zone
        if let clientA = clientAZone {
            let clientATopLeftX = clientA.topLeftGrid.x
            let clientATopRightX = clientA.topRightGrid.x
            let clientATopLeftY = clientA.topLeftGrid.y
            let clientABottomLeftY = clientA.bottomLeftGrid.y
            
            if gridX >= clientATopLeftX && gridX <= clientATopRightX &&
               gridY >= clientATopLeftY && gridY <= clientABottomLeftY {
                return clientA.color
            }
        }
        
        // Provjeri da li je grid koordinata unutar Client B zone
        if let clientB = clientBZone {
            let clientBTopLeftX = clientB.topLeftGrid.x
            let clientBTopRightX = clientB.topRightGrid.x
            let clientBTopLeftY = clientB.topLeftGrid.y
            let clientBBottomLeftY = clientB.bottomLeftGrid.y
            
            if gridX >= clientBTopLeftX && gridX <= clientBTopRightX &&
               gridY >= clientBTopLeftY && gridY <= clientBBottomLeftY {
                return clientB.color
            }
        }
        
        // Middle area - orange
        return accentOrange
    }
}

