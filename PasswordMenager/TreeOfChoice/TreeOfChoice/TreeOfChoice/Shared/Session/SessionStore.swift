//
//  SessionStore.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation
import SwiftUI

/// Store za upravljanje aktivnim sesijama
class SessionStore: ObservableObject {
    @Published var activeSessions: [SessionMetadata] = []
    
    private let sessionsDirectory: URL
    
    init() {
        // Kreiraj direktorij za spremanje sesija
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        sessionsDirectory = documentsPath.appendingPathComponent("Sessions", isDirectory: true)
        
        // Kreiraj direktorij ako ne postoji
        try? FileManager.default.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
        
        // Učitaj postojeće sesije
        loadSessions()
    }
    
    /// Kreiraj novu sesiju
    func createSession(modeType: SessionModeType, name: String? = nil) -> SessionMetadata {
        let sessionName = name ?? "\(modeType.displayName) - \(Date().formatted(date: .omitted, time: .shortened))"
        let session = SessionMetadata(
            modeType: modeType,
            name: sessionName
        )
        
        activeSessions.append(session)
        saveSessions()
        
        return session
    }
    
    /// Obriši sesiju
    func deleteSession(_ session: SessionMetadata) {
        activeSessions.removeAll { $0.id == session.id }
        saveSessions()
    }
    
    /// Ažuriraj sesiju (npr. lastAccessed)
    func updateSession(_ session: SessionMetadata) {
        if let index = activeSessions.firstIndex(where: { $0.id == session.id }) {
            var updatedSession = session
            updatedSession.lastAccessed = Date()
            activeSessions[index] = updatedSession
            saveSessions()
        }
    }
    
    /// Spremi sesiju u datoteku na određenu lokaciju
    func saveSessionToFile(_ session: SessionMetadata, at url: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(session)
            
            // Ako je URL direktorij, dodaj ime datoteke
            var fileURL = url
            if url.hasDirectoryPath {
                let fileName = "\(session.name).json".replacingOccurrences(of: "/", with: "_")
                fileURL = url.appendingPathComponent(fileName)
            }
            
            try data.write(to: fileURL)
            print("Session saved to: \(fileURL.path)")
        } catch {
            print("Failed to save session: \(error)")
        }
    }
    
    /// Spremi sesiju u default direktorij (za backward compatibility)
    func saveSessionToFile(_ session: SessionMetadata) {
        let fileURL = sessionsDirectory.appendingPathComponent("\(session.id.uuidString).json")
        saveSessionToFile(session, at: fileURL)
    }
    
    /// Učitaj sesiju iz datoteke
    func loadSessionFromFile(id: UUID) -> SessionMetadata? {
        let fileURL = sessionsDirectory.appendingPathComponent("\(id.uuidString).json")
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode(SessionMetadata.self, from: data)
    }
    
    /// Spremi sve sesije
    private func saveSessions() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(activeSessions)
            let fileURL = sessionsDirectory.appendingPathComponent("sessions.json")
            try data.write(to: fileURL)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }
    
    /// Učitaj sve sesije
    private func loadSessions() {
        let fileURL = sessionsDirectory.appendingPathComponent("sessions.json")
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let sessions = try? decoder.decode([SessionMetadata].self, from: data) {
            activeSessions = sessions.filter { $0.isActive }
        }
    }
}
