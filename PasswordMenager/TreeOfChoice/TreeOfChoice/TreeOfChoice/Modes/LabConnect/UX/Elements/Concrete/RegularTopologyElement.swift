//
//  RegularTopologyElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Konkretna klasa za regularne elemente (bez Area)
/// Automatski ima pinove (ConnectableElement), ali nema Area
/// Koristi se za: Router, Server, Switch, itd.
class RegularTopologyElement: BaseTopologyElement {
    // MARK: - Initialization
    
    override init(component: NetworkComponent, visibility: ElementVisibility = .public, topology: NetworkTopology? = nil) {
        super.init(component: component, visibility: visibility, topology: topology)
    }
    
    // MARK: - Override Methods
    
    override func getStatus() -> String {
        "Connected" // Override u subklasama ako je potrebno
    }
    
    override func getMetadata() -> [String: Any] {
        var metadata = super.getMetadata()
        metadata["hasArea"] = false
        return metadata
    }
}

