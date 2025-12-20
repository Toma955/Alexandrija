//
//  ComponentPositionManager.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ComponentPositionManager {
    static func getAbsolutePosition(for component: NetworkComponent, in geometry: GeometryProxy) -> CGPoint {
        let zoneWidth: CGFloat = 110
        let padding: CGFloat = 10
        
        if component.isClientA == true {
            // Client A: centered in zone, in bottom half
            let bottomHalfStart = geometry.size.height * 0.5
            let bottomHalfHeight = geometry.size.height * 0.5
            let verticalPadding: CGFloat = 20
            let y = bottomHalfStart + (bottomHalfHeight / 2) - verticalPadding
            let x = padding + (zoneWidth / 2) // Center of Client A zone with padding
            return CGPoint(x: x, y: y)
        } else if component.isClientB == true {
            // Client B: centered in zone, in bottom half
            let bottomHalfStart = geometry.size.height * 0.5
            let bottomHalfHeight = geometry.size.height * 0.5
            let verticalPadding: CGFloat = 20
            let y = bottomHalfStart + (bottomHalfHeight / 2) - verticalPadding
            let x = (geometry.size.width - padding - zoneWidth) + (zoneWidth / 2) // Center of Client B zone with padding
            return CGPoint(x: x, y: y)
        } else {
            // Other components in middle area - position is relative to middle area start (padding + zoneWidth)
            let middleAreaStart = padding + zoneWidth
            let absoluteX: CGFloat
            if component.position.x < 0 {
                // Component is in Client A zone (negative offset)
                absoluteX = middleAreaStart + component.position.x
            } else if component.position.x > geometry.size.width - (padding * 2) - (zoneWidth * 2) {
                // Component is in Client B zone
                let offsetFromB = component.position.x - (geometry.size.width - (padding * 2) - (zoneWidth * 2))
                absoluteX = geometry.size.width - padding - zoneWidth + offsetFromB
            } else {
                // Component is in middle area
                absoluteX = middleAreaStart + component.position.x
            }
            
            return CGPoint(x: absoluteX, y: component.position.y)
        }
    }
    
    static func calculateRelativePosition(absoluteX: CGFloat, absoluteY: CGFloat, geometry: GeometryProxy) -> CGPoint {
        let zoneWidth: CGFloat = 110
        let padding: CGFloat = 10
        let middleAreaStart = padding + zoneWidth
        
        let relativeX: CGFloat
        if absoluteX <= padding + zoneWidth {
            // In Client A zone - store as negative offset from middleAreaStart
            relativeX = absoluteX - middleAreaStart
        } else if absoluteX >= geometry.size.width - padding - zoneWidth {
            // In Client B zone - store as offset from width-padding-zoneWidth
            relativeX = absoluteX - (geometry.size.width - padding - zoneWidth) + (geometry.size.width - (padding * 2) - (zoneWidth * 2))
        } else {
            // In middle area
            relativeX = absoluteX - middleAreaStart
        }
        
        return CGPoint(x: relativeX, y: absoluteY)
    }
    
    static func findComponent(at location: CGPoint, in components: [NetworkComponent], geometry: GeometryProxy, exclude: NetworkComponent? = nil) -> NetworkComponent? {
        let hitRadius: CGFloat = 50
        
        for component in components {
            if let exclude = exclude, component.id == exclude.id { continue }
            
            let componentPos = getAbsolutePosition(for: component, in: geometry)
            let distance = sqrt(
                pow(location.x - componentPos.x, 2) +
                pow(location.y - componentPos.y, 2)
            )
            
            if distance < hitRadius {
                return component
            }
        }
        
        return nil
    }
}

