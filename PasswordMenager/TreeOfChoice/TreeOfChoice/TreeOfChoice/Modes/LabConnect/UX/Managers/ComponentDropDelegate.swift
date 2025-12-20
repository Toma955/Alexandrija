//
//  ComponentDropDelegate.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ComponentDropDelegate: DropDelegate {
    let topology: NetworkTopology
    let geometry: GeometryProxy
    
    func performDrop(info: DropInfo) -> Bool {
        guard info.location.x >= 0 && info.location.x <= geometry.size.width else {
            return false
        }
        
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }
        
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            if let data = data as? Data,
               let typeString = String(data: data, encoding: .utf8),
               let componentType = NetworkComponent.ComponentType(rawValue: typeString) {
                
                DispatchQueue.main.async {
                    // Snap drop location to grid
                    let snappedLocation = GridSnapHelper.snapToGrid(info.location)
                    
                    let dropX = snappedLocation.x
                    let dropY = snappedLocation.y
                    let zoneWidth: CGFloat = 110
                    let padding: CGFloat = 10
                    let middleAreaStart = padding + zoneWidth
                    let relativeX: CGFloat
                    
                    if dropX <= padding + zoneWidth {
                        relativeX = dropX - middleAreaStart
                    } else if dropX >= geometry.size.width - padding - zoneWidth {
                        relativeX = dropX - (geometry.size.width - padding - zoneWidth) + (geometry.size.width - (padding * 2) - (zoneWidth * 2))
                    } else {
                        relativeX = dropX - middleAreaStart
                    }
                    
                    let newComponent = NetworkComponent(
                        componentType: componentType,
                        position: CGPoint(x: relativeX, y: dropY),
                        name: componentType.displayName
                    )
                    topology.components.append(newComponent)
                    topology.objectWillChange.send()
                }
            }
        }
        
        return true
    }
}

