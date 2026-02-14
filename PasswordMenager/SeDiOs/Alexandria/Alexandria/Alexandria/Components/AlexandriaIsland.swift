//
//  AlexandriaIsland.swift
//  Alexandria
//
//  Crni obli kvadrat s narančastim obrubom – SVE unutra.
//  Hover → ikone, Klik → raširi s punim toolbarom (naprijed, nazad, insert bar, home, reload, mode, user, grupe, prit, zoom).
//

import SwiftUI

struct AlexandriaIsland: View {
    @AppStorage("islandTitle") private var islandTitle: String = "Alexandria"
    @AppStorage("isInternetEnabled") private var isInternetEnabled = true
    @AppStorage("themeRegistrySelectedThemeId") private var islandThemeId: String = "default"  // promjena teme → osvježi ikone
    @State private var isExpandedPhase1 = false  // hover – ikone
    @Binding var isExpandedPhase2: Bool          // klik – puni toolbar
    @Binding var currentAddress: String         // URL trenutnog taba – prikazuje se u input baru
    @State private var showAppLibrary = false
    @ObservedObject private var networkMonitor = NetworkMonitorService.shared

    private var accentColor: Color { AlexandriaTheme.accentColor }
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenSearch: (() -> Void)?
    var onSubmitFromInsertBar: ((String) -> Void)?
    var onOpenDevMode: (() -> Void)?
    var onOpenNewTab: (() -> Void)?
    var onOpenAppFromLibrary: ((InstalledApp) -> Void)?

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .overlay(alignment: .top) {
                AlexandriaIslandContent(
                    islandTitle: islandTitle,
                    isExpandedPhase1: $isExpandedPhase1,
                    isExpandedPhase2: $isExpandedPhase2,
                    currentAddress: $currentAddress,
                    networkStatus: networkMonitor.status,
                    isInternetEnabled: isInternetEnabled,
                    accentColor: accentColor,
                    onBack: onBack,
                    onForward: onForward,
                    onOpenSettings: onOpenSettings,
                    onOpenAppLibrary: { showAppLibrary = true },
                    onOpenSearch: onOpenSearch,
                    onSubmitFromInsertBar: onSubmitFromInsertBar,
                    onOpenDevMode: onOpenDevMode,
                    onOpenNewTab: onOpenNewTab
                )
            }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showAppLibrary) {
            AppLibraryView(
                onOpenApp: { app in
                    showAppLibrary = false
                    onOpenAppFromLibrary?(app)
                }
            )
        }
    }
}

// MARK: - Okrugli gumb za Island
private struct IslandRoundButton: View {
    let icon: String
    let accentColor: Color
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(accentColor)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Nazad / Naprijed gumb (strelica + natpis) gore u toolbaru
private struct IslandBackForwardButton: View {
    let icon: String
    let label: String
    let accentColor: Color
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(accentColor)
                Text(label)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(accentColor.opacity(0.9))
            }
            .frame(width: 32, height: 34)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ikona bez kruga (za mikrofon)
private struct IslandPlainIcon: View {
    let icon: String
    let accentColor: Color

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 12))
            .foregroundColor(accentColor)
    }
}

// MARK: - Insert bar unutar Islanda – mic + input + Go
private struct IslandInsertBar: View {
    @Binding var text: String
    let accentColor: Color
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            IslandPlainIcon(icon: IslandIcon.symbol(for: .mic), accentColor: accentColor)
            IslandInsertBarTextField(text: $text, onSubmit: onSubmit)
            Button {
                onSubmit?()
            } label: {
                Text("Go")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(accentColor))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 32)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - TextField s Enter za submit (macOS)
private struct IslandInsertBarTextField: NSViewRepresentable {
    @Binding var text: String
    var onSubmit: (() -> Void)?

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField(string: text)
        tf.placeholderString = "Pretraži ili unesi URL..."
        tf.isBordered = false
        tf.drawsBackground = false
        tf.isEditable = true
        tf.isSelectable = true
        tf.focusRingType = .none
        tf.font = .systemFont(ofSize: 12)
        tf.textColor = .white
        tf.cell?.truncatesLastVisibleLine = true
        if let cell = tf.cell as? NSTextFieldCell {
            cell.placeholderAttributedString = NSAttributedString(
                string: "Pretraži ili unesi URL...",
                attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.5)]
            )
        }
        tf.delegate = context.coordinator
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        context.coordinator.onSubmit = onSubmit
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        var onSubmit: (() -> Void)?

        init(text: Binding<String>, onSubmit: (() -> Void)?) {
            _text = text
            self.onSubmit = onSubmit
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                onSubmit?()
                return true
            }
            return false
        }
    }
}

// MARK: - Island Content (hover = ikone, klik = puni toolbar)
struct AlexandriaIslandContent: View {
    let islandTitle: String
    @Binding var isExpandedPhase1: Bool
    @Binding var isExpandedPhase2: Bool
    @Binding var currentAddress: String
    let networkStatus: NetworkStatus
    let isInternetEnabled: Bool
    let accentColor: Color
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenAppLibrary: (() -> Void)?
    var onOpenSearch: (() -> Void)?
    var onSubmitFromInsertBar: ((String) -> Void)?
    var onOpenDevMode: (() -> Void)?
    var onOpenNewTab: (() -> Void)?
    
    @State private var insertBarText = ""
    
    private var isExpanded: Bool { isExpandedPhase1 || isExpandedPhase2 }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(isExpanded ? 14 : 6)
        .frame(width: islandWidth, height: isExpanded ? nil : 26)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(accentColor, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .padding(.horizontal, 60)
        .padding(.vertical, 1)
        .onHover { hovering in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpandedPhase1 = hovering
            }
        }
    }
    
    private var islandWidth: CGFloat {
        if isExpandedPhase2 { return 520 }
        if isExpandedPhase1 { return 360 }
        return 140
    }
    
    /// Zeleni globus = spojeno, sivi = nije spojeno
    private var globeIndicatorColor: Color {
        guard isInternetEnabled else { return .gray }
        switch networkStatus {
        case .connected: return Color(hex: "22c55e")
        case .disconnected: return .gray
        case .unknown: return .orange
        }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(spacing: isExpanded ? 10 : 0) {
            // Natpis + klik – raširi na phase 2 (natpis se ne prikazuje u phase 2)
            if !isExpandedPhase2 {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpandedPhase2.toggle()
                        if isExpandedPhase2 {
                            insertBarText = currentAddress
                        } else {
                            insertBarText = ""
                        }
                    }
                } label: {
                    Text(islandTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accentColor)
                        .frame(height: 18)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            
            if isExpandedPhase1 && !isExpandedPhase2 {
                phase1Buttons
            }
            
            if isExpandedPhase2 {
                phase2FullToolbar
            }
        }
        .onChange(of: currentAddress) { oldAddr, newAddr in
            // Ažuriraj samo ako korisnik nije ručno upisao (tekst još odgovara starom URL-u)
            if isExpandedPhase2, insertBarText == oldAddr {
                insertBarText = newAddr
            }
        }
        .onChange(of: isExpandedPhase2) { _, expanded in
            if expanded {
                insertBarText = currentAddress
            } else {
                insertBarText = ""
            }
        }
    }
    
    private var phase1Buttons: some View {
        HStack(spacing: 6) {
            IslandPhase1Button(icon: IslandIcon.symbol(for: .settings), label: "Postavke", accentColor: accentColor, action: onOpenSettings)
            IslandPhase1Button(icon: IslandIcon.symbol(for: .appLibrary), label: "Aplikacije", accentColor: accentColor, action: onOpenAppLibrary)
            IslandPhase1Button(icon: IslandIcon.symbol(for: .newTab), label: "Novi tab", accentColor: accentColor, action: onOpenNewTab)
            IslandPhase1Button(icon: IslandIcon.symbol(for: .favorites), label: "Omiljeno", accentColor: accentColor)
            IslandPhase1Button(icon: IslandIcon.symbol(for: .search), label: "Pretraživanje", accentColor: accentColor, action: onOpenSearch)
        }
    }
    
    // Tablica 2 reda – gornji: spojene ćelije (Nazad|Naprijed|Input|Globe). Donji: svaka ćelija = jedna ikona.
    private var phase2FullToolbar: some View {
        let gap: CGFloat = 8
        let btnW: CGFloat = 26

        return Grid(alignment: .center, horizontalSpacing: gap, verticalSpacing: gap) {
            GridRow {
                IslandBackForwardButton(icon: IslandIcon.symbol(for: .back), label: "Nazad", accentColor: accentColor, action: { onBack?() })
                IslandBackForwardButton(icon: IslandIcon.symbol(for: .forward), label: "Naprijed", accentColor: accentColor, action: { onForward?() })
                IslandInsertBar(text: $insertBarText, accentColor: accentColor) {
                    let q = insertBarText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !q.isEmpty else { return }
                    onSubmitFromInsertBar?(q)
                    onOpenSearch?()
                }
                .frame(maxWidth: .infinity)
                .gridCellColumns(9)
                Image(systemName: IslandIcon.symbol(for: .globe))
                    .font(.system(size: 11))
                    .foregroundColor(globeIndicatorColor)
                    .frame(width: btnW, height: btnW)
            }
            GridRow {
                IslandRoundButton(icon: IslandIcon.symbol(for: .magnifyingGlassMinus), accentColor: accentColor)
                IslandRoundButton(icon: IslandIcon.symbol(for: .grid), accentColor: accentColor, action: { onOpenAppLibrary?() })
                IslandRoundButton(icon: IslandIcon.symbol(for: .magnifyingGlassPlus), accentColor: accentColor)
                IslandRoundButton(icon: IslandIcon.symbol(for: .home), accentColor: accentColor)
                IslandRoundButton(icon: IslandIcon.symbol(for: .reload), accentColor: accentColor)
                IslandRoundButton(icon: IslandIcon.symbol(for: .devMode), accentColor: accentColor, action: { onOpenDevMode?() })
                IslandRoundButton(icon: IslandIcon.symbol(for: .person), accentColor: accentColor)
                IslandRoundButton(icon: IslandIcon.symbol(for: .printer), accentColor: accentColor)
                IslandRoundButton(icon: IslandIcon.symbol(for: .keyboard), accentColor: accentColor)
                IslandRoundButton(icon: IslandIcon.symbol(for: .bag), accentColor: accentColor)
                IslandRoundButton(icon: IslandIcon.symbol(for: .plus), accentColor: accentColor, action: { onOpenNewTab?() })
                IslandRoundButton(icon: IslandIcon.symbol(for: .settings), accentColor: accentColor, action: { onOpenSettings?() })
            }
        }
    }
}


// MARK: - Island Phase 1 Button (okrugli)
struct IslandPhase1Button: View {
    let icon: String
    let label: String
    let accentColor: Color
    var action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 1) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 8, weight: .medium))
            }
            .foregroundColor(accentColor)
            .frame(minWidth: 36)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Island Bottom Button
struct IslandBottomButton: View {
    let icon: String
    let label: String
    let accentColor: Color
    var action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}
