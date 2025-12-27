//
//  AreaTopologyElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Konkretna klasa za elemente koji imaju Area područje
/// Automatski implementira AreaElement protokol
/// Koristi se za: User Area, Business Area, Business Private Area, Nilternius Area
class AreaTopologyElement: BaseTopologyElement, AreaElement {
    // MARK: - Area Properties
    
    @Published var areaWidth: CGFloat? = 120
    @Published var areaHeight: CGFloat? = 120
    
    // MARK: - Initialization
    
    init(
        component: NetworkComponent,
        visibility: ElementVisibility = .public,
        topology: NetworkTopology? = nil,
        areaWidth: CGFloat? = 120,
        areaHeight: CGFloat? = 120
    ) {
        self.areaWidth = areaWidth
        self.areaHeight = areaHeight
        super.init(component: component, visibility: visibility, topology: topology)
        
        // Ako komponenta već ima areaWidth/areaHeight, koristi ih
        if let existingWidth = component.areaWidth {
            self.areaWidth = existingWidth
        }
        if let existingHeight = component.areaHeight {
            self.areaHeight = existingHeight
        }
    }
    
    // MARK: - AreaElement Implementation
    
    override var hasAreaProperty: Bool { true }
    
    var hasArea: Bool { true }
    
    var areaColor: Color {
        // Default: siva boja (kao i ikone)
        component.customColor ?? Color.gray
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
    
    // MARK: - Override Methods
    
    override func getStatus() -> String {
        "Area: \(Int(areaWidth ?? 0))x\(Int(areaHeight ?? 0))"
    }
    
    override func getMetadata() -> [String: Any] {
        var metadata = super.getMetadata()
        metadata["areaWidth"] = areaWidth ?? 0
        metadata["areaHeight"] = areaHeight ?? 0
        metadata["areaColor"] = areaColor.description
        return metadata
    }
}

