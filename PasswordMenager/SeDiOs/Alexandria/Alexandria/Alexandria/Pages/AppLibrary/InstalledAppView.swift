//
//  InstalledAppView.swift
//  Alexandria
//
//  App browser – prikazuje instaliranu aplikaciju (renderira UI).
//

import SwiftUI

/// Prikazuje instaliranu aplikaciju – učitava Swift (DSL), parsira i renderira. Ne dira se logika appova.
struct InstalledAppView: View {
    let app: InstalledApp
    @Binding var currentAddress: String
    var onBack: (() -> Void)?
    var onSwitchToDevMode: (() -> Void)?
    
    @State private var state: ViewState = .loading
    
    private var accentColor: Color { AlexandriaTheme.accentColor }
    
    enum ViewState {
        case loading
        case app(AlexandriaViewNode)
        case error(String, source: String?)
    }
    
    var body: some View {
        ZStack {
            switch state {
            case .loading:
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(accentColor)
                    Text("Učitavam \(app.name)...")
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .app(let node):
                VStack(spacing: 0) {
                    HStack {
                        Button { onBack?() } label: {
                            Image(systemName: "arrow.left")
                                .foregroundColor(accentColor)
                        }
                        .buttonStyle(.plain)
                        .padding(12)
                        Text(app.name)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                    .background(Color.black.opacity(0.5))
                    AlexandriaRenderer(node: node)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message, let source):
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text(message)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    if let src = source {
                        CodeView(source: src)
                            .frame(maxWidth: .infinity, maxHeight: 300)
                    }
                    HStack(spacing: 16) {
                        Button("Natrag") { onBack?() }
                            .foregroundColor(accentColor)
                        Button("Dev Mode") { onSwitchToDevMode?() }
                            .foregroundColor(accentColor.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { currentAddress = app.name }
        .task {
            currentAddress = app.name
            await loadAndRender()
        }
    }
    
    private func loadAndRender() async {
        do {
            let source = try AppInstallService.shared.loadSource(for: app)
            let node = try AlexandriaParser(source: source).parse()
            await MainActor.run {
                state = .app(node)
            }
        } catch {
            await MainActor.run {
                ConsoleStore.shared.log("App greška: \(error.localizedDescription)", type: .error)
                let src = (try? AppInstallService.shared.loadSource(for: app))
                state = .error(error.localizedDescription, source: src)
            }
        }
    }
}
