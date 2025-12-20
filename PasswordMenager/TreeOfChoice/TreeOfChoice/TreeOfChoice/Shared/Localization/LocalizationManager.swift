// LocalizationManager.swift
import Foundation

final class LocalizationManager: ObservableObject {

    @Published var currentLanguage: SupportedLanguage = .english
    private var translations: [String: String] = [:]

    init() {
        loadLanguage(.english)
    }

    func loadLanguage(_ language: SupportedLanguage) {
        currentLanguage = language
        translations = loadJSON(for: language)
    }

    func text(_ key: String) -> String {
        return translations[key] ?? key
    }

    private func loadJSON(for language: SupportedLanguage) -> [String: String] {
        guard let url = Bundle.main.url(forResource: language.rawValue, withExtension: "json") else {
            print("❌ JSON NOT FOUND:", language.rawValue)
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            let dict = try JSONDecoder().decode([String: String].self, from: data)
            print("✅ Loaded JSON:", language.rawValue)
            return dict
        } catch {
            print("❌ JSON DECODE ERROR:", error)
            return [:]
        }
    }
}
