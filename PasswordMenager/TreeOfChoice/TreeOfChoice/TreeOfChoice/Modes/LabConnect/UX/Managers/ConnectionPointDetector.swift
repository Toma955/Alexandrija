//
//  ConnectionPointDetector.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

enum ConnectionPoint: String, Codable, CaseIterable {
    case top, bottom, left, right
    case topLeft, topRight, bottomLeft, bottomRight
}

struct ConnectionPointDetector {
    static func detect(at location: CGPoint, componentCenter: CGPoint) -> ConnectionPoint? {
        let connectionPointDistance: CGFloat = 45
        let hitRadius: CGFloat = 20 // Radius za prikaz pinova - miš mora biti jako blizu (smanjeno sa 25 na 20)
        
        // Izračunaj euklidsku udaljenost od lokacije do svakog connection pointa
        func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
            let dx = p1.x - p2.x
            let dy = p1.y - p2.y
            return sqrt(dx * dx + dy * dy)
        }
        
        // Izračunaj pozicije svih connection pointova (uključujući kutne)
        let allPoints: [(CGPoint, ConnectionPoint)] = [
            (CGPoint(x: componentCenter.x, y: componentCenter.y - connectionPointDistance), .top),
            (CGPoint(x: componentCenter.x, y: componentCenter.y + connectionPointDistance), .bottom),
            (CGPoint(x: componentCenter.x - connectionPointDistance, y: componentCenter.y), .left),
            (CGPoint(x: componentCenter.x + connectionPointDistance, y: componentCenter.y), .right),
            (CGPoint(x: componentCenter.x - connectionPointDistance, y: componentCenter.y - connectionPointDistance), .topLeft),
            (CGPoint(x: componentCenter.x + connectionPointDistance, y: componentCenter.y - connectionPointDistance), .topRight),
            (CGPoint(x: componentCenter.x - connectionPointDistance, y: componentCenter.y + connectionPointDistance), .bottomLeft),
            (CGPoint(x: componentCenter.x + connectionPointDistance, y: componentCenter.y + connectionPointDistance), .bottomRight)
        ]
        
        // Pronađi najbliži connection point
        let distances: [(CGFloat, ConnectionPoint)] = allPoints.map { (point, connectionPoint) in
            (distance(location, point), connectionPoint)
        }
        
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
        case .topLeft:
            return CGPoint(x: componentCenter.x - distance, y: componentCenter.y - distance)
        case .topRight:
            return CGPoint(x: componentCenter.x + distance, y: componentCenter.y - distance)
        case .bottomLeft:
            return CGPoint(x: componentCenter.x - distance, y: componentCenter.y + distance)
        case .bottomRight:
            return CGPoint(x: componentCenter.x + distance, y: componentCenter.y + distance)
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

