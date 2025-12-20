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
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(lineColor, style: strokeStyle)
    }
    
    // All connections are gray initially
    private var lineColor: Color {
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

