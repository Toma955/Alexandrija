//
//  ProfileManager.swift
//  Alexandria
//
//  Upravljanje profilima (Chrome/Safari/Edge style) – više profila, switch, add, remove.
//

import Foundation
import SwiftUI

@MainActor
final class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published private(set) var profiles: [Profile] = []
    @Published private(set) var currentProfile: Profile?
    @Published var showProfilePicker: Bool = false
    
    private let profilesKey = "alexandria.profiles"
    private let currentProfileIdKey = "alexandria.currentProfileId"
    
    private init() {
        loadProfiles()
        migrateFromLegacyUserIfNeeded()
    }
    
    var hasActiveProfile: Bool { currentProfile != nil }
    
    func addProfile(name: String) {
        let profile = Profile(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        profiles.append(profile)
        if profiles.count == 1 {
            switchTo(profile)
        }
        save()
    }
    
    func switchTo(_ profile: Profile) {
        guard profiles.contains(where: { $0.id == profile.id }) else { return }
        currentProfile = profile
        UserDefaults.standard.set(profile.id.uuidString, forKey: currentProfileIdKey)
        showProfilePicker = false
    }
    
    func removeProfile(_ profile: Profile) {
        profiles.removeAll { $0.id == profile.id }
        if currentProfile?.id == profile.id {
            currentProfile = profiles.first
            if let p = currentProfile {
                UserDefaults.standard.set(p.id.uuidString, forKey: currentProfileIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: currentProfileIdKey)
            }
        }
        save()
    }
    
    func requestProfileSwitch() {
        showProfilePicker = true
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }
    
    private func loadProfiles() {
        guard let data = UserDefaults.standard.data(forKey: profilesKey),
              let loaded = try? JSONDecoder().decode([Profile].self, from: data) else {
            return
        }
        profiles = loaded
        if let idStr = UserDefaults.standard.string(forKey: currentProfileIdKey),
           let id = UUID(uuidString: idStr),
           let profile = profiles.first(where: { $0.id == id }) {
            currentProfile = profile
        } else {
            currentProfile = profiles.first
            if let p = currentProfile {
                UserDefaults.standard.set(p.id.uuidString, forKey: currentProfileIdKey)
            }
        }
    }
    
    /// Migracija starog User modela u Profile
    private func migrateFromLegacyUserIfNeeded() {
        let legacyKey = "alexandria.currentUser"
        guard let data = UserDefaults.standard.data(forKey: legacyKey),
              let _ = try? JSONDecoder().decode(User.self, from: data) else {
            return
        }
        struct LegacyUser: Codable {
            let id: UUID
            let name: String
            let email: String?
        }
        guard let legacy = try? JSONDecoder().decode(LegacyUser.self, from: data) else { return }
        if profiles.isEmpty {
            let profile = Profile(
                id: legacy.id,
                name: legacy.name.isEmpty ? "Profil" : legacy.name
            )
            profiles = [profile]
            currentProfile = profile
            UserDefaults.standard.set(profile.id.uuidString, forKey: currentProfileIdKey)
            save()
        }
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }
}
