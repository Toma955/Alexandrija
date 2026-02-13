//
//  ContentView.swift
//  Alexandria
//
//  Created by Toma Babić on 13.02.2026..
//

import SwiftUI
import AppKit

// MARK: - Transparent window kroz NSWindow
private class WindowAccessorHost: NSView {
    var callback: (NSWindow) -> Void

    override var isOpaque: Bool { false }

    init(callback: @escaping (NSWindow) -> Void) {
        self.callback = callback
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let w = window { callback(w) }
    }
}

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        WindowAccessorHost(callback: callback)
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Tab model
private enum TabType: Equatable {
    case empty
    case search
    case app(InstalledApp)
    case devMode
}

private struct BrowserTabItem: Identifiable {
    let id: UUID
    let type: TabType
    var title: String {
        switch type {
        case .empty: return "Novi tab"
        case .search: return "Pretraži"
        case .app(let app): return app.name
        case .devMode: return "Dev Mode"
        }
    }
}

// MARK: - Tab (obli pill s natpisom)
private struct BrowserTabView: View {
    let tab: BrowserTabItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    private let accentColor = Color(hex: "ff5c00")

    var body: some View {
        HStack(spacing: 6) {
            Button {
                onSelect()
            } label: {
                Text(tab.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(accentColor)
            }
            .buttonStyle(.plain)
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(height: 28)
        .background(
            Capsule()
                .fill(isSelected ? Color.gray.opacity(0.95) : Color.gray.opacity(0.9))
        )
    }
}

// MARK: - Screen element – prostor za prikaz ekrana (tab sadržaj), od ruba do ruba
private struct ScreenElement: View {
    var selectedTab: BrowserTabItem?
    @Binding var initialSearchQuery: String?
    @Binding var currentAddress: String
    var onBackFromApp: (() -> Void)?
    var onOpenAppFromSearch: ((InstalledApp) -> Void)?
    var onSwitchToDevMode: (() -> Void)?

    var body: some View {
        Group {
            if let tab = selectedTab {
                switch tab.type {
                case .search:
                    EluminatiumView(initialSearchQuery: $initialSearchQuery, currentAddress: $currentAddress, onOpenAppFromSearch: onOpenAppFromSearch, onSwitchToDevMode: onSwitchToDevMode)
                case .empty:
                    Color.clear
                        .onAppear { currentAddress = "" }
                case .devMode:
                    DevModeView(currentAddress: $currentAddress)
                case .app(let app):
                    InstalledAppView(app: app, currentAddress: $currentAddress, onBack: onBackFromApp, onSwitchToDevMode: onSwitchToDevMode)
                }
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenEnvironment(isSelectedTab: true)
        .ignoresSafeArea(edges: [.bottom, .leading, .trailing])
    }
}

private struct CircleButton: View {
    let icon: String
    var action: () -> Void = {}
    private let accentColor = Color(hex: "ff5c00")

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(accentColor)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.white.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }
}

struct ContentView: View {
    @ObservedObject private var manager = ProfileManager.shared
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue
    @State private var tabs: [BrowserTabItem] = {
        let type: TabType
        switch AppSettings.onOpenAction {
        case .search, .webBrowser: type = .search
        case .empty: type = .empty
        case .devMode: type = .devMode
        }
        return [BrowserTabItem(id: UUID(), type: type)]
    }()
    @State private var selectedTabId: UUID?
    @State private var showSettings = false
    @State private var islandPhase2Expanded = false
    @State private var islandSearchQuery: String?
    @State private var currentAddress = ""

    private var selectedTab: BrowserTabItem? {
        if let id = selectedTabId, let tab = tabs.first(where: { $0.id == id }) {
            return tab
        }
        return tabs.first
    }
    
    var body: some View {
        ZStack {
            if showSettings {
                SettingsView(onClose: { showSettings = false })
            } else if manager.hasActiveProfile && !manager.showProfilePicker {
                mainContent(showSettings: $showSettings)
            } else {
                ProfilePickerView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(colorSchemeFromTheme)
        .onAppear {
            if selectedTabId == nil {
                selectedTabId = tabs.first?.id
            }
        }
    }
    
    private var colorSchemeFromTheme: ColorScheme? {
        guard let theme = AppTheme(rawValue: appThemeRaw) else { return nil }
        switch theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    private func mainContent(showSettings: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            // Bijeli element – tabovi + Island (sve kontrole u Islandu)
            ZStack {
                HStack(spacing: 12) {
                    ForEach(tabs) { tab in
                        BrowserTabView(
                            tab: tab,
                            isSelected: tab.id == selectedTabId,
                            onSelect: { selectedTabId = tab.id },
                            onClose: {
                                tabs.removeAll { $0.id == tab.id }
                                if tabs.isEmpty {
                                    NSApplication.shared.terminate(nil)
                                } else if selectedTabId == tab.id {
                                    selectedTabId = tabs.first?.id
                                }
                            }
                        )
                    }
                    Spacer(minLength: 0)
                }

                AlexandriaIsland(
                    isExpandedPhase2: $islandPhase2Expanded,
                    currentAddress: $currentAddress,
                    onOpenSettings: { showSettings.wrappedValue = true },
                    onOpenSearch: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if let searchTab = tabs.first(where: { $0.type == .search }) {
                                selectedTabId = searchTab.id
                            } else {
                                let newTab = BrowserTabItem(id: UUID(), type: .search)
                                tabs.append(newTab)
                                selectedTabId = newTab.id
                            }
                        }
                    },
                    onSubmitFromInsertBar: { query in
                        islandSearchQuery = query
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if let searchTab = tabs.first(where: { $0.type == .search }) {
                                selectedTabId = searchTab.id
                            } else {
                                let newTab = BrowserTabItem(id: UUID(), type: .search)
                                tabs.append(newTab)
                                selectedTabId = newTab.id
                            }
                        }
                    },
                    onOpenDevMode: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if let devTab = tabs.first(where: { $0.type == .devMode }) {
                                selectedTabId = devTab.id
                            } else {
                                let newTab = BrowserTabItem(id: UUID(), type: .devMode)
                                tabs.append(newTab)
                                selectedTabId = newTab.id
                            }
                        }
                    },
                    onOpenNewTab: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            let newTab = BrowserTabItem(id: UUID(), type: .empty)
                            tabs.append(newTab)
                            selectedTabId = newTab.id
                        }
                    },
                    onOpenAppFromLibrary: { app in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            let newTab = BrowserTabItem(id: UUID(), type: .app(app))
                            tabs.append(newTab)
                            selectedTabId = newTab.id
                        }
                    }
                )
                .zIndex(1)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white)
            .zIndex(10)

            // Screen element – sadržaj taba (ispod bijelog elementa)
            ScreenElement(
                selectedTab: selectedTab,
                initialSearchQuery: $islandSearchQuery,
                currentAddress: $currentAddress,
                onBackFromApp: {
                    if case .app = selectedTab?.type {
                        tabs.removeAll { $0.id == selectedTab?.id }
                        selectedTabId = tabs.first?.id
                    }
                },
                onOpenAppFromSearch: { app in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        let newTab = BrowserTabItem(id: UUID(), type: .app(app))
                        tabs.append(newTab)
                        selectedTabId = newTab.id
                    }
                },
                onSwitchToDevMode: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        if let devTab = tabs.first(where: { $0.type == .devMode }) {
                            selectedTabId = devTab.id
                        } else {
                            let newTab = BrowserTabItem(id: UUID(), type: .devMode)
                            tabs.append(newTab)
                            selectedTabId = newTab.id
                        }
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(0)
            .overlay {
                // Overlay samo na sadržaju – klik zatvara Island, ali NE blokira toolbar (Island input)
                if islandPhase2Expanded {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            islandPhase2Expanded = false
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .top)
        .background(AppBackgroundView().ignoresSafeArea())
        .overlay(
            WindowAccessor { window in
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.hasShadow = true
                window.contentView?.wantsLayer = true
                window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
            }
            .frame(width: 0, height: 0)
        )
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 600)
}
