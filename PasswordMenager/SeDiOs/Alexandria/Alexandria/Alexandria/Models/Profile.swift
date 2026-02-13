//
//  Profile.swift
//  Alexandria
//
//  Model profila – ime. Avatar i boje idu u temu.
//

import Foundation

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
    
    var displayName: String {
        name.isEmpty ? "Profil" : name
    }
}
