//
//  AreaElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Protokol za elemente koji imaju Area područje
/// Samo elementi s "Area" u nazivu implementiraju ovaj protokol
protocol AreaElement {
    /// Provjerava da li element ima area područje
    var hasArea: Bool { get }
    
    /// Širina area područja
    var areaWidth: CGFloat? { get set }
    
    /// Visina area područja
    var areaHeight: CGFloat? { get set }
    
    /// Boja area područja
    var areaColor: Color { get }
    
    /// Vraća bounds area područja
    func getAreaBounds(componentCenter: CGPoint) -> CGRect
    
    /// Provjerava da li je točka unutar area područja
    func isPointInArea(_ point: CGPoint, componentCenter: CGPoint) -> Bool
}

/// Default implementacija za AreaElement
extension AreaElement {
    var hasArea: Bool { true }
    
    var areaColor: Color {
        // Default siva boja (kao i ikone)
        Color.gray
    }
    
    func getAreaBounds(componentCenter: CGPoint) -> CGRect {
        let width = areaWidth ?? 120
        let height = areaHeight ?? 120
        
        return CGRect(
            x: componentCenter.x - width / 2,
            y: componentCenter.y - height / 2,
            width: width,
            height: height
        )
    }
    
    func isPointInArea(_ point: CGPoint, componentCenter: CGPoint) -> Bool {
        let bounds = getAreaBounds(componentCenter: componentCenter)
        return bounds.contains(point)
    }
}

