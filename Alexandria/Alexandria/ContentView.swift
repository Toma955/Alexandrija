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

// MARK: - Brušeno staklo (blur + tamni overlay)
private struct FrostedGlassBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = .behindWindow
        v.state = .active
        v.appearance = NSAppearance(named: .vibrantDark)
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.appearance = NSAppearance(named: .vibrantDark)
    }
}

// MARK: - Tab model
private enum TabType {
    case empty
    case search
}

private struct TabItem: Identifiable {
    let id: UUID
    let type: TabType
    var title: String {
        switch type {
        case .empty: return "Novi tab"
        case .search: return "Pretraži"
        }
    }
}

// MARK: - Tab (kvadrat s natpisom)
private struct TabView: View {
    let tab: TabItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    private let accentColor = Color(hex: "ff5c00")

    var body: some View {
        HStack(spacing: 4) {
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
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.gray.opacity(0.95) : Color.gray.opacity(0.9))
        )
    }
}

// MARK: - Lijevi element: obli kvadrat s 2 kruga (search, plus)
private struct LeftSideElement: View {
    let onPlusTap: () -> Void
    let onSearchTap: () -> Void
    private let accentColor = Color(hex: "ff5c00")

    var body: some View {
        HStack(spacing: 6) {
            CircleButton(icon: "magnifyingglass", action: onSearchTap)  // search → Eluminatium
            CircleButton(icon: "plus", action: onPlusTap)
        }
        .padding(6)
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray)
        )
    }
}

// MARK: - Screen element – prostor za prikaz ekrana (tab sadržaj), od ruba do ruba
private struct ScreenElement: View {
    var selectedTab: TabItem?

    var body: some View {
        Group {
            if let tab = selectedTab {
                switch tab.type {
                case .search:
                    EluminatiumView()
                case .empty:
                    Color.clear
                }
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    @State private var tabs: [TabItem] = [TabItem(id: UUID(), type: .empty)]
    @State private var selectedTabId: UUID?

    private var selectedTab: TabItem? {
        if let id = selectedTabId, let tab = tabs.first(where: { $0.id == id }) {
            return tab
        }
        return tabs.first
    }

    var body: some View {
        VStack(spacing: 0) {
            // Gornji bar: tabovi lijevo, Alexandria Island fiksno u sredini
            ZStack {
                HStack(spacing: 12) {
                    ForEach(tabs) { tab in
                        TabView(
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

                    LeftSideElement(
                        onPlusTap: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                let newTab = TabItem(id: UUID(), type: .empty)
                                tabs.append(newTab)
                                selectedTabId = newTab.id
                            }
                        },
                        onSearchTap: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                let newTab = TabItem(id: UUID(), type: .search)
                                tabs.append(newTab)
                                selectedTabId = newTab.id
                            }
                        }
                    )

                    Spacer(minLength: 0)
                }

                AlexandriaIsland(
                    onOpenSearch: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            let newTab = TabItem(id: UUID(), type: .search)
                            tabs.append(newTab)
                            selectedTabId = newTab.id
                        }
                    },
                    onOpenNewTab: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            let newTab = TabItem(id: UUID(), type: .empty)
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

            // Screen element – od ruba do ruba, počinje odmah ispod bijelog bara
            ScreenElement(selectedTab: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .top)
        .background(
            ZStack {
                FrostedGlassBackground().ignoresSafeArea()
                Color.black.opacity(0.35).ignoresSafeArea()  // tamni overlay – jače zatamni
            }
        )
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
