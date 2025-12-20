// TreeOfChoice/App/TreeOfChoiceApp.swift
// TreeOfChoice

import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct TreeOfChoiceApp: App {
    @StateObject private var preloaderViewModel = PreloaderViewModel()
    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var appSettings = AppSettings.shared
    @State private var isAppLoaded: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isAppLoaded {
                    AppView()
                        .environmentObject(preloaderViewModel)
                        .environmentObject(localizationManager)
                        .environmentObject(appSettings)
                        .frame(minWidth: 1200, minHeight: 800)
                        .onAppear {
                            setupWindow()
                        }
                } else {
                    PreloaderView {
                        isAppLoaded = true
                    }
                    .environmentObject(preloaderViewModel)
                    .environmentObject(localizationManager)
                }
            }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandMenu("Jezik") {
                Button("Hrvatski") {
                    preloaderViewModel.currentLanguage = .croatian
                }
                Button("English") {
                    preloaderViewModel.currentLanguage = .english
                }
            }
            
            CommandGroup(replacing: .windowSize) {
                Button("Toggle Fullscreen") {
                    appSettings.isFullscreen.toggle()
                    toggleFullscreen()
                }
                .keyboardShortcut("f", modifiers: [.command, .control])
            }
        }
    }
    
    private func setupWindow() {
        #if os(macOS)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let window = NSApplication.shared.windows.first {
                // Enter fullscreen if not already in fullscreen
                if !window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
            }
        }
        #endif
    }
    
    private func toggleFullscreen() {
        #if os(macOS)
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.toggleFullScreen(nil)
            }
        }
        #endif
    }
}
