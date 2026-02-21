//
//  ContentView.swift
//  Alexandria
//
//  Created by Toma Babić on 13.02.2026..
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

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

// MARK: - Tab hijerarhija (parent → children, slojevi)
//
// ContentView (root)
// ├── mainContent ZStack (slojevi odozdo prema gore):
// │   ├── Sloj 0: VStack [ spacer 48pt, ScreenElement ]     — sadržaj ekrana
// │   ├── Sloj 1: TabBarView                               — traka + tabovi
// │   └── Sloj 2: AlexandriaIsland                        — address bar, pretraga
// │
// TabBarView (parent: ContentView)
// └── children: TabViewOneElement (po jedan po tabu)
//
// TabViewOneElement (parent: TabBarView) — jedan “kartica” taba (pill + proširenje)
// ├── child: BrowserTabView   — pill (naslov + X)
// └── child: TabExpandedBody  — prošireni panel (kad je isExpanded)
//
// TabExpandedBody (parent: TabViewOneElement)
// └── children: TabExpandedSection, toggles, gumbi
//

/// Prefiks za pasteboard pri dragu taba (swap u traci ili nova instanca pri dropu izvan trake).
private let kAlexandriaTabDragPrefix = "alexandria-tab:"

// MARK: - Tab zajedničke konstante (jedan izvor istine za traku i tabove)
private enum TabBarConstants {
    static let tabWidth: CGFloat = 152
    static let pillHeight: CGFloat = 36
    static let barHeight: CGFloat = 48
    static let barLeadingPad: CGFloat = 16
    static let tabSpacing: CGFloat = 12
    static let expandAnimation: Animation = .spring(response: 0.58, dampingFraction: 0.78)
    /// Za odabrani tab: polumjer zaobljenja samo gornjih kutova.
    static let selectedTabTopCornerRadius: CGFloat = 14
}

// MARK: - Oblik s zaobljenim samo gornjim kutovima (donji do dna = efekt značenosti)
private struct TopRoundedRectangle: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, rect.width / 2, rect.height)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

// MARK: - Tab model

/// Stanje overlay-a kad tab NIJE prikazan u sredini: poziv, glazba ili poruka.
enum TabOverlayState: Equatable {
    case none
    /// Npr. WhatsApp poziv – tko zove; na približavanje proširi s Prihvati / Odbij / Zanemari.
    case incomingCall(callerName: String)
    /// Glazba se reproducira – naziv; na hover proširi s play/pause/next/repeat.
    case playingMusic(trackName: String, artist: String?)
    /// Nova poruka – pošiljatelj i pregled; na približavanje (kao Island) proširi dole s poljem za odgovor.
    case message(senderName: String, preview: String)
}

private enum TabType: Equatable {
    case empty
    case search
    case app(InstalledApp)
    case devMode
}

private struct BrowserTabItem: Identifiable {
    let id: UUID
    let type: TabType
    /// Opcijska SF Symbol ikona (npr. "globe", "message.fill"); nil = samo naslov.
    var icon: String?

    init(id: UUID, type: TabType, icon: String? = nil) {
        self.id = id
        self.type = type
        self.icon = icon
    }

    var title: String {
        switch type {
        case .empty: return "Novi tab"
        case .search: return "Pretraži"
        case .app(let app): return app.name
        case .devMode: return "Dev Mode"
        }
    }
}

// MARK: - BrowserTabView (child of TabViewOneElement) — pill: opcijska ikona + naslov + X na hover
private struct BrowserTabView: View {
    let tab: BrowserTabItem
    let isSelected: Bool
    let isExpanded: Bool
    /// Jedan tap: parent odlučuje (prvi klik = prikaži u sredini, drugi klik = otvori Island).
    let onTap: () -> Void
    let onClose: () -> Void
    @State private var isHovering = false
    private static let fontSz: CGFloat = 11
    private static let iconSz: CGFloat = 12
    private static let hoverAnimation: Animation = .spring(response: 0.32, dampingFraction: 0.78)

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onTap) {
                HStack(spacing: 6) {
                    if let icon = tab.icon {
                        Image(systemName: icon)
                            .font(.system(size: Self.iconSz))
                            .foregroundColor(.black.opacity(0.85))
                            .frame(width: 14, height: 14, alignment: .center)
                    }
                    Text(tab.title)
                        .font(.system(size: Self.fontSz, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: isHovering ? .leading : .center)
                }
                .padding(.trailing, isHovering ? 24 : 0)
                .frame(maxWidth: .infinity, maxHeight: isSelected ? .infinity : nil, alignment: .top)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onClose) {
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
        .frame(minWidth: TabBarConstants.tabWidth, maxWidth: TabBarConstants.tabWidth)
        .frame(height: TabBarConstants.pillHeight)
        .background(Capsule().fill(Color.white))
        .animation(Self.hoverAnimation, value: isHovering)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Overlay proširenje: gumbi za poziv (kad tab nije prikazan u sredini)
private struct TabOverlayCallActions: View {
    let callerName: String
    var onAccept: () -> Void = {}
    var onReject: () -> Void = {}
    var onIgnore: () -> Void = {}
    private static let fontSz: CGFloat = 9

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(callerName) zove")
                .font(.system(size: Self.fontSz, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(1)
            HStack(spacing: 8) {
                Button(action: onAccept) {
                    Label("Prihvati", systemImage: "phone.fill")
                        .font(.system(size: Self.fontSz))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                Button(action: onReject) {
                    Label("Odbij", systemImage: "phone.down.fill")
                        .font(.system(size: Self.fontSz))
                }
                .buttonStyle(.bordered)
                Button(action: onIgnore) {
                    Label("Zanemari", systemImage: "minus.circle")
                        .font(.system(size: Self.fontSz))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(8)
        .frame(width: TabBarConstants.tabWidth, alignment: .leading)
    }
}

// MARK: - Overlay proširenje: play/pause/next/repeat (kad tab nije prikazan)
private struct TabOverlayMusicControls: View {
    let trackName: String
    let artist: String?
    var onPlayPause: () -> Void = {}
    var onNext: () -> Void = {}
    var onRepeat: () -> Void = {}
    private static let fontSz: CGFloat = 9

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(trackName)
                    .font(.system(size: Self.fontSz, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                if let a = artist, !a.isEmpty {
                    Text(a)
                        .font(.system(size: Self.fontSz - 1))
                        .foregroundColor(.black.opacity(0.7))
                        .lineLimit(1)
                }
            }
            HStack(spacing: 8) {
                Button(action: onPlayPause) {
                    Image(systemName: "playpause.fill")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                Button(action: onRepeat) {
                    Image(systemName: "repeat")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(.black)
        }
        .padding(8)
        .frame(width: TabBarConstants.tabWidth, alignment: .leading)
    }
}

// MARK: - Overlay proširenje: poruka + polje za odgovor dole (kao Island, na hover)
private struct TabOverlayMessageView: View {
    let senderName: String
    let preview: String
    @State private var replyText: String = ""
    var onSendReply: (String) -> Void = { _ in }
    private static let fontSz: CGFloat = 9

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(senderName)
                    .font(.system(size: Self.fontSz, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                Text(preview)
                    .font(.system(size: Self.fontSz))
                    .foregroundColor(.black.opacity(0.8))
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            HStack(spacing: 6) {
                TextField("Odgovor...", text: $replyText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: Self.fontSz))
                Button(action: {
                    let t = replyText
                    replyText = ""
                    onSendReply(t)
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(replyText.isEmpty ? .gray : AlexandriaTheme.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(replyText.isEmpty)
            }
        }
        .padding(8)
        .frame(width: TabBarConstants.tabWidth, alignment: .leading)
    }
}

// MARK: - TabViewOneElement (child of TabBarView): pill + proširenje (postavke ILI overlay call/music/poruka)
private struct TabViewOneElement: View {
    let tab: BrowserTabItem
    let isSelected: Bool
    let isExpanded: Bool
    let overlayState: TabOverlayState
    let onSelect: () -> Void
    let onExpand: () -> Void
    /// Kad je tab već u fokusu i user ponovno klikne na njega → otvori Island.
    let onSelectedAgain: () -> Void
    let onClose: () -> Void
    @State private var isOverlayHoverExpanded = false

    private var isOverlayActive: Bool { !isSelected && overlayState != .none }

    var body: some View {
        VStack(spacing: currentExpandSpacing) {
            if isOverlayActive {
                overlayPillContent
            } else {
                BrowserTabView(
                    tab: tab,
                    isSelected: isSelected,
                    isExpanded: isExpanded,
                    onTap: {
                        if isSelected {
                            withAnimation(TabBarConstants.expandAnimation) { onExpand() }
                        } else {
                            onSelect()
                            withAnimation(TabBarConstants.expandAnimation) { onExpand() }
                        }
                    },
                    onClose: onClose
                )
                .frame(maxHeight: (isSelected && !isExpanded) ? TabBarConstants.barHeight : nil)
                .contentShape(Rectangle())
            }

            if isOverlayActive && isOverlayHoverExpanded {
                overlayExpandedContent
                    .padding(.top, 4)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .frame(width: TabBarConstants.tabWidth)
        .frame(height: isSelected && !isOverlayActive ? TabBarConstants.barHeight : TabBarConstants.pillHeight, alignment: isSelected && !isOverlayActive ? .top : .center)
        .clipped()
        .animation(TabBarConstants.expandAnimation, value: isExpanded)
        .animation(TabBarConstants.expandAnimation, value: isOverlayHoverExpanded)
        .background(backgroundShape.allowsHitTesting(false))
        .onHover { hovering in
            if isOverlayActive { isOverlayHoverExpanded = hovering }
        }
    }

    private var currentExpandSpacing: CGFloat {
        if isOverlayActive { return isOverlayHoverExpanded ? 8 : 0 }
        return isExpanded ? 8 : 0
    }

    private var overlayPillContent: some View {
        Button {
            if isSelected {
                withAnimation(TabBarConstants.expandAnimation) { onExpand() }
            } else {
                onSelect()
                withAnimation(TabBarConstants.expandAnimation) { onExpand() }
            }
        } label: {
            HStack(spacing: 6) {
                overlayPillIcon
                Text(overlayPillTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .frame(minWidth: TabBarConstants.tabWidth, maxWidth: TabBarConstants.tabWidth)
        .frame(height: TabBarConstants.pillHeight)
        .background(Capsule().fill(Color.white))
    }

    private var overlayPillIcon: some View {
        Group {
            switch overlayState {
            case .none:
                EmptyView()
            case .incomingCall:
                Image(systemName: "phone.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            case .playingMusic:
                Image(systemName: "music.note")
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.85))
            case .message:
                Image(systemName: "message.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 14, height: 14, alignment: .center)
    }

    private var overlayPillTitle: String {
        switch overlayState {
        case .none: return tab.title
        case .incomingCall(let name): return name
        case .playingMusic(let track, _): return track
        case .message(let sender, _): return sender
        }
    }

    @ViewBuilder
    private var overlayExpandedContent: some View {
        switch overlayState {
        case .none:
            EmptyView()
        case .incomingCall(let callerName):
            TabOverlayCallActions(callerName: callerName, onAccept: {}, onReject: {}, onIgnore: {})
        case .playingMusic(let trackName, let artist):
            TabOverlayMusicControls(trackName: trackName, artist: artist, onPlayPause: {}, onNext: {}, onRepeat: {})
        case .message(let senderName, let preview):
            TabOverlayMessageView(senderName: senderName, preview: preview, onSendReply: { _ in })
        }
    }

    private var backgroundShape: some View {
        Group {
            let expanded = (isSelected && isExpanded) || (isOverlayActive && isOverlayHoverExpanded)
            if expanded {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
            } else if isSelected && !isOverlayActive {
                TopRoundedRectangle(cornerRadius: TabBarConstants.selectedTabTopCornerRadius)
                    .fill(Color.white)
            } else {
                Capsule().fill(Color.white)
            }
        }
        .animation(TabBarConstants.expandAnimation, value: isExpanded)
        .animation(TabBarConstants.expandAnimation, value: isOverlayHoverExpanded)
    }
}

// MARK: - Krug s plusom do tabova (u budućnosti proširiv u zaobljeni kvadrat: plus / Google / YouTube itd.)
private struct TabBarAddButton: View {
    var action: () -> Void = {}
    private static let size: CGFloat = 36
    private static let iconSz: CGFloat = 16

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: Self.iconSz, weight: .medium))
                .foregroundColor(.white)
                .frame(width: Self.size, height: Self.size)
                .background(Circle().fill(Color.white.opacity(0.25)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Zaobljeni kvadrat u desnom kutu: Sig/in se pretvori u panel (kao Island)
private struct TabBarCornerSignIn: View {
    @Binding var isExpanded: Bool
    @AppStorage("tabBarIncognito") private var incognito = false
    @AppStorage("tabBarHighSecureMode") private var highSecureMode = false
    private static let pillH: CGFloat = 36
    private static let cornerRadius: CGFloat = 12
    private static let fontSz: CGFloat = 11
    private static let w: CGFloat = 72
    private static let expandedWidth: CGFloat = 260
    private static let expandedPadding: CGFloat = 18
    private static let expandedSpacing: CGFloat = 14
    private static let expandedFontSz: CGFloat = 14
    private static let expandedIconSz: CGFloat = 16
    private static let expandedCornerRadius: CGFloat = 16

    var body: some View {
        Group {
            if isExpanded {
                expandedPanel
            } else {
                pillButton
            }
        }
        .frame(width: isExpanded ? Self.expandedWidth : Self.w)
        .frame(maxHeight: isExpanded ? .infinity : Self.pillH)
        .clipped()
        .animation(TabBarConstants.expandAnimation, value: isExpanded)
    }

    private var pillButton: some View {
        Button {
            withAnimation(TabBarConstants.expandAnimation) { isExpanded = true }
        } label: {
            Text("Sig/in")
                .font(.system(size: Self.fontSz, weight: .medium))
                .foregroundColor(.white)
                .frame(height: Self.pillH)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: Self.cornerRadius).fill(Color.white.opacity(0.25)))
        }
        .buttonStyle(.plain)
        .frame(alignment: .trailing)
    }

    private var expandedPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(TabBarConstants.expandAnimation) { isExpanded = false }
            } label: {
                Text("Sig/in")
                    .font(.system(size: Self.expandedFontSz, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, Self.expandedPadding)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: Self.expandedSpacing) {
                HStack(spacing: 12) {
                    Image(systemName: "theatermasks")
                        .font(.system(size: Self.expandedIconSz))
                        .foregroundColor(.black.opacity(0.8))
                        .frame(width: 24, alignment: .center)
                    Text("Incognito")
                        .font(.system(size: Self.expandedFontSz, weight: .medium))
                        .foregroundColor(.black)
                    Spacer(minLength: 8)
                    Toggle("", isOn: $incognito)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(.vertical, 4)

                HStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: Self.expandedIconSz))
                        .foregroundColor(.black.opacity(0.8))
                        .frame(width: 24, alignment: .center)
                    Text("High secure mode")
                        .font(.system(size: Self.expandedFontSz, weight: .medium))
                        .foregroundColor(.black)
                    Spacer(minLength: 8)
                    Toggle("", isOn: $highSecureMode)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(.vertical, 4)

                Button {
                    // Buduće: otvori popis accounta
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2")
                            .font(.system(size: Self.expandedIconSz))
                            .foregroundColor(.black.opacity(0.8))
                            .frame(width: 24, alignment: .center)
                        Text("Računi")
                            .font(.system(size: Self.expandedFontSz, weight: .medium))
                            .foregroundColor(.black)
                        Spacer(minLength: 8)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Self.expandedPadding)
            .padding(.bottom, Self.expandedPadding)
        }
        .frame(width: Self.expandedWidth, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Self.expandedCornerRadius).fill(Color.white))
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Self.expandedCornerRadius)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        }
    }
}

// MARK: - TabBarView (parent: ContentView) — crna traka + tabovi (Island je iznad kao zaseban sloj)
private struct TabBarView: View {
    @Binding var tabs: [BrowserTabItem]
    @Binding var selectedTabId: UUID?
    @Binding var expandedTabId: UUID?
    @Binding var signInPanelExpanded: Bool
    var onCloseSignInPanel: () -> Void
    var overlayStateForTab: (UUID) -> TabOverlayState
    var onSelectedTabClickedAgain: () -> Void
    var onRemoveTab: (BrowserTabItem) -> Void
    var onAddTab: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .center) {
                Color.black
                    .frame(maxWidth: .infinity)
                    .frame(height: TabBarConstants.barHeight)
                tabRow
            }
            .frame(height: TabBarConstants.barHeight)
            .frame(maxWidth: .infinity)
            .clipped()

            if let expandedId = expandedTabId,
               let tab = tabs.first(where: { $0.id == expandedId }) {
                TabExpandedBody(tabTitle: tab.title)
                    .padding(.top, 4)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(TabBarConstants.expandAnimation, value: expandedTabId)
    }

    private var tabRow: some View {
        HStack(alignment: .center, spacing: TabBarConstants.tabSpacing) {
            ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                tabItem(index: index, tab: tab)
            }
            TabBarAddButton(action: onAddTab)
            Spacer(minLength: 0)
            TabBarCornerSignIn(isExpanded: $signInPanelExpanded)
        }
        .padding(.leading, TabBarConstants.barLeadingPad)
        .padding(.trailing, TabBarConstants.barLeadingPad)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func tabItem(index: Int, tab: BrowserTabItem) -> some View {
        TabViewOneElement(
            tab: tab,
            isSelected: tab.id == selectedTabId,
            isExpanded: expandedTabId == tab.id,
            overlayState: overlayStateForTab(tab.id),
            onSelect: { selectedTabId = tab.id; onCloseSignInPanel() },
            onExpand: {
                withAnimation(TabBarConstants.expandAnimation) {
                    expandedTabId = expandedTabId == tab.id ? nil : tab.id
                }
            },
            onSelectedAgain: onSelectedTabClickedAgain,
            onClose: { onRemoveTab(tab) }
        )
        .onDrag {
            NSItemProvider(item: "\(kAlexandriaTabDragPrefix)\(tab.id.uuidString)" as NSString, typeIdentifier: UTType.plainText.identifier)
        }
        .onDrop(of: [.plainText], isTargeted: .constant(false)) { providers in
            guard let provider = providers.first else { return false }
            let dropIndex = index
            provider.loadObject(ofClass: NSString.self) { obj, _ in
                guard let str = obj as? String,
                      str.hasPrefix(kAlexandriaTabDragPrefix),
                      let draggedId = UUID(uuidString: String(str.dropFirst(kAlexandriaTabDragPrefix.count))) else { return }
                DispatchQueue.main.async {
                    guard let fromIdx = tabs.firstIndex(where: { $0.id == draggedId }),
                          fromIdx != dropIndex else { return }
                    withAnimation(TabBarConstants.expandAnimation) {
                        var newTabs = tabs
                        newTabs.move(fromOffsets: IndexSet([fromIdx]), toOffset: dropIndex)
                        tabs = newTabs
                    }
                }
            }
            return true
        }
    }
}

// MARK: - TabExpandedBody (child of TabViewOneElement) — sekcije, toggles, gumbi
private struct TabExpandedBody: View {
    let tabTitle: String
    @AppStorage("tabSettingSound") private var soundEnabled = true
    @AppStorage("tabSettingRAM") private var ramEnabled = true
    @AppStorage("tabSettingMic") private var micEnabled = false
    @AppStorage("tabSettingCamera") private var cameraEnabled = false
    private static let w: CGFloat = TabBarConstants.tabWidth
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
    var signInPanelExpanded: Bool = false
    var onCloseSignInPanel: (() -> Void)?
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
            if tabPanelExpanded || signInPanelExpanded {
                Color.clear
                    .contentShape(Rectangle())
                    .onHover { _ in
                        onCloseTabPanel?()
                        onCloseSignInPanel?()
                    }
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

/// Kontekst za novu instancu: ContentView u novom prozoru u onAppear uzima ove tabove.
private enum AlexandriaLaunchContext {
    static var tabsToLaunch: [BrowserTabItem]?
}

/// Otvara novu instancu Alexandria (novi prozor) s danim tabovima (npr. jedan tab izvučen iz trake).
private func openNewAlexandriaWindow(withTabs tabsToShow: [BrowserTabItem]) {
    guard !tabsToShow.isEmpty else { return }
    AlexandriaLaunchContext.tabsToLaunch = tabsToShow
    let content = ContentView()
    let hosting = NSHostingView(rootView: content)
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )
    window.contentView = hosting
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.isOpaque = false
    window.backgroundColor = .clear
    window.center()
    window.makeKeyAndOrderFront(nil)
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
    @State private var islandPhase2CloseRequested = false
    @State private var islandSearchQuery: String?
    @State private var currentAddress = ""
    /// Akcija za Island „Nazad” kad je u Eluminatiumu otvoren app u kartici (postavlja Eluminatium).
    @State private var islandBackAction: (() -> Void)? = nil
    /// Tab čiji se postavke prikazuju ispod trake (klik na tab → proširi prema dolje).
    @State private var expandedTabId: UUID? = nil
    /// Overlay po tabu kad tab NIJE prikazan: .incomingCall / .playingMusic. Postavi iz servisa poziva ili glazbe.
    @State private var tabOverlayStates: [UUID: TabOverlayState] = [:]
    /// Sig/in panel proširen; zatvori kad izgubi fokus (hover/tap izvan).
    @State private var signInPanelExpanded = false
    /// Pri pokretanju prikaži odabir moda ako je uključeno u postavkama.
    @State private var showModePickerAtLaunch = false

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
        .sheet(isPresented: $showModePickerAtLaunch) {
            ModePickerAtLaunchView(onSelect: { showModePickerAtLaunch = false })
        }
        .onAppear {
            if WorkModeStorage.showPickerOnLaunch {
                showModePickerAtLaunch = true
            }
            if let t = AlexandriaLaunchContext.tabsToLaunch, !t.isEmpty {
                tabs = t
                selectedTabId = t.first?.id
                AlexandriaLaunchContext.tabsToLaunch = nil
            }
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
            // Sloj 0 (najmanji): centralni sadržaj; drop taba ovdje → nova instanca Alexandria
            VStack(spacing: 0) {
                Color.clear.frame(height: 48)
                ScreenElement(
                    selectedTab: selectedTab,
                    initialSearchQuery: $islandSearchQuery,
                    currentAddress: $currentAddress,
                    setBackAction: { islandBackAction = $0 },
                    tabPanelExpanded: expandedTabId != nil,
                    onCloseTabPanel: { expandedTabId = nil },
                    signInPanelExpanded: signInPanelExpanded,
                    onCloseSignInPanel: { withAnimation(TabBarConstants.expandAnimation) { signInPanelExpanded = false } },
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
                            .onTapGesture { islandPhase2CloseRequested = true }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [.plainText], isTargeted: .constant(false)) { providers in
                guard let provider = providers.first else { return false }
                provider.loadObject(ofClass: NSString.self) { obj, _ in
                    guard let str = obj as? String, str.hasPrefix(kAlexandriaTabDragPrefix),
                          let uuid = UUID(uuidString: String(str.dropFirst(kAlexandriaTabDragPrefix.count))) else { return }
                    DispatchQueue.main.async {
                        guard let tab = tabs.first(where: { $0.id == uuid }) else { return }
                        openNewAlexandriaWindow(withTabs: [tab])
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.92)) {
                            tabs.removeAll { $0.id == tab.id }
                            if expandedTabId == tab.id { expandedTabId = nil }
                            if selectedTabId == tab.id { selectedTabId = tabs.first?.id }
                            if tabs.isEmpty { NSApplication.shared.terminate(nil) }
                        }
                    }
                }
                return true
            }
            .zIndex(0)

            // Sloj 1: crna traka + tabovi (ispod Islanda)
            TabBarView(
                tabs: $tabs,
                selectedTabId: $selectedTabId,
                expandedTabId: $expandedTabId,
                signInPanelExpanded: $signInPanelExpanded,
                onCloseSignInPanel: { withAnimation(TabBarConstants.expandAnimation) { signInPanelExpanded = false } },
                overlayStateForTab: { tabOverlayStates[$0] ?? .none },
                onSelectedTabClickedAgain: { islandPhase2Expanded = true },
                onRemoveTab: { tab in
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.92)) {
                        tabs.removeAll { $0.id == tab.id }
                        if expandedTabId == tab.id { expandedTabId = nil }
                        if tabs.isEmpty {
                            NSApplication.shared.terminate(nil)
                        } else if selectedTabId == tab.id {
                            selectedTabId = tabs.first?.id
                        }
                        signInPanelExpanded = false
                    }
                },
                onAddTab: {
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
                    signInPanelExpanded = false
                }
            )
            .frame(maxWidth: .infinity, alignment: .top)
            .zIndex(1)

            // Sloj 2: Island na vrhu svega (najveća hijerarhija)
            AlexandriaIsland(
                        isExpandedPhase2: $islandPhase2Expanded,
                        currentAddress: $currentAddress,
                        requestClosePhase2: $islandPhase2CloseRequested,
                        onBack: {
                            if case .app = selectedTab?.type {
                                tabs.removeAll { $0.id == selectedTab?.id }
                                selectedTabId = tabs.first?.id
                            } else {
                                islandBackAction?()
                            }
                        },
                        onForward: nil,
                        onReload: nil,
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
            .zIndex(100)
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
                WindowLayoutObserver.shared.updateFromWindow(window)
            }
            .frame(width: 0, height: 0)
        )
    }
}

// MARK: - Minijatura prozora za postavke teme (doslovno isti UX kao mainContent, samo skalirano)
struct MainWindowPreviewView: View {
    let theme: Theme
    private static let previewScale: CGFloat = 0.4
    private static let logicalWidth: CGFloat = 800
    private static let logicalHeight: CGFloat = 300

    @State private var previewTabId = UUID()
    @State private var tabs: [BrowserTabItem] = []
    @State private var selectedTabId: UUID?
    @State private var expandedTabId: UUID?
    @State private var signInPanelExpanded = false
    @State private var islandPhase2Expanded = false
    @State private var islandPhase2CloseRequested = false
    @State private var currentAddress = ""

    private var bindingTabs: Binding<[BrowserTabItem]> {
        Binding(
            get: {
                if tabs.isEmpty {
                    return [BrowserTabItem(id: previewTabId, type: .search)]
                }
                return tabs
            },
            set: { tabs = $0 }
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Sloj 0: isti kao mainContent – 48pt spacer pa sadržaj (ovdje samo boja teme).
            VStack(spacing: 0) {
                Color.clear.frame(height: TabBarConstants.barHeight)
                Rectangle()
                    .fill(theme.previewBackgroundColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(0)

            // Sloj 1: TabBarView (crna traka + tabovi).
            TabBarView(
                tabs: bindingTabs,
                selectedTabId: Binding(get: { selectedTabId ?? previewTabId }, set: { selectedTabId = $0 }),
                expandedTabId: Binding(get: { expandedTabId ?? previewTabId }, set: { expandedTabId = $0 }),
                signInPanelExpanded: $signInPanelExpanded,
                onCloseSignInPanel: { },
                overlayStateForTab: { _ in .none },
                onSelectedTabClickedAgain: { },
                onRemoveTab: { _ in },
                onAddTab: { }
            )
            .frame(maxWidth: .infinity, alignment: .top)
            .zIndex(1)

            // Sloj 2: Island na vrhu.
            AlexandriaIsland(
                isExpandedPhase2: $islandPhase2Expanded,
                currentAddress: $currentAddress,
                previewAccentColor: theme.previewAccentColor,
                onBack: { },
                onForward: nil,
                onReload: nil,
                onOpenSettings: { },
                onOpenSearch: { },
                onSubmitFromInsertBar: { _ in },
                onOpenDevMode: { },
                onOpenNewTab: { },
                onOpenAppFromLibrary: nil
            )
            .frame(maxWidth: .infinity, alignment: .top)
            .zIndex(100)
        }
        .frame(width: Self.logicalWidth, height: Self.logicalHeight)
        .scaleEffect(Self.previewScale)
        .frame(width: Self.logicalWidth * Self.previewScale, height: Self.logicalHeight * Self.previewScale)
    }
}

// MARK: - Odabir moda pri pokretanju (kad je uključeno „Uvijek pitaj koji mod”)
private struct ModePickerAtLaunchView: View {
    @ObservedObject private var workModeStorage = WorkModeStorage.shared
    var onSelect: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Odaberi mod rada")
                .font(.title2.bold())
            Text("Postavke (tema, Island, dopuštenja…) ovise o modu.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            List(workModeStorage.workModes) { mode in
                Button {
                    workModeStorage.setCurrentMode(id: mode.id)
                    onSelect()
                } label: {
                    HStack {
                        Image(systemName: mode.iconSymbolName)
                            .font(.system(size: 18))
                            .foregroundColor(.accentColor)
                            .frame(width: 28, alignment: .center)
                        Text(mode.displayName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
            .frame(minWidth: 280, minHeight: 200)
        }
        .padding(24)
        .frame(width: 320, height: 360)
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 600)
}
