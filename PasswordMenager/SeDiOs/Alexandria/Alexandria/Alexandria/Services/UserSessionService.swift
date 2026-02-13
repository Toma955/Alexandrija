//
//  UserSessionService.swift
//  Alexandria
//
//  Upravljanje sesijom korisnika – prijava, odjava, trenutni korisnik.
//

import Foundation
import SwiftUI

@MainActor
final class UserSessionService: ObservableObject {
    static let shared = UserSessionService()
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoggedIn: Bool = false
    
    private let storageKey = "alexandria.currentUser"
    
    private init() {
        loadUser()
    }
    
    func login(name: String, email: String? = nil) {
        let user = User(name: name.trimmingCharacters(in: .whitespacesAndNewlines), email: email)
        currentUser = user
        isLoggedIn = true
        saveUser()
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    private func saveUser() {
        guard let user = currentUser else { return }
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadUser() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return
        }
        currentUser = user
        isLoggedIn = true
    }
}
