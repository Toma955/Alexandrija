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
    /// Kad parent postavi na true, island prvo sakrije ikone pa nakon 0.2s postavi isExpandedPhase2 = false.
    var requestClosePhase2: Binding<Bool> = .constant(false)
    @State private var showAppLibrary = false
    @ObservedObject private var networkMonitor = NetworkMonitorService.shared

    /// Kad je postavljen, koristi se umjesto AlexandriaTheme (za minijaturu u postavkama teme).
    var previewAccentColor: Color? = nil
    private var accentColor: Color { previewAccentColor ?? AlexandriaTheme.accentColor }
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?
    var onReload: (() -> Void)?
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
                    requestClosePhase2: requestClosePhase2,
                    currentAddress: $currentAddress,
                    networkStatus: networkMonitor.status,
                    isInternetEnabled: isInternetEnabled,
                    accentColor: accentColor,
                    onBack: onBack,
                    onForward: onForward,
                    onReload: onReload,
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
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(accentColor)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.white.opacity(isHovered ? 0.14 : 0.08)))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Tražilica "T" gumb (slovo T) – toolbar stil ili obli kvadrat s polukrugom (Capsule)
private struct IslandSearchTButton: View {
    let accentColor: Color
    var action: () -> Void = {}
    var capsuleStyle: Bool = false  // true = obli kvadrat s polukrugom (u padajućem izborniku)
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text("T")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor)
                .frame(width: capsuleStyle ? 36 : 32, height: 34)
                .padding(.horizontal, capsuleStyle ? 8 : 0)
                .background(
                    Group {
                        if capsuleStyle {
                            Capsule().fill(Color.white.opacity(isHovered ? 0.14 : 0.08))
                        } else {
                            RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(isHovered ? 0.14 : 0.08))
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Nazad / Naprijed gumb (samo ikona) gore u toolbaru
private struct IslandBackForwardButton: View {
    let icon: String
    let accentColor: Color
    var action: () -> Void = {}
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(accentColor)
                .frame(width: 32, height: 34)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(isHovered ? 0.14 : 0.08)))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
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

// MARK: - Insert bar unutar Islanda – mic + input (Enter za submit), fokus otvara padajući izbornik
private struct IslandInsertBar: View {
    @Binding var text: String
    let accentColor: Color
    var onSubmit: (() -> Void)?
    var onFocusChange: ((Bool) -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            IslandPlainIcon(icon: IslandIcon.symbol(for: .mic), accentColor: accentColor)
            IslandInsertBarTextField(text: $text, onSubmit: onSubmit, onFocusChange: onFocusChange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 34)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
    }
}

// NSTextField koji javlja kada postane / prestane biti first responder
private final class IslandFocusReportingTextField: NSTextField {
    var onFirstResponderChange: ((Bool) -> Void)?
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result { onFirstResponderChange?(true) }
        return result
    }
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result { onFirstResponderChange?(false) }
        return result
    }
}

// MARK: - TextField s Enter za submit i detekcija fokusa (macOS)
private struct IslandInsertBarTextField: NSViewRepresentable {
    @Binding var text: String
    var onSubmit: (() -> Void)?
    var onFocusChange: ((Bool) -> Void)?

    func makeNSView(context: Context) -> NSTextField {
        let tf = IslandFocusReportingTextField(string: text)
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
        let coord = context.coordinator
        (tf as? IslandFocusReportingTextField)?.onFirstResponderChange = { focused in
            DispatchQueue.main.async { coord.onFocusChange?(focused) }
        }
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onFocusChange = onFocusChange
        let coord = context.coordinator
        (nsView as? IslandFocusReportingTextField)?.onFirstResponderChange = { focused in
            DispatchQueue.main.async { coord.onFocusChange?(focused) }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit, onFocusChange: onFocusChange)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        var onSubmit: (() -> Void)?
        var onFocusChange: ((Bool) -> Void)?

        init(text: Binding<String>, onSubmit: (() -> Void)?, onFocusChange: ((Bool) -> Void)?) {
            _text = text
            self.onSubmit = onSubmit
            self.onFocusChange = onFocusChange
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            text = field.stringValue
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            onFocusChange?(false)
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
    var requestClosePhase2: Binding<Bool> = .constant(false)
    @Binding var currentAddress: String
    let networkStatus: NetworkStatus
    let isInternetEnabled: Bool
    let accentColor: Color
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?
    var onReload: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenAppLibrary: (() -> Void)?
    var onOpenSearch: (() -> Void)?
    var onSubmitFromInsertBar: ((String) -> Void)?
    var onOpenDevMode: (() -> Void)?
    var onOpenNewTab: (() -> Void)?
    
    @AppStorage("workMode.currentModeId") private var currentModeId: String = WorkMode.defaultId
    @State private var insertBarText = ""
    /// Ikone/toolbar se prikažu tek nakon animacije prostora. Phase 2 se ne sakuplja – ostaje raširen.
    @State private var showPhase1Content = false
    @State private var showPhase2Content = false
    /// Fokus na input polju → padajući izbornik (povijest + donji red s Go i ikonama)
    @State private var isInsertBarExpanded = false
    @State private var insertBarHistory: [String] = []
    private static let insertBarHistoryKey = "island.insertBar.history"
    private static let insertBarHistoryMax = 10
    
    private var isExpanded: Bool { isExpandedPhase1 || isExpandedPhase2 }
    /// Phase 1: kratka odgoda pa glatko "kao duhovi" pojavljivanje
    private let expandPhase1ContentDelay: Double = 0.12
    /// Phase 2: prikaz toolbara "u putu" – tijekom širenja donje granice
    private let expandPhase2ContentDelay: Double = 0.2
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(isExpanded ? 14 : 6)
        .frame(width: islandWidth, height: isExpanded ? nil : 26)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(accentColor.opacity(0.9), lineWidth: 1.2)
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 4)
        .contentShape(Rectangle())
        .padding(.horizontal, 60)
        .padding(.vertical, 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isExpanded)
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
    
    /// Visina područja ikona – kad je input fokusiran, gornji red je samo input, botuni idu dole u padajući; phase2 ikone nestanu.
    private var iconsAreaHeight: CGFloat {
        if isExpandedPhase2 {
            if isInsertBarExpanded {
                return 44 + 320  // jedan red (samo input) + padajući izbornik
            }
            return 82  // dva reda: botuni + phase2 ikone
        }
        if isExpandedPhase1 { return 40 }
        return 0
    }
    
    private func loadInsertBarHistory() {
        insertBarHistory = (UserDefaults.standard.array(forKey: Self.insertBarHistoryKey) as? [String]) ?? []
    }
    
    private func addToInsertBarHistory(_ s: String) {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        insertBarHistory.removeAll { $0 == trimmed }
        insertBarHistory.insert(trimmed, at: 0)
        insertBarHistory = Array(insertBarHistory.prefix(Self.insertBarHistoryMax))
        UserDefaults.standard.set(insertBarHistory, forKey: Self.insertBarHistoryKey)
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
            // Natpis + klik – raširi na phase 2; pri zatvaranju naziv se pojavljuje dok se granice skupljaju
            if !isExpandedPhase2 {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpandedPhase2 = true
                        insertBarText = currentAddress
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + expandPhase2ContentDelay) {
                        if isExpandedPhase2 { showPhase2Content = true }
                    }
                } label: {
                    Text(islandTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "e11d1d"), Color(hex: "ea580c"), Color(hex: "f97316")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 20)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
            
            // Područje s animiranom visinom: donja granica "putuje" dole, ikone su na dnu pa putuju s njom i u putu se transformiraju
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .bottom) {
                    if (isExpandedPhase1 && !isExpandedPhase2) || (isExpandedPhase2 && !showPhase2Content) {
                        phase1Buttons
                            .opacity((isExpandedPhase2 && !showPhase2Content) ? 1 : (showPhase1Content ? 1 : 0))
                            .transition(.opacity)
                    }
                    if isExpandedPhase2 && showPhase2Content {
                        phase2FullToolbar
                            .transition(.opacity)
                    }
                }
            }
            .frame(height: iconsAreaHeight)
            .clipped()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: iconsAreaHeight)
        .animation(.easeInOut(duration: 0.32), value: showPhase1Content)
        .animation(.easeInOut(duration: 0.22), value: showPhase2Content)
        .onChange(of: isExpandedPhase1) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + expandPhase1ContentDelay) {
                    if isExpandedPhase1 { showPhase1Content = true }
                }
            } else {
                showPhase1Content = false
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
                showPhase2Content = false
            }
        }
        .onChange(of: requestClosePhase2.wrappedValue) { _, requested in
            guard requested else { return }
            // Zadnja faza: ikone nestaju, granice se skupljaju i naziv se pojavljuje – sve u jednoj animaciji
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showPhase2Content = false
                isExpandedPhase2 = false
                insertBarText = ""
            }
            requestClosePhase2.wrappedValue = false
        }
    }
    
    private var phase1Order: [IslandIconKey] {
        IslandLayoutStorage.phase1Order(modeId: currentModeId)
    }

    private func phase1Action(for key: IslandIconKey) -> (() -> Void)? {
        switch key {
        case .settings: return onOpenSettings
        case .appLibrary: return onOpenAppLibrary
        case .newTab: return onOpenNewTab
        case .search: return onOpenSearch
        default: return nil
        }
    }

    private var phase1Buttons: some View {
        HStack(spacing: 6) {
            ForEach(phase1Order, id: \.rawValue) { key in
                IslandPhase1Button(
                    icon: IslandIcon.symbol(for: key),
                    label: key.displayLabel,
                    accentColor: accentColor,
                    action: phase1Action(for: key)
                )
            }
        }
    }

    private var phase2Order: [IslandIconKey] {
        IslandLayoutStorage.phase2Order(modeId: currentModeId)
    }

    private func phase2Action(for key: IslandIconKey) -> (() -> Void)? {
        switch key {
        case .grid: return onOpenAppLibrary
        case .devMode: return onOpenDevMode
        case .plus: return onOpenNewTab
        case .settings: return onOpenSettings
        default: return nil
        }
    }

    // Kad nema fokusa: gornji red Nazad|T|Input|Naprijed|Reload, donji phase2 ikone. Kad se počne unositi: gornji samo Input, botuni i sve ostalo idu dole u padajući.
    private var phase2FullToolbar: some View {
        let gap: CGFloat = 8
        return VStack(spacing: 0) {
            Grid(alignment: .center, horizontalSpacing: gap, verticalSpacing: gap) {
                GridRow {
                    if !isInsertBarExpanded {
                        IslandBackForwardButton(icon: IslandIcon.symbol(for: .back), accentColor: accentColor, action: { onBack?() })
                        IslandSearchTButton(accentColor: accentColor, action: { onOpenSearch?() })
                    }
                    IslandInsertBar(text: $insertBarText, accentColor: accentColor, onSubmit: { performInsertBarSubmit() }, onFocusChange: { focused in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            isInsertBarExpanded = focused
                        }
                    })
                    .frame(maxWidth: .infinity)
                    .gridCellColumns(isInsertBarExpanded ? 12 : 8)
                    if !isInsertBarExpanded {
                        IslandBackForwardButton(icon: IslandIcon.symbol(for: .forward), accentColor: accentColor, action: { onForward?() })
                        IslandBackForwardButton(icon: "arrow.clockwise", accentColor: accentColor, action: { onReload?() })
                    }
                }
                if !isInsertBarExpanded {
                    GridRow {
                        ForEach(phase2Order, id: \.rawValue) { key in
                            IslandRoundButton(
                                icon: IslandIcon.symbol(for: key),
                                accentColor: accentColor,
                                action: phase2Action(for: key) ?? {}
                            )
                        }
                    }
                }
            }
            if isInsertBarExpanded {
                insertBarDropdown
            }
        }
        .onAppear { loadInsertBarHistory() }
    }
    
    private func performInsertBarSubmit() {
        let q = insertBarText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        addToInsertBarHistory(q)
        onSubmitFromInsertBar?(q)
        onOpenSearch?()
    }
    
    /// Padajući izbornik: povijest (do 10) + donji red: Nazad | Naprijed | Reload | Povijest | Go (usredini) | Mikrofon | Tipkovnica | Plus
    @ViewBuilder
    private var insertBarDropdown: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(insertBarHistory.prefix(Self.insertBarHistoryMax), id: \.self) { item in
                        Button {
                            insertBarText = item
                            performInsertBarSubmit()
                        } label: {
                            Text(item)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 280)
            HStack(spacing: 10) {
                IslandInsertBarIconButton(icon: IslandIcon.symbol(for: .back), accentColor: accentColor, action: { onBack?() })
                IslandInsertBarIconButton(icon: IslandIcon.symbol(for: .forward), accentColor: accentColor, action: { onForward?() })
                IslandInsertBarIconButton(icon: "arrow.clockwise", accentColor: accentColor, action: { onReload?() })
                IslandInsertBarIconButton(icon: "clock.arrow.circlepath", accentColor: accentColor, action: {})
                Spacer(minLength: 8)
                Button {
                    performInsertBarSubmit()
                } label: {
                    Text("Go")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(hex: "22c55e")))
                }
                .buttonStyle(.plain)
                IslandSearchTButton(accentColor: accentColor, action: { onOpenSearch?() }, capsuleStyle: true)
                Spacer(minLength: 8)
                IslandInsertBarIconButton(icon: IslandIcon.symbol(for: .mic), accentColor: accentColor, action: {})
                IslandInsertBarIconButton(icon: "keyboard", accentColor: accentColor, action: {})
                IslandInsertBarIconButton(icon: "plus", accentColor: accentColor, action: { onOpenNewTab?() })
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Ikona u donjem redu padajućeg izbornika (miš, mik, tipkovnica, plus)
private struct IslandInsertBarIconButton: View {
    let icon: String
    let accentColor: Color
    var action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(accentColor)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.white.opacity(isHovered ? 0.14 : 0.08)))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}


// MARK: - Island Phase 1 Button (okrugli)
struct IslandPhase1Button: View {
    let icon: String
    let label: String
    let accentColor: Color
    var action: (() -> Void)?
    @State private var isHovered = false

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
                    .fill(Color.white.opacity(isHovered ? 0.14 : 0.08))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
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
