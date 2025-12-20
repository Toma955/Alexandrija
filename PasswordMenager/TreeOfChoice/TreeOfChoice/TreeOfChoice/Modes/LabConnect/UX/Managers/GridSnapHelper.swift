//
//  GridSnapHelper.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Helper za snap-to-grid funkcionalnost
struct GridSnapHelper {
    static let gridSpacing: CGFloat = 20 // Spacing mreže
    
    /// Snap-uje poziciju na najbližu grid točku
    static func snapToGrid(_ point: CGPoint) -> CGPoint {
        let snappedX = round(point.x / gridSpacing) * gridSpacing
        let snappedY = round(point.y / gridSpacing) * gridSpacing
        return CGPoint(x: snappedX, y: snappedY)
    }
    
    /// Provjerava da li je pozicija na grid točki
    static func isOnGrid(_ point: CGPoint) -> Bool {
        let snapped = snapToGrid(point)
        return abs(point.x - snapped.x) < 0.1 && abs(point.y - snapped.y) < 0.1
    }
}

