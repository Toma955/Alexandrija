//
//  ConnectionManager.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ConnectionManager {
    static func getConnectionPoint(from: CGPoint, to: CGPoint, isFrom: Bool) -> CGPoint {
        let edgeOffset: CGFloat = 45
        
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0 else {
            return isFrom ? from : to
        }
        
        let normalizedDx = dx / distance
        let normalizedDy = dy / distance
        
        if isFrom {
            return CGPoint(
                x: from.x + normalizedDx * edgeOffset,
                y: from.y + normalizedDy * edgeOffset
            )
        } else {
            return CGPoint(
                x: to.x - normalizedDx * edgeOffset,
                y: to.y - normalizedDy * edgeOffset
            )
        }
    }
}

