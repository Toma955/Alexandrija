//
//  SearchEngine.swift
//  Alexandria
//
//  Model pretraživača – ime i URL za spajanje.
//

import Foundation

struct SearchEngine: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    
    init(id: UUID = UUID(), name: String, url: String) {
        self.id = id
        self.name = name
        self.url = url.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/$", with: "", options: .regularExpression)
    }
}
