//
//  Extensions.swift
//  TreeOfChoice
//

import SwiftUI

// MARK: - Localization core

final class Localization: ObservableObject {
    static let shared = Localization()

    @Published var currentLanguage: AppLanguage = .hr {
        didSet { loadStrings() }
    }

    private var strings: [String: String] = [:]

    private init() {
        loadStrings()
    }

    private func loadStrings() {
        let code = currentLanguage.rawValue   // "hr" ili "en"

        // prvo probaj Resources/Localization/{code}.json
        let bundle = Bundle.main
        let possiblePaths: [URL?] = [
            bundle.url(forResource: code, withExtension: "json", subdirectory: "Resources/Localization"),
            bundle.url(forResource: code, withExtension: "json", subdirectory: "Localization"),
            bundle.url(forResource: code, withExtension: "json")
        ]

        for urlOpt in possiblePaths {
            if let url = urlOpt,
               let data = try? Data(contentsOf: url),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                strings = dict
                return
            }
        }

        // ako ništa ne nađe
        strings = [:]
    }

    func text(_ key: String) -> String {
        strings[key] ?? key
    }
}

// MARK: - Environment helper

private struct LocalizationKey: EnvironmentKey {
    static let defaultValue: Localization = .shared
}

extension EnvironmentValues {
    var localization: Localization {
        get { self[LocalizationKey.self] }
        set { self[LocalizationKey.self] = newValue }
    }
}

extension View {
    func withLocalization() -> some View {
        environment(\.localization, Localization.shared)
    }
}
