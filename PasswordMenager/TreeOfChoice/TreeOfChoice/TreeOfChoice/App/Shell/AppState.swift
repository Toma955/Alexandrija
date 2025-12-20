//
//  AppState.swift
//  TreeOfChoice
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case hr = "hr"
    case en = "en"

    var id: String { rawValue }
}

enum RootScreen {
    case preloader
    case app
}

final class AppState: ObservableObject {
    @Published var rootScreen: RootScreen = .preloader
    @Published var language: AppLanguage = .hr {
        didSet {
            Localization.shared.currentLanguage = language
        }
    }

    init() {
        Localization.shared.currentLanguage = language
    }
}
