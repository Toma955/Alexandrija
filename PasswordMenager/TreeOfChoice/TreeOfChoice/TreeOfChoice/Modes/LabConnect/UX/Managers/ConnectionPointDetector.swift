//
//  ConnectionPointDetector.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

enum ConnectionPoint {
    case top, bottom, left, right
}

struct ConnectionPointDetector {
    static func detect(at location: CGPoint, componentCenter: CGPoint) -> ConnectionPoint? {
        let connectionPointDistance: CGFloat = 45
        let hitRadius: CGFloat = 15
        
        let dx = location.x - componentCenter.x
        let dy = location.y - componentCenter.y
        
        // Check each direction
        if abs(dy + connectionPointDistance) < hitRadius && abs(dx) < hitRadius {
            return .top
        } else if abs(dy - connectionPointDistance) < hitRadius && abs(dx) < hitRadius {
            return .bottom
        } else if abs(dx + connectionPointDistance) < hitRadius && abs(dy) < hitRadius {
            return .left
        } else if abs(dx - connectionPointDistance) < hitRadius && abs(dy) < hitRadius {
            return .right
        }
        
        return nil
    }
    
    static func position(for point: ConnectionPoint, componentCenter: CGPoint) -> CGPoint {
        let distance: CGFloat = 45
        switch point {
        case .top:
            return CGPoint(x: componentCenter.x, y: componentCenter.y - distance)
        case .bottom:
            return CGPoint(x: componentCenter.x, y: componentCenter.y + distance)
        case .left:
            return CGPoint(x: componentCenter.x - distance, y: componentCenter.y)
        case .right:
            return CGPoint(x: componentCenter.x + distance, y: componentCenter.y)
        }
    }
    
    static func closestPoint(from center: CGPoint, to location: CGPoint) -> CGPoint {
        let connectionPointDistance: CGFloat = 45
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0 else {
            return CGPoint(x: center.x, y: center.y - connectionPointDistance)
        }
        
        let normalizedDx = dx / distance
        let normalizedDy = dy / distance
        
        return CGPoint(
            x: center.x + normalizedDx * connectionPointDistance,
            y: center.y + normalizedDy * connectionPointDistance
        )
    }
}

