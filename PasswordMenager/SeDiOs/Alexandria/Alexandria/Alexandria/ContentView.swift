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

// MARK: - Tab = jedan objekt (pill + proširenje dole); naslov na sredini, hover → lijevo + X
private struct BrowserTabView: View {
    let tab: BrowserTabItem
    let isSelected: Bool
    let isExpanded: Bool
    let onSelect: () -> Void
    let onExpand: () -> Void
    let onClose: () -> Void
    @State private var isHovering = false
    private static let tabW: CGFloat = 152
    private static let tabH: CGFloat = 36
    private static let fontSz: CGFloat = 11
    private static let hoverAnimation: Animation = .spring(response: 0.32, dampingFraction: 0.78)

    var body: some View {
        HStack(spacing: 8) {
            Button { onSelect(); onExpand() } label: {
                Text(tab.title)
                    .font(.system(size: Self.fontSz, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: isHovering ? .leading : .center)
                    .padding(.trailing, isHovering ? 24 : 0)
            }
            .buttonStyle(.plain)

            Button { onClose() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.9))
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
            .frame(width: isHovering ? nil : 0, height: 22)
            .clipped()
            .allowsHitTesting(isHovering)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minWidth: Self.tabW, maxWidth: Self.tabW)
        .frame(height: Self.tabH)
        .background(Capsule().fill(Color.white))
        .animation(Self.hoverAnimation, value: isHovering)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Tab = isto kao Island: jedan view, sadržaj unutra, .frame(height: isExpanded ? nil : 36)
private struct TabViewOneElement: View {
    let tab: BrowserTabItem
    let isSelected: Bool
    let isExpanded: Bool
    let onSelect: () -> Void
    let onExpand: () -> Void
    let onClose: () -> Void

    private static let tabW: CGFloat = 152
    private static let pillH: CGFloat = 36
    private static let expandAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.8)

    var body: some View {
        VStack(spacing: isExpanded ? 8 : 0) {
            BrowserTabView(
                tab: tab,
                isSelected: isSelected,
                isExpanded: isExpanded,
                onSelect: onSelect,
                onExpand: {
                    withAnimation(Self.expandAnimation) { onExpand() }
                },
                onClose: onClose
            )

            if isExpanded {
                TabExpandedBody(tabTitle: tab.title)
                    .padding(.top, 4)
            }
        }
        .frame(width: Self.tabW, height: isExpanded ? nil : Self.pillH)
        .animation(Self.expandAnimation, value: isExpanded)
        .background(
            Group {
                if isExpanded {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                } else {
                    Capsule().fill(Color.white)
                }
            }
        )
    }
}

// MARK: - Traka: crni kvadrat 48pt + tabovi (kao Island – svaki tab jedan view koji se samo produžuje)
private struct TabBarView: View {
    let tabs: [BrowserTabItem]
    @Binding var selectedTabId: UUID?
    @Binding var expandedTabId: UUID?
    var onRemoveTab: (BrowserTabItem) -> Void

    private static let spacing: CGFloat = 12
    private static let leadingPad: CGFloat = 16
    private static let barHeight: CGFloat = 48
    private static let expandAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.8)

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .frame(maxWidth: .infinity)
                .frame(height: Self.barHeight)

            HStack(alignment: .top, spacing: Self.spacing) {
                ForEach(tabs) { tab in
                    TabViewOneElement(
                        tab: tab,
                        isSelected: tab.id == selectedTabId,
                        isExpanded: expandedTabId == tab.id,
                        onSelect: { selectedTabId = tab.id },
                        onExpand: {
                            withAnimation(Self.expandAnimation) {
                                expandedTabId = expandedTabId == tab.id ? nil : tab.id
                            }
                        },
                        onClose: { onRemoveTab(tab) }
                    )
                }
                Spacer(minLength: 0)
            }
            .padding(.leading, Self.leadingPad)
            .padding(.trailing, Self.leadingPad)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - Tijelo proširenog taba – sekcije za postavke, obavijesti, pozive, poruke, music player itd.
private struct TabExpandedBody: View {
    let tabTitle: String
    @AppStorage("tabSettingSound") private var soundEnabled = true
    @AppStorage("tabSettingRAM") private var ramEnabled = true
    @AppStorage("tabSettingMic") private var micEnabled = false
    @AppStorage("tabSettingCamera") private var cameraEnabled = false
    private static let w: CGFloat = 152
    private static let fontSz: CGFloat = 9

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Naslov taba
            Text(tabTitle)
                .font(.system(size: Self.fontSz, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(1)

            // Sekcija: Postavke (zvuk, RAM, mik, kamera, gumbi)
            TabExpandedSection {
                VStack(alignment: .leading, spacing: 2) {
                    TabPanelToggleRow(label: "Zvuk", icon: "speaker.wave.2", isOn: $soundEnabled, fontSz: Self.fontSz)
                    TabPanelToggleRow(label: "RAM", icon: "memorychip", isOn: $ramEnabled, fontSz: Self.fontSz)
                    TabPanelToggleRow(label: "Mikrofon", icon: "mic", isOn: $micEnabled, fontSz: Self.fontSz)
                    TabPanelToggleRow(label: "Kamera", icon: "camera", isOn: $cameraEnabled, fontSz: Self.fontSz)
                }
                HStack(spacing: 5) {
                    TabPanelRoundButton(icon: "info.circle", action: {}, fontSz: Self.fontSz)
                    TabPanelRoundButton(icon: "speedometer", action: {}, fontSz: Self.fontSz)
                    TabPanelRoundButton(icon: "gearshape", action: {}, fontSz: Self.fontSz)
                }
            }

            // Buduće sekcije: obavijesti, pozivi, poruke, music player – dodati ovdje
            // TabExpandedSection { NotificationsRow() }
            // TabExpandedSection { CallsRow() }
            // TabExpandedSection { MessagesRow() }
            // TabExpandedSection { MusicPlayerMini() }
        }
        .padding(8)
        .frame(width: Self.w, alignment: .leading)
    }
}

/// Jedna sekcija unutar proširenog taba (koristi se za postavke, obavijesti, pozive, itd.)
private struct TabExpandedSection<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
    }
}

// MARK: - Red s Toggleom (mali font)
private struct TabPanelToggleRow: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool
    var fontSz: CGFloat = 9

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: fontSz - 1))
                .foregroundColor(.black.opacity(0.7))
                .frame(width: 12, alignment: .center)
            Text(label)
                .font(.system(size: fontSz))
                .foregroundColor(.black)
            Spacer(minLength: 2)
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
    }
}

// MARK: - Mali okrugli gumb
private struct TabPanelRoundButton: View {
    let icon: String
    let action: () -> Void
    var fontSz: CGFloat = 9
    private var accentColor: Color { AlexandriaTheme.accentColor }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: fontSz))
                .foregroundColor(accentColor)
                .frame(width: 20, height: 20)
                .background(Circle().fill(accentColor.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Screen element – prostor za prikaz ekrana (tab sadržaj), od ruba do ruba
private struct ScreenElement: View {
    var selectedTab: BrowserTabItem?
    @Binding var initialSearchQuery: String?
    @Binding var currentAddress: String
    var setBackAction: (((() -> Void)?) -> Void)?
    var tabPanelExpanded: Bool = false
    var onCloseTabPanel: (() -> Void)?
    var onBackFromApp: (() -> Void)?
    var onOpenAppFromSearch: ((InstalledApp) -> Void)?
    var onSwitchToDevMode: (() -> Void)?

    var body: some View {
        Group {
            if let tab = selectedTab {
                switch tab.type {
                case .search:
                    EluminatiumView(initialSearchQuery: $initialSearchQuery, currentAddress: $currentAddress, onOpenAppFromSearch: onOpenAppFromSearch, onSwitchToDevMode: onSwitchToDevMode, setBackAction: setBackAction)
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
        .overlay {
            if tabPanelExpanded {
                Color.clear
                    .contentShape(Rectangle())
                    .onHover { _ in onCloseTabPanel?() }
            }
        }
    }
}

private struct CircleButton: View {
    let icon: String
    var action: () -> Void = {}
    private var accentColor: Color { AlexandriaTheme.accentColor }

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
    /// Akcija za Island „Nazad” kad je u Eluminatiumu otvoren app u kartici (postavlja Eluminatium).
    @State private var islandBackAction: (() -> Void)? = nil
    /// Tab čiji se postavke prikazuju ispod trake (klik na tab → proširi prema dolje).
    @State private var expandedTabId: UUID? = nil

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
        ZStack(alignment: .top) {
            // Sloj 0 (najmanji): centralni sadržaj
            VStack(spacing: 0) {
                Color.clear.frame(height: 48)
                ScreenElement(
                    selectedTab: selectedTab,
                    initialSearchQuery: $islandSearchQuery,
                    currentAddress: $currentAddress,
                    setBackAction: { islandBackAction = $0 },
                    tabPanelExpanded: expandedTabId != nil,
                    onCloseTabPanel: { expandedTabId = nil },
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
                .overlay {
                    if islandPhase2Expanded {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture { islandPhase2Expanded = false }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(0)

            // Sloj 1: jedan element – traka + tabovi + prošireni panel (kao Island)
            TabBarView(
                tabs: tabs,
                selectedTabId: $selectedTabId,
                expandedTabId: $expandedTabId,
                onRemoveTab: { tab in
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.92)) {
                        tabs.removeAll { $0.id == tab.id }
                        if expandedTabId == tab.id { expandedTabId = nil }
                        if tabs.isEmpty {
                            NSApplication.shared.terminate(nil)
                        } else if selectedTabId == tab.id {
                            selectedTabId = tabs.first?.id
                        }
                    }
                }
            )
            .frame(maxWidth: .infinity, alignment: .top)
            .zIndex(1)

            // Sloj 2 (najveći): Island – ništa iznad Islanda
            AlexandriaIsland(
                isExpandedPhase2: $islandPhase2Expanded,
                currentAddress: $currentAddress,
                onBack: {
                    if case .app = selectedTab?.type {
                        tabs.removeAll { $0.id == selectedTab?.id }
                        selectedTabId = tabs.first?.id
                    } else {
                        islandBackAction?()
                    }
                },
                onForward: nil,
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
                        let type: TabType
                        switch AppSettings.onOpenAction {
                        case .search, .webBrowser: type = .search
                        case .empty: type = .empty
                        case .devMode: type = .devMode
                        }
                        let newTab = BrowserTabItem(id: UUID(), type: type)
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
            .frame(maxWidth: .infinity, alignment: .top)
            .zIndex(3)
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
