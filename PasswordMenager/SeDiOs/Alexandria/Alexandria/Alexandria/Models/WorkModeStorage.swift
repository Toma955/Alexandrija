//
//  WorkModeStorage.swift
//  Alexandria
//
//  Modovi rada – korisnik može dodavati/uklanjati/imenovati modove.
//  Svaki mod ima ikonu (kuća, aktovka, štit, odmor, offline itd.).
//

import Foundation
import SwiftUI

/// Predlošci ikona za mod – home = kuća, work = aktovka, security = štit, vacation = odmor, offline itd.
struct ModeIconPreset: Identifiable, Equatable {
    let id: String
    let displayName: String
    let symbolName: String

    static let all: [ModeIconPreset] = [
        ModeIconPreset(id: "default", displayName: "Zadano", symbolName: "square.grid.2x2"),
        ModeIconPreset(id: "home", displayName: "Kuća", symbolName: "house.fill"),
        ModeIconPreset(id: "work", displayName: "Posao", symbolName: "briefcase.fill"),
        ModeIconPreset(id: "security", displayName: "Sigurnost", symbolName: "shield.fill"),
        ModeIconPreset(id: "vacation", displayName: "Odmor", symbolName: "palm.tree.fill"),
        ModeIconPreset(id: "offline", displayName: "Offline", symbolName: "wifi.slash"),
        ModeIconPreset(id: "trip", displayName: "Putovanje", symbolName: "airplane"),
        ModeIconPreset(id: "personal", displayName: "Osobno", symbolName: "person.fill"),
        ModeIconPreset(id: "holiday", displayName: "Praznik", symbolName: "gift.fill"),
        ModeIconPreset(id: "focus", displayName: "Fokus", symbolName: "moon.fill"),
        ModeIconPreset(id: "family", displayName: "Obitelj", symbolName: "person.3.fill"),
        ModeIconPreset(id: "health", displayName: "Zdravlje", symbolName: "heart.fill"),
        ModeIconPreset(id: "finance", displayName: "Financije", symbolName: "dollarsign.circle.fill"),
    ]
}

/// Jedan mod rada – npr. Zadano, Posao, Putovanje (ugrađeni ili korisnički), s ikonom.
struct WorkMode: Identifiable, Equatable, Codable {
    var id: String
    var displayName: String
    /// Ugrađeni mod (npr. Zadano) ne može se obrisati.
    var isBuiltIn: Bool
    /// SF Symbol naziv ikone moda (kuća, aktovka, štit…). Nil = zadana ikona.
    var iconName: String?

    /// Ikona za prikaz (zadana ako nije postavljena).
    var iconSymbolName: String {
        iconName ?? "square.grid.2x2"
    }

    static let defaultId = "default"

    static func defaultMode() -> WorkMode {
        WorkMode(id: defaultId, displayName: "Zadano", isBuiltIn: true, iconName: "square.grid.2x2")
    }

    /// Ugrađeni modovi koji već postoje – korisnik ih vidi odmah i može birati; može i dodati svoj.
    static func builtInModes() -> [WorkMode] {
        [
            WorkMode(id: "default", displayName: "Zadano", isBuiltIn: true, iconName: "square.grid.2x2"),
            WorkMode(id: "home", displayName: "Kuća", isBuiltIn: true, iconName: "house.fill"),
            WorkMode(id: "work", displayName: "Posao", isBuiltIn: true, iconName: "briefcase.fill"),
            WorkMode(id: "security", displayName: "Sigurnost", isBuiltIn: true, iconName: "shield.fill"),
            WorkMode(id: "vacation", displayName: "Odmor", isBuiltIn: true, iconName: "palm.tree.fill"),
            WorkMode(id: "offline", displayName: "Offline", isBuiltIn: true, iconName: "wifi.slash"),
            WorkMode(id: "trip", displayName: "Putovanje", isBuiltIn: true, iconName: "airplane"),
            WorkMode(id: "personal", displayName: "Osobno", isBuiltIn: true, iconName: "person.fill"),
            WorkMode(id: "holiday", displayName: "Praznik", isBuiltIn: true, iconName: "gift.fill"),
            WorkMode(id: "focus", displayName: "Fokus", isBuiltIn: true, iconName: "moon.fill"),
        ]
    }
}

/// Pohrana modova rada: lista modova, aktivni mod, opcija "pri pokretanju pitaj za mod".
final class WorkModeStorage: ObservableObject {
    static let shared = WorkModeStorage()

    private static let workModesKey = "workMode.list"
    private static let currentModeIdKey = "workMode.currentModeId"
    private static let showPickerOnLaunchKey = "workMode.showPickerOnLaunch"

    @Published private(set) var workModes: [WorkMode] = []

    /// Trenutno aktivni mod (id). Koristi se za Island, temu, dopuštenja itd.
    static var currentModeId: String {
        get {
            let id = UserDefaults.standard.string(forKey: currentModeIdKey)
            return id ?? WorkMode.defaultId
        }
        set {
            UserDefaults.standard.set(newValue, forKey: currentModeIdKey)
        }
    }

    /// Ako true, pri pokretanju aplikacije prikaži odabir moda.
    static var showPickerOnLaunch: Bool {
        get { UserDefaults.standard.bool(forKey: showPickerOnLaunchKey) }
        set { UserDefaults.standard.set(newValue, forKey: showPickerOnLaunchKey) }
    }

    init() {
        loadModes()
        ensureBuiltInModesPresent()
    }

    private func loadModes() {
        guard let data = UserDefaults.standard.data(forKey: Self.workModesKey),
              let decoded = try? JSONDecoder().decode([WorkMode].self, from: data),
              !decoded.isEmpty else {
            workModes = WorkMode.builtInModes()
            saveModes()
            return
        }
        workModes = decoded
    }

    /// Uvijek imamo sve ugrađene modove na izbor; dopuni listu ako neki nedostaju (npr. stari zapis imao samo Zadano).
    private func ensureBuiltInModesPresent() {
        let builtIns = WorkMode.builtInModes()
        var existingIds = Set(workModes.map(\.id))
        var added = false
        for mode in builtIns {
            if !existingIds.contains(mode.id) {
                workModes.append(mode)
                existingIds.insert(mode.id)
                added = true
            }
        }
        if added {
            saveModes()
        }
    }

    private func saveModes() {
        guard let data = try? JSONEncoder().encode(workModes) else { return }
        UserDefaults.standard.set(data, forKey: Self.workModesKey)
    }

    /// Vraća mod za id; ako ne postoji, vraća Zadano.
    func mode(for id: String) -> WorkMode? {
        workModes.first { $0.id == id }
    }

    /// Aktivni mod (objekt).
    var currentMode: WorkMode? {
        mode(for: Self.currentModeId)
    }

    /// Postavi aktivni mod (po id).
    func setCurrentMode(id: String) {
        guard workModes.contains(where: { $0.id == id }) else { return }
        Self.currentModeId = id
    }

    /// Dodaj novi mod (korisnički). Id = UUID. Ikona po izboru (nil = zadana).
    func addMode(displayName: String, iconName: String? = nil) {
        let id = UUID().uuidString
        let mode = WorkMode(id: id, displayName: displayName, isBuiltIn: false, iconName: iconName)
        workModes.append(mode)
        saveModes()
    }

    /// Obriši mod. Ugrađeni se ne mogu obrisati. Ako se obriše aktivan, prebaci na Zadano.
    func removeMode(id: String) {
        guard let index = workModes.firstIndex(where: { $0.id == id }),
              !workModes[index].isBuiltIn else { return }
        workModes.remove(at: index)
        if Self.currentModeId == id {
            Self.currentModeId = WorkMode.defaultId
        }
        saveModes()
    }

    /// Preimenuj mod.
    func renameMode(id: String, displayName: String) {
        guard let index = workModes.firstIndex(where: { $0.id == id }) else { return }
        workModes[index].displayName = displayName
        saveModes()
    }

    /// Postavi ikonu moda (SF Symbol naziv).
    func setModeIcon(id: String, iconName: String?) {
        guard let index = workModes.firstIndex(where: { $0.id == id }) else { return }
        workModes[index].iconName = iconName
        saveModes()
    }
}
