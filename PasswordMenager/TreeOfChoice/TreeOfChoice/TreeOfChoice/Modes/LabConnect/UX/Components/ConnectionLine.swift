//
//  ConnectionLine.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let type: NetworkConnection.ConnectionType
    var isTestMode: Bool = false // Test mode - narančasta boja
    
    var body: some View {
        // Obična linija
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(lineColor, style: strokeStyle)
    }
    
    // All connections are gray initially, narančasta u test modu
    private var lineColor: Color {
        if isTestMode {
            return Color(red: 1.0, green: 0.36, blue: 0.0) // Narančasta boja
        }
        return Color.gray
    }
    
    private var strokeStyle: StrokeStyle {
        switch type {
        case .wireless:
            return StrokeStyle(lineWidth: 4, dash: [5, 5])
        default:
            return StrokeStyle(lineWidth: 4)
        }
    }
}

