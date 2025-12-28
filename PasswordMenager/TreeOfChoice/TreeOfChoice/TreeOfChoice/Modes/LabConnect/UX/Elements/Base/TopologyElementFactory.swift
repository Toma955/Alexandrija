//
//  TopologyElementFactory.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Factory za kreiranje topology elemenata
struct TopologyElementFactory {
    /// Kreira odgovarajući BaseTopologyElement za komponentu
    static func createElement(for component: NetworkComponent, visibility: ElementVisibility, topology: NetworkTopology? = nil) -> BaseTopologyElement {
        // Za sada sve komponente koriste isti BaseTopologyElement
        // U budućnosti možemo imati različite tipove (AreaTopologyElement, RegularTopologyElement, itd.)
        return BaseTopologyElement(component: component, visibility: visibility, topology: topology)
    }
}

