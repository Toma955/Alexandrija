//
//  InstalledAppView.swift
//  Alexandria
//
//  App browser – prikazuje instaliranu aplikaciju (renderira UI).
//

import SwiftUI

/// Prikazuje instaliranu aplikaciju – učitava Swift (DSL), parsira i renderira. Logika u InstalledAppViewModel.
struct InstalledAppView: View {
    let app: InstalledApp
    @Binding var currentAddress: String
    var onBack: (() -> Void)?
    var onSwitchToDevMode: (() -> Void)?
    
    @Environment(\.appInstallService) private var appInstallService
    @Environment(\.consoleStore) private var consoleStore
    @StateObject private var viewModel: InstalledAppViewModel
    
    init(app: InstalledApp, currentAddress: Binding<String>, onBack: (() -> Void)?, onSwitchToDevMode: (() -> Void)?) {
        self.app = app
        _currentAddress = currentAddress
        self.onBack = onBack
        self.onSwitchToDevMode = onSwitchToDevMode
        _viewModel = StateObject(wrappedValue: InstalledAppViewModel(app: app))
    }
    
    private var accentColor: Color { AlexandriaTheme.accentColor }
    
    var body: some View {
        Group {
            if let webURL = app.webURL, !webURL.isEmpty {
                // Pravi web (Google, YouTube, Spotify, …) – HTML/CSS/JS u WKWebView
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
                    WebViewWrapper(urlString: webURL)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1a1a1a"))
            } else {
                dslContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { currentAddress = app.name }
        .task(id: app.id) {
            currentAddress = app.name
            if app.webURL == nil || app.webURL?.isEmpty == true {
                viewModel.loadIfNeeded(appInstallService: appInstallService, consoleStore: consoleStore)
            }
        }
        .id(app.id)
    }
    
    @ViewBuilder
    private var dslContent: some View {
        ZStack {
            switch viewModel.state {
            case .loading:
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(accentColor)
                    Text("Učitavam \(app.name)...")
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1a1a1a"))
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
                    AlexandriaRenderer(node: node, console: consoleStore)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(24)
                        .background(Color(hex: "1a1a1a"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1a1a1a"))
            case .error(let message, let source):
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text(message)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    if app.canViewOrSaveSource, let src = source {
                        CodeView(source: src)
                            .frame(maxWidth: .infinity, maxHeight: 300)
                    } else if !app.canViewOrSaveSource {
                        Text("Izvorni kod nije dostupan za pregled (LLVM IR).")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    HStack(spacing: 16) {
                        Button("Natrag") { onBack?() }
                            .foregroundColor(accentColor)
                        Button("Dev Mode") { onSwitchToDevMode?() }
                            .foregroundColor(accentColor.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1a1a1a"))
            }
        }
    }
    
}
