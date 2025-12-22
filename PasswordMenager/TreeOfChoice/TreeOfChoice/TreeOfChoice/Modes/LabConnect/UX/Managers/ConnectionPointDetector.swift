//
//  ConnectionPointDetector.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

// ConnectionPoint enum je sada u Shared/NetworkTopology/Models/ConnectionPoint.swift

struct ConnectionPointDetector {
    static func detect(at location: CGPoint, componentCenter: CGPoint) -> ConnectionPoint? {
        let connectionPointDistance: CGFloat = 45
        let hitRadius: CGFloat = 20 // Radius za prikaz pinova - miš mora biti jako blizu (smanjeno sa 25 na 20)
        
        // Izračunaj pozicije svakog connection pointa
        let topPoint = CGPoint(x: componentCenter.x, y: componentCenter.y - connectionPointDistance)
        let bottomPoint = CGPoint(x: componentCenter.x, y: componentCenter.y + connectionPointDistance)
        let leftPoint = CGPoint(x: componentCenter.x - connectionPointDistance, y: componentCenter.y)
        let rightPoint = CGPoint(x: componentCenter.x + connectionPointDistance, y: componentCenter.y)
        
        // Izračunaj euklidsku udaljenost od lokacije do svakog connection pointa
        func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
            let dx = p1.x - p2.x
            let dy = p1.y - p2.y
            return sqrt(dx * dx + dy * dy)
        }
        
        let topDistance = distance(location, topPoint)
        let bottomDistance = distance(location, bottomPoint)
        let leftDistance = distance(location, leftPoint)
        let rightDistance = distance(location, rightPoint)
        
        // Pronađi najbliži connection point
        let distances: [(CGFloat, ConnectionPoint)] = [
            (topDistance, .top),
            (bottomDistance, .bottom),
            (leftDistance, .left),
            (rightDistance, .right)
        ]
        
        if let closest = distances.min(by: { $0.0 < $1.0 }), closest.0 < hitRadius {
            return closest.1
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

