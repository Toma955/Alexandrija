//
//  InstalledAppView.swift
//  Alexandria
//
//  Prikaz instalirane Alexandria Swift aplikacije.
//

import SwiftUI

/// Prikazuje instaliranu aplikaciju – učitava Swift izvornik i prikazuje ga (samo kod, bez renderiranja).
struct InstalledAppView: View {
    let app: InstalledApp
    @Binding var currentAddress: String
    var onBack: (() -> Void)?
    var onSwitchToDevMode: (() -> Void)?
    
    @State private var state: ViewState = .loading
    
    private let accentColor = Color(hex: "ff5c00")
    
    enum ViewState {
        case loading
        case source(String)
        case error(String)
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
            case .source(let source):
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            onBack?()
                        } label: {
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
                    CodeView(source: source)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text(message)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 16) {
                        Button("Natrag") {
                            onBack?()
                        }
                        .foregroundColor(accentColor)
                        Button("Dev Mode") {
                            onSwitchToDevMode?()
                        }
                        .foregroundColor(accentColor.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            currentAddress = app.name
            await loadAndRender()
        }
    }
    
    private func loadAndRender() async {
        do {
            let source = try AppInstallService.shared.loadSource(for: app)
            await MainActor.run {
                state = .source(source)
            }
        } catch {
            await MainActor.run {
                ConsoleStore.shared.log("App greška: \(error.localizedDescription)", type: .error)
                state = .error(error.localizedDescription)
            }
        }
    }
}
