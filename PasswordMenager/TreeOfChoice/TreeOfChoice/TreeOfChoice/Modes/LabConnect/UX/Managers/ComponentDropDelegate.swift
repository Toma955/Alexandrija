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
    var isTestMode: Bool = false // Test mode - onemogućava dodavanje komponenti
    
    func performDrop(info: DropInfo) -> Bool {
        // Ako je test mode aktivan, ne dozvoli dodavanje komponenti
        guard !isTestMode else {
            return false
        }
        
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
                    
                    // Provjeri je li Area komponenta
                    let isAreaComponent = componentType == .userArea ||
                                         componentType == .businessArea ||
                                         componentType == .businessPrivateArea ||
                                         componentType == .nilterniusArea
                    
                    // Za Area komponente, drop lokacija je centar (ne lijevi gornji kut)
                    // Za regularne komponente, drop lokacija je pozicija komponente
                    let relativeX: CGFloat
                    let relativeY: CGFloat
                    
                    if dropX <= padding + zoneWidth {
                        relativeX = dropX - middleAreaStart
                    } else if dropX >= geometry.size.width - padding - zoneWidth {
                        relativeX = dropX - (geometry.size.width - padding - zoneWidth) + (geometry.size.width - (padding * 2) - (zoneWidth * 2))
                    } else {
                        relativeX = dropX - middleAreaStart
                    }
                    
                    relativeY = dropY
                    
                    let newComponent = NetworkComponent(
                        componentType: componentType,
                        position: CGPoint(x: relativeX, y: relativeY),
                        name: componentType.displayName
                    )
                    
                    // Za Area komponente, postavi početnu veličinu ako nije postavljena
                    if isAreaComponent {
                        newComponent.areaWidth = 120
                        newComponent.areaHeight = 120
                    }
                    
                    // Provjeri constraints - ne dozvoli dodavanje u Client zone
                    // zoneWidth i padding su već definirane gore
                    let isInClientAZone = dropX <= padding + zoneWidth
                    let isInClientBZone = dropX >= geometry.size.width - padding - zoneWidth
                    
                    if isInClientAZone || isInClientBZone {
                        // Ne dozvoli dodavanje u Client zone
                        print("⚠️ Komponenta se ne može dodati u Client zone")
                        return
                    }
                    
                    // Koristi centraliziranu metodu za dodavanje komponente
                    let success = topology.addComponent(newComponent, allowInClientZones: false)
                    if !success {
                        print("⚠️ Neuspješno dodavanje komponente na topologiju")
                    }
                }
            }
        }
        
        return true
    }
}

