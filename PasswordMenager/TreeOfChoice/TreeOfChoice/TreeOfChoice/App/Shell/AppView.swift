// App/Shell/AppView.swift
import SwiftUI

struct AppView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var appSettings: AppSettings
    @State private var selectedMode: AppMode?
    @State private var showSettings = false
    
    enum AppMode {
        case labConnect
        case labSecurity
        case realConnect
        case realSecurity
        case treeLibrary
    }

    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0) // #FF5C00

    var body: some View {
        Group {
            if let mode = selectedMode {
                // Show ModeWindowView instead of home screen
                ModeWindowView(selectedMode: $selectedMode, initialTab: mapToModeTab(mode))
                    .environmentObject(localization)
                    .transition(.opacity)
            } else {
                // Home screen
                homeView
            }
        }
        .animation(.easeInOut, value: selectedMode)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(localization)
                .environmentObject(appSettings)
        }
    }
    
    private var homeView: some View {
        ZStack {
            // JEDNA NARANČASTA POZADINA
            accentOrange

            VStack(alignment: .leading, spacing: 24) {
                // header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.text("app.title"))
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Text(localization.text("app.subtitle"))
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Settings button
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                // 5 komponenti (4 moda + Tree Library)
                HStack(spacing: 20) {
                    ModeCard(
                        title: localization.text("mode.labConnect.title"),
                        description: localization.text("mode.labConnect.description"),
                        buttonTitle: localization.text("mode.open"),
                        accentColor: accentOrange,
                        action: {
                            selectedMode = .labConnect
                        }
                    )

                    ModeCard(
                        title: localization.text("mode.labSecurity.title"),
                        description: localization.text("mode.labSecurity.description"),
                        buttonTitle: localization.text("mode.open"),
                        accentColor: accentOrange,
                        action: {
                            selectedMode = .labSecurity
                        }
                    )

                    ModeCard(
                        title: localization.text("mode.realConnect.title"),
                        description: localization.text("mode.realConnect.description"),
                        buttonTitle: localization.text("mode.open"),
                        accentColor: accentOrange,
                        action: {
                            selectedMode = .realConnect
                        }
                    )

                    ModeCard(
                        title: localization.text("mode.realSecurity.title"),
                        description: localization.text("mode.realSecurity.description"),
                        buttonTitle: localization.text("mode.open"),
                        accentColor: accentOrange,
                        action: {
                            selectedMode = .realSecurity
                        }
                    )
                    
                    ModeCard(
                        title: localization.text("treeLibrary.title"),
                        description: localization.text("treeLibrary.homeDescription"),
                        buttonTitle: localization.text("mode.open"),
                        accentColor: accentOrange,
                        action: {
                            selectedMode = .treeLibrary
                        }
                    )
                }

                // panel za datoteke
                FilesPanel()
                    .environmentObject(localization)

                Spacer()
            }
            .padding(32)
        }
        .frame(minWidth: 1200, minHeight: 800)
        .onAppear {
            // Enter fullscreen when home view appears
            #if os(macOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let window = NSApplication.shared.windows.first {
                    if !window.styleMask.contains(.fullScreen) {
                        window.toggleFullScreen(nil)
                    }
                }
            }
            #endif
        }
    }
    
    private func mapToModeTab(_ mode: AppMode) -> ModeWindowView.ModeTab {
        switch mode {
        case .labConnect: return .labConnect
        case .labSecurity: return .labSecurity
        case .realConnect: return .realConnect
        case .realSecurity: return .realSecurity
        case .treeLibrary: return .treeLibrary
        }
    }
}

extension AppView.AppMode: Identifiable {
    var id: Self { self }
}
