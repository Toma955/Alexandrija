// App/Shell/AppView.swift
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct AppView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var appSettings: AppSettings
    @StateObject private var sessionStore = SessionStore()
    @State private var selectedMode: AppMode?
    @State private var showSettings = false
    @State private var showAbout = false
    
    enum AppMode {
        case labConnect
        case labSecurity
        case realConnect
        case realSecurity
        case treeLibrary
        case treeCreator
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
        .sheet(isPresented: $showAbout) {
            AboutView()
                .environmentObject(localization)
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
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        // About button
                        Button(action: {
                            showAbout = true
                        }) {
                            Image(systemName: "info.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .help("About")
                        
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
                        .help("Settings")
                        
                        // Exit button
                        Button(action: {
                            exitApplication()
                        }) {
                            Image(systemName: "power")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .help("Exit")
                    }
                }

                // 7 komponenti (4 moda + Tree Library + Proces + Info)
                HStack(spacing: 20) {
                    ModeCard(
                        title: localization.text("mode.labConnect.title"),
                        description: localization.text("mode.labConnect.description"),
                        buttonTitle: "Lab-Connection",
                        iconName: "Lab",
                        accentColor: accentOrange,
                        action: {
                            sessionStore.createSession(modeType: .labConnect)
                            selectedMode = .labConnect
                        }
                    )
                    .frame(maxWidth: .infinity)

                    ModeCard(
                        title: localization.text("mode.labSecurity.title"),
                        description: localization.text("mode.labSecurity.description"),
                        buttonTitle: "Lab-Security",
                        iconName: "SecurityLab",
                        accentColor: accentOrange,
                        action: {
                            sessionStore.createSession(modeType: .labSecurity)
                            selectedMode = .labSecurity
                        }
                    )
                    .frame(maxWidth: .infinity)

                    ModeCard(
                        title: localization.text("mode.realConnect.title"),
                        description: localization.text("mode.realConnect.description"),
                        buttonTitle: "Real-Connection",
                        iconName: "Conection",
                        accentColor: accentOrange,
                        action: {
                            sessionStore.createSession(modeType: .realConnect)
                            selectedMode = .realConnect
                        }
                    )
                    .frame(maxWidth: .infinity)

                    ModeCard(
                        title: localization.text("mode.realSecurity.title"),
                        description: localization.text("mode.realSecurity.description"),
                        buttonTitle: "Real-Security",
                        iconName: "SecurityLab",
                        accentColor: accentOrange,
                        action: {
                            sessionStore.createSession(modeType: .realSecurity)
                            selectedMode = .realSecurity
                        }
                    )
                    .frame(maxWidth: .infinity)
                    
                    ModeCard(
                        title: localization.text("treeLibrary.title"),
                        description: localization.text("treeLibrary.homeDescription"),
                        buttonTitle: "Tree Library",
                        iconName: "decision",
                        accentColor: accentOrange,
                        action: {
                            sessionStore.createSession(modeType: .treeLibrary)
                            selectedMode = .treeLibrary
                        }
                    )
                    .frame(maxWidth: .infinity)
                    
                    ModeCard(
                        title: "Watchmen",
                        description: "",
                        buttonTitle: "Watchmen",
                        iconName: "Watchtower_icon",
                        accentColor: accentOrange,
                        action: {
                            sessionStore.createSession(modeType: .watchmen)
                            // TODO: Implement Watchmen action
                        }
                    )
                    .frame(maxWidth: .infinity)
                    
                    ModeCard(
                        title: "Tree Creator",
                        description: "",
                        buttonTitle: "Tree Creator",
                        iconName: "decision",
                        accentColor: accentOrange,
                        action: {
                            sessionStore.createSession(modeType: .treeCreator)
                            selectedMode = .treeCreator
                        }
                    )
                    .frame(maxWidth: .infinity)
                }

                // panel za datoteke
                FilesPanel()
                    .environmentObject(localization)
                    .frame(maxWidth: .infinity)
                
                // Active Sessions
                ActiveSessionsView(sessionStore: sessionStore) { session in
                    // Otvori sesiju - mapiraj SessionModeType na AppMode
                    if let mode = mapSessionModeToAppMode(session.modeType) {
                        selectedMode = mode
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 32)
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
        case .treeCreator: return .treeCreator
        }
    }
    
    private func mapSessionModeToAppMode(_ sessionMode: SessionModeType) -> AppMode? {
        switch sessionMode {
        case .labConnect: return .labConnect
        case .labSecurity: return .labSecurity
        case .realConnect: return .realConnect
        case .realSecurity: return .realSecurity
        case .treeLibrary: return .treeLibrary
        case .treeCreator: return .treeCreator
        case .watchmen: return nil // Watchmen nema AppMode još
        }
    }
    
    private func exitApplication() {
        #if os(macOS)
        NSApplication.shared.terminate(nil)
        #else
        exit(0)
        #endif
    }
}

extension AppView.AppMode: Identifiable {
    var id: Self { self }
}
