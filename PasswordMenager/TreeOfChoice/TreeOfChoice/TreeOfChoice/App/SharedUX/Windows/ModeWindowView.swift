//
//  ModeWindowView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Glavni window view s tab bar-om za sve mode-ove i Tree Library
struct ModeWindowView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var selectedMode: AppView.AppMode?
    @State private var selectedTabId: UUID?
    @State private var tabs: [TabItem]
    var sessionStore: SessionStore?
    
    init(selectedMode: Binding<AppView.AppMode?>, initialTab: ModeTab = .labConnect, sessionStore: SessionStore? = nil) {
        self._selectedMode = selectedMode
        self.sessionStore = sessionStore
        let initialTabItem = TabItem(tab: initialTab)
        _selectedTabId = State(initialValue: initialTabItem.id)
        _tabs = State(initialValue: [initialTabItem])
    }
    
    private var selectedTab: ModeTab? {
        tabs.first(where: { $0.id == selectedTabId })?.tab
    }
    
    // Tab item with custom name support
    class TabItem: Identifiable, ObservableObject {
        let id = UUID()
        var tab: ModeTab
        @Published var customName: String?
        
        var displayName: String {
            customName ?? tab.title
        }
        
        init(tab: ModeTab, customName: String? = nil) {
            self.tab = tab
            self.customName = customName
        }
    }
    
    enum ModeTab: Identifiable, Hashable {
        case labConnect
        case labSecurity
        case realConnect
        case realSecurity
        case treeLibrary
        case treeCreator
        
        var id: Self { self }
        
        var title: String {
            switch self {
            case .labConnect: return "Lab Connect"
            case .labSecurity: return "Lab Security"
            case .realConnect: return "Real Connect"
            case .realSecurity: return "Real Security"
            case .treeLibrary: return "Tree Library"
            case .treeCreator: return "Tree Creator"
            }
        }
        
        var localizedTitle: String {
            switch self {
            case .labConnect: return "mode.labConnect.title"
            case .labSecurity: return "mode.labSecurity.title"
            case .realConnect: return "mode.realConnect.title"
            case .realSecurity: return "mode.realSecurity.title"
            case .treeLibrary: return "treeLibrary.title"
            case .treeCreator: return "treeCreator.title"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
            
            VStack(spacing: 0) {
                // Tab Bar
                tabBarView
                
                // Content
                contentView
            }
        }
        .frame(minWidth: 1400, minHeight: 900)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WindowAccessor { window in
            // Spremi referencu na prozor za minimizaciju
            if let window = window {
                cachedWindow = window
            }
        })
        .onAppear {
            #if os(macOS)
            // Također pokušaj pronaći prozor kada se view pojavi
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if cachedWindow == nil {
                    if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.mainWindow {
                        cachedWindow = window
                    }
                }
            }
            #endif
        }
    }
    
    #if os(macOS)
    @State private var cachedWindow: NSWindow?
    #endif
    
    // MARK: - Tab Bar
    
    private var tabBarView: some View {
        HStack(spacing: 0) {
            // macOS window controls (left side)
            macOSWindowControls
            
            // Existing tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(tabs) { tabItem in
                        TabItemView(
                            tabItem: tabItem,
                            isSelected: selectedTabId == tabItem.id,
                            localization: localization,
                            onRename: { newName in
                                renameTab(tabItem, newName: newName)
                            }
                        ) {
                            selectedTabId = tabItem.id
                        } onClose: {
                            closeTab(tabItem)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Add new tab buttons (5 buttons for each mode + Tree Library)
            newTabButtons
            
            // Home button
            homeButton
        }
        .frame(height: 40)
        .background(Color.black.opacity(0.8))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var macOSWindowControls: some View {
        HStack(spacing: 8) {
            // Close button (red) - prekini sve i vrati se na home
            Button(action: {
                closeToHome()
            }) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.black.opacity(0.6))
                    )
            }
            .buttonStyle(.plain)
            .help("Close and return to home")
            
            // Home button (green-like, but using house icon)
            Button(action: {
                // Ažuriraj sesiju prije izlaska
                if let sessionStore = sessionStore, let currentSession = sessionStore.activeSessions.last {
                    sessionStore.updateSession(currentSession)
                }
                selectedMode = nil
            }) {
                Circle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Image(systemName: "house.fill")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(.black.opacity(0.6))
                    )
            }
            .buttonStyle(.plain)
            .help("Back to home")
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
    }
    
    private var newTabButtons: some View {
        HStack(spacing: 4) {
            // Lab Connect
            newTabButton(for: .labConnect, icon: "network")
            
            // Lab Security
            newTabButton(for: .labSecurity, icon: "shield")
            
            // Real Connect
            newTabButton(for: .realConnect, icon: "network")
            
            // Real Security
            newTabButton(for: .realSecurity, icon: "lock.shield")
            
            // Tree Library
            newTabButton(for: .treeLibrary, icon: "tree")
            
            // Tree Creator
            newTabButton(for: .treeCreator, icon: "decision")
        }
        .padding(.trailing, 8)
    }
    
    private func newTabButton(for tab: ModeTab, icon: String) -> some View {
        Button(action: {
            addTab(tab)
        }) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .help(localization.text(tab.localizedTitle))
    }
    
    private var homeButton: some View {
        Button(action: {
            // Ažuriraj sesiju prije izlaska
            if let sessionStore = sessionStore, let currentSession = sessionStore.activeSessions.last {
                sessionStore.updateSession(currentSession)
            }
            selectedMode = nil
        }) {
            Image(systemName: "house.fill")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .help(localization.text("modeWindow.backToHome"))
        .padding(.trailing, 12)
    }
    
    private var contentView: some View {
        Group {
            if let tab = selectedTab {
                switch tab {
                case .labConnect:
                    LabConnectView()
                        .environmentObject(localization)
                case .labSecurity:
                    LabSecurityView()
                        .environmentObject(localization)
                case .realConnect:
                    RealConnectView()
                        .environmentObject(localization)
                case .realSecurity:
                    RealSecurityView()
                        .environmentObject(localization)
                case .treeLibrary:
                    TreeLibraryView()
                        .environmentObject(localization)
                case .treeCreator:
                    TreeCreatorView()
                        .environmentObject(localization)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func showNewTabMenu() {
        // This function is no longer needed since we have individual buttons
        // But keeping it for compatibility
    }
    
    private func addTab(_ tab: ModeTab) {
        // Always allow adding new tab (even duplicates)
        let newTabItem = TabItem(tab: tab)
        tabs.append(newTabItem)
        selectedTabId = newTabItem.id
    }
    
    private func closeTab(_ tabItem: TabItem) {
        guard tabs.count > 1 else {
            // If last tab, go back to home
            // Ažuriraj sesiju prije izlaska
            if let sessionStore = sessionStore, let currentSession = sessionStore.activeSessions.last {
                sessionStore.updateSession(currentSession)
            }
            selectedMode = nil
            return
        }
        
        if let index = tabs.firstIndex(where: { $0.id == tabItem.id }) {
            let wasSelected = selectedTabId == tabItem.id
            tabs.remove(at: index)
            
            // Select another tab if closed tab was selected
            if wasSelected {
                if let lastTab = tabs.last {
                    selectedTabId = lastTab.id
                } else if let firstTab = tabs.first {
                    selectedTabId = firstTab.id
                }
            }
        }
    }
    
    private func closeToHome() {
        // Obriši sesiju iz Active Sessions
        if let sessionStore = sessionStore {
            // Pronađi sesiju za trenutni mod i obriši je
            if let currentTab = tabs.first(where: { $0.id == selectedTabId }) {
                let modeType = mapTabToSessionModeType(currentTab.tab)
                if let session = sessionStore.findSession(modeType: modeType) {
                    sessionStore.deleteSession(session)
                }
            }
        }
        
        // Vrati se na home (ne zatvaraj aplikaciju)
        selectedMode = nil
    }
    
    private func mapTabToSessionModeType(_ tab: ModeTab) -> SessionModeType {
        switch tab {
        case .labConnect: return .labConnect
        case .labSecurity: return .labSecurity
        case .realConnect: return .realConnect
        case .realSecurity: return .realSecurity
        case .treeLibrary: return .treeLibrary
        case .treeCreator: return .treeCreator
        }
    }
    
    private func renameTab(_ tabItem: TabItem, newName: String) {
        if let index = tabs.firstIndex(where: { $0.id == tabItem.id }) {
            if newName.isEmpty {
                tabs[index].customName = nil
            } else {
                tabs[index].customName = newName
            }
        }
    }
}


// MARK: - Tab Item View

struct TabItemView: View {
    @ObservedObject var tabItem: ModeWindowView.TabItem
    let isSelected: Bool
    let localization: LocalizationManager
    let onRename: (String) -> Void
    let onTap: () -> Void
    let onClose: () -> Void
    
    @State private var isHovered = false
    @State private var showRenameField = false
    @State private var editingTitle: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if showRenameField {
                    TextField("", text: $editingTitle)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .frame(width: 120)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            finishRename()
                        }
                        .onAppear {
                            editingTitle = tabItem.displayName
                            isTextFieldFocused = true
                        }
                        .onExitCommand {
                            cancelRename()
                        }
                } else {
                    Text(displayTitle)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                        .lineLimit(1)
                        .frame(minWidth: 80, maxWidth: 150, alignment: .leading)
                }
                
                // Rename button (shown on hover)
                if isHovered && isSelected && !showRenameField {
                    Button(action: {
                        showRenameField = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                
                // Close button
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            // Double click to rename
            if isSelected {
                showRenameField = true
            }
        }
    }
    
    private var displayTitle: String {
        if let customName = tabItem.customName, !customName.isEmpty {
            return customName
        }
        return localization.text(tabItem.tab.localizedTitle)
    }
    
    private func finishRename() {
        showRenameField = false
        onRename(editingTitle)
    }
    
    private func cancelRename() {
        showRenameField = false
        editingTitle = tabItem.displayName
    }
}

// MARK: - Window Accessor Helper

#if os(macOS)
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                callback(window)
            }
        }
    }
}
#endif

