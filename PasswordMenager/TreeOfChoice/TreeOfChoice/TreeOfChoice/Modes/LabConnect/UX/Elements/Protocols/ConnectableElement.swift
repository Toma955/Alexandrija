//
//  ConnectableElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Protokol za elemente koji mogu imati konekcije (pinove)
/// SVI elementi u topologiji moraju implementirati ovaj protokol
protocol ConnectableElement {
    /// Lista connection pointa (pinova) koje element ima
    var connectionPoints: [ConnectionPoint] { get }
    
    /// Vraća poziciju pina za dani connection point
    func getPinPosition(_ point: ConnectionPoint, componentCenter: CGPoint) -> CGPoint
    
    /// Provjerava da li element može spojiti s drugim elementom
    func canConnect(to other: ConnectableElement) -> Bool
}

/// Default implementacija za ConnectableElement
extension ConnectableElement {
    /// Default: svi elementi imaju 4 pina (top, bottom, left, right)
    var connectionPoints: [ConnectionPoint] {
        [.top, .bottom, .left, .right]
    }
    
    /// Default: koristi ConnectionPointDetector za poziciju pina
    func getPinPosition(_ point: ConnectionPoint, componentCenter: CGPoint) -> CGPoint {
        ConnectionPointDetector.position(for: point, componentCenter: componentCenter)
    }
    
    /// Default: svi elementi mogu spojiti jedan s drugim
    func canConnect(to other: ConnectableElement) -> Bool {
        true
    }
}

