//
//  Profile.swift
//  Alexandria
//
//  Model profila – sve što je za moderni web browser bitno (ime, prezime, naziv, email, mobitel, slika, osobe).
//

import Foundation

/// Osoba povezana s profilom (član obitelji, kontakt…)
struct ProfilePerson: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var relation: String?  // npr. "Supruga", "Dijete"
    
    init(id: UUID = UUID(), name: String, relation: String? = nil) {
        self.id = id
        self.name = name
        self.relation = relation
    }
}

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    /// Staro polje – koristi se kao fallback za displayName ako nema preferredDisplayName / ime+prezime
    var name: String
    var createdAt: Date
    
    var firstName: String?
    var lastName: String?
    var middleName: String?
    /// Naziv (kako se profil prikazuje) – npr. "Ivan P." ili "Poslovni"
    var preferredDisplayName: String?
    var email: String?
    var phone: String?
    /// Slika profila (JPEG/PNG, spremljeno kao Data; preporuka max ~256×256)
    var avatarImageData: Data?
    /// Osobe (članovi obitelji, kontakti)
    var people: [ProfilePerson]?
    
    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        firstName: String? = nil,
        lastName: String? = nil,
        middleName: String? = nil,
        preferredDisplayName: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        avatarImageData: Data? = nil,
        people: [ProfilePerson]? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.firstName = firstName
        self.lastName = lastName
        self.middleName = middleName
        self.preferredDisplayName = preferredDisplayName
        self.email = email
        self.phone = phone
        self.avatarImageData = avatarImageData
        self.people = people
    }
    
    /// Prikazano ime: naziv (preferredDisplayName) ili "Ime Prezime" ili staro name ili "Profil"
    var displayName: String {
        if let p = preferredDisplayName, !p.trimmingCharacters(in: .whitespaces).isEmpty {
            return p.trimmingCharacters(in: .whitespaces)
        }
        let f = firstName?.trimmingCharacters(in: .whitespaces) ?? ""
        let l = lastName?.trimmingCharacters(in: .whitespaces) ?? ""
        if !f.isEmpty || !l.isEmpty {
            return [f, l].joined(separator: " ").trimmingCharacters(in: .whitespaces)
        }
        return name.isEmpty ? "Profil" : name
    }
}
