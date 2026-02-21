//
//  InstalledAppViewModel.swift
//  Alexandria
//

import Foundation
import SwiftUI

/// ViewModel za InstalledAppView – učitavanje izvora i parsiranje; logika odvojena od Viewa.
@MainActor
final class InstalledAppViewModel: ObservableObject {
    enum State {
        case loading
        case app(AlexandriaViewNode)
        case error(String, source: String?)
    }

    @Published private(set) var state: State = .loading

    private let app: InstalledApp

    init(app: InstalledApp) {
        self.app = app
    }

    func loadIfNeeded(appInstallService: AppInstallServiceProtocol, consoleStore: ConsoleStore) {
        guard case .loading = state else { return }
        guard app.canViewOrSaveSource else {
            state = .error("Aplikacija je u LLVM IR formatu (.ll / .bc). Izvornik nije dostupan za pregled ni spremanje.", source: nil)
            return
        }
        let service = appInstallService
        let app = app
        let store = consoleStore
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let source = try service.loadSource(for: app)
                let node = try AlexandriaParser(source: source).parse()
                Task { @MainActor in
                    self?.state = .app(node)
                }
            } catch {
                let fallbackSource = (try? service.loadSource(for: app))
                Task { @MainActor in
                    store.log("App greška: \(error.localizedDescription)", type: .error)
                    self?.state = .error(error.localizedDescription, source: fallbackSource)
                }
            }
        }
    }
}
