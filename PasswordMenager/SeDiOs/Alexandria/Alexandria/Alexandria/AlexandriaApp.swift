//
//  AlexandriaApp.swift
//  Alexandria
//
//  Created by Toma Babić on 13.02.2026..
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private static var hasEnteredFullScreen = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidEnterFullScreen),
            name: NSWindow.didEnterFullScreenNotification,
            object: nil
        )
        tryEnterFullScreen()
        BackendCatalogService.shared.syncCatalogIfNeeded()
        // Primjena boja odabrane teme (npr. Classic) iz theme.json – inače bi ostale zadnje vrijednosti ili default.
        ThemeRegistry.applyCurrentThemeColors()
    }

    @objc private func windowDidEnterFullScreen(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    }

    private func tryEnterFullScreen() {
        guard !Self.hasEnteredFullScreen,
              let window = NSApplication.shared.windows.first else {
            if !Self.hasEnteredFullScreen {
                DispatchQueue.main.async { self.tryEnterFullScreen() }
            }
            return
        }
        Self.hasEnteredFullScreen = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        window.collectionBehavior.insert(.fullScreenPrimary)
        if let screen = NSScreen.main {
            window.setFrame(screen.visibleFrame, display: true)
        }
        window.toggleFullScreen(nil)
    }
}

@main
struct AlexandriaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1920, height: 1080)
    }
}
