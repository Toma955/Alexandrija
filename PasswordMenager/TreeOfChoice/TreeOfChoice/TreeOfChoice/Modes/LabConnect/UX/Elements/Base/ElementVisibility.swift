//
//  ElementVisibility.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Enum koji određuje vidljivost elementa u topologiji
enum ElementVisibility {
    /// Element je javan - prikazuje se na topologiji
    case `public`
    
    /// Element je privatan - prikazuje se u zonama (Client A/B)
    case `private`
    
    /// Provjerava da li element može biti drag & drop
    var canBeDragged: Bool {
        switch self {
        case .public:
            return true
        case .private:
            return false
        }
    }
    
    /// Provjerava da li element može biti uklonjen
    var canBeDeleted: Bool {
        switch self {
        case .public:
            return true
        case .private:
            return false // Client A i B se ne mogu obrisati
        }
    }
}

