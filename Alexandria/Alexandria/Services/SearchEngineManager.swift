//
//  SearchEngineManager.swift
//  Alexandria
//
//  Upravljanje listom pretraživača i odabranim.
//

import Foundation
import SwiftUI

final class SearchEngineManager: ObservableObject {
    static let shared = SearchEngineManager()
    
    private let enginesKey = "searchEngines"
    private let selectedIdKey = "selectedSearchEngineId"
    
    @Published var engines: [SearchEngine] = []
    @Published var selectedEngineId: UUID?
    
    var selectedEngine: SearchEngine? {
        guard let id = selectedEngineId else { return engines.first }
        return engines.first { $0.id == id } ?? engines.first
    }
    
    var selectedEngineURL: String {
        selectedEngine?.url ?? ""
    }
    
    private init() {
        load()
    }
    
    func add(name: String, url: String) {
        let engine = SearchEngine(name: name, url: url)
        engines.append(engine)
        if engines.count == 1 {
            selectedEngineId = engine.id
        }
        save()
    }
    
    func remove(_ engine: SearchEngine) {
        engines.removeAll { $0.id == engine.id }
        if selectedEngineId == engine.id {
            selectedEngineId = engines.first?.id
        }
        save()
    }
    
    func update(_ engine: SearchEngine) {
        if let i = engines.firstIndex(where: { $0.id == engine.id }) {
            engines[i] = engine
            save()
        }
    }
    
    func select(_ engine: SearchEngine) {
        selectedEngineId = engine.id
        save()
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: enginesKey),
           let decoded = try? JSONDecoder().decode([SearchEngine].self, from: data) {
            engines = decoded
        }
        if let idStr = UserDefaults.standard.string(forKey: selectedIdKey),
           let id = UUID(uuidString: idStr) {
            selectedEngineId = engines.contains { $0.id == id } ? id : engines.first?.id
        } else {
            selectedEngineId = engines.first?.id
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(engines) {
            UserDefaults.standard.set(data, forKey: enginesKey)
        }
        UserDefaults.standard.set(selectedEngineId?.uuidString, forKey: selectedIdKey)
    }
}
