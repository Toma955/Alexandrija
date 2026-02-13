//
//  User.swift
//  Alexandria
//
//  Model korisnika.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var email: String?
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, email: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
    }
    
    var displayName: String {
        name.isEmpty ? "Korisnik" : name
    }
}
