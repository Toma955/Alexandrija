//
//  SessionMetadata.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Model koji predstavlja metapodatke o aktivnoj sesiji
struct SessionMetadata: Identifiable, Codable {
    let id: UUID
    let modeType: SessionModeType
    let name: String
    let createdAt: Date
    var lastAccessed: Date
    var isActive: Bool
    
    init(id: UUID = UUID(), modeType: SessionModeType, name: String, createdAt: Date = Date(), lastAccessed: Date = Date(), isActive: Bool = true) {
        self.id = id
        self.modeType = modeType
        self.name = name
        self.createdAt = createdAt
        self.lastAccessed = lastAccessed
        self.isActive = isActive
    }
}

/// Tipovi sesija koji odgovaraju različitim modovima
enum SessionModeType: String, Codable {
    case labConnect = "labConnect"
    case labSecurity = "labSecurity"
    case realConnect = "realConnect"
    case realSecurity = "realSecurity"
    case watchmen = "watchmen"
    case treeCreator = "treeCreator"
    case treeLibrary = "treeLibrary"
    
    var displayName: String {
        switch self {
        case .labConnect: return "Lab-Connection"
        case .labSecurity: return "Lab-Security"
        case .realConnect: return "Real-Connection"
        case .realSecurity: return "Real-Security"
        case .watchmen: return "Watchmen"
        case .treeCreator: return "Tree Creator"
        case .treeLibrary: return "Tree Library"
        }
    }
    
    var iconName: String {
        switch self {
        case .labConnect: return "Lab"
        case .labSecurity: return "SecurityLab"
        case .realConnect: return "Conection"
        case .realSecurity: return "SecurityLab"
        case .watchmen: return "Watchtower_icon"
        case .treeCreator: return "decision"
        case .treeLibrary: return "decision"
        }
    }
}
