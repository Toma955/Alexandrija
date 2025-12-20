// PreloaderViewModel.swift
import Foundation

final class PreloaderViewModel: ObservableObject {

    enum Language {
        case croatian
        case english
    }

    @Published var currentLanguage: Language = .croatian
    @Published var isLoading: Bool = true

    func loadOnStartup(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            completion()
        }
    }
}
