//
//  DevToolsPanel.swift
//  Alexandria
//
//  Dev Tools panel: General → Console → Network → Programming → Designer → Architecture.
//  Navigacija strelicama, Reload; u postavkama možeš mijenjati redoslijed i onemogućiti sekcije (General uvijek prvi i neuklonjiv).
//

import SwiftUI

// MARK: - Sekcije Dev Toolsa (General uvijek prva i neuklonjiva)
enum DevToolsSectionId: String, CaseIterable, Identifiable {
    case general = "general"
    case console = "console"
    case network = "network"
    case programming = "programming"
    case designer = "designer"
    case viewTypes = "viewTypes"
    case architecture = "architecture"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .general: return "General"
        case .console: return "Console"
        case .network: return "Network"
        case .programming: return "Programming"
        case .designer: return "Designer"
        case .viewTypes: return "View Types"
        case .architecture: return "Architecture"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .console: return "terminal"
        case .network: return "network"
        case .programming: return "chevron.left.forwardslash.chevron.right"
        case .designer: return "paintbrush"
        case .viewTypes: return "rectangle.on.rectangle.angled"
        case .architecture: return "square.stack.3d.up"
        }
    }
}

// MARK: - Redoslijed i uključivanje sekcija (persisted)
final class DevToolsSectionOrder: ObservableObject {
    static let shared = DevToolsSectionOrder()
    
    private let key = "devToolsSectionOrder"
    private let defaultOrder: [DevToolsSectionId] = [.general, .console, .network, .programming, .designer, .viewTypes, .architecture]
    
    @Published private(set) var orderedSections: [DevToolsSectionId] = []
    
    private init() {
        load()
    }
    
    func load() {
        guard let raw = UserDefaults.standard.string(forKey: key),
              !raw.isEmpty else {
            orderedSections = defaultOrder
            return
        }
        let ids = raw.split(separator: ",").map(String.init)
        var result: [DevToolsSectionId] = []
        result.append(.general)
        for id in ids where id != DevToolsSectionId.general.rawValue {
            if let section = DevToolsSectionId(rawValue: id) {
                result.append(section)
            }
        }
        for section in DevToolsSectionId.allCases where section != .general && !result.contains(section) {
            result.append(section)
        }
        orderedSections = result
    }
    
    func save() {
        let raw = orderedSections.map(\.rawValue).joined(separator: ",")
        UserDefaults.standard.set(raw, forKey: key)
    }
    
    /// General je uvijek prvi i ne može se maknuti
    func setOrder(_ sections: [DevToolsSectionId]) {
        var list = sections
        if list.first != .general {
            list.removeAll { $0 == .general }
            list.insert(.general, at: 0)
        }
        orderedSections = list
        save()
    }
    
    func move(from: IndexSet, to: Int) {
        var list = orderedSections
        list.move(fromOffsets: from, toOffset: to)
        if list.first != .general {
            list.removeAll { $0 == .general }
            list.insert(.general, at: 0)
        }
        orderedSections = list
        save()
    }
    
    func toggleEnabled(_ section: DevToolsSectionId) {
        guard section != .general else { return }
        if orderedSections.contains(section) {
            orderedSections.removeAll { $0 == section }
        } else {
            orderedSections.append(section)
        }
        save()
    }
    
    func isEnabled(_ section: DevToolsSectionId) -> Bool {
        orderedSections.contains(section)
    }
}

// MARK: - Panel s navigacijom (← → Reload) i sadržajem sekcije
struct DevToolsPanelView: View {
    let accentColor: Color
    let eluminatiumURL: String
    let localIP: String
    let downloadRecords: [DownloadRecord]
    let formatDate: (Date) -> String
    let onRecordSelect: (DownloadRecord?) -> Void
    let onClearDownloads: () -> Void
    
    @StateObject private var sectionOrder = DevToolsSectionOrder.shared
    @State private var currentIndex: Int = 0
    @State private var reloadId = UUID()
    @AppStorage("devToolsSelectedSectionId") private var selectedSectionId: String = "general"
    
    private var orderedSections: [DevToolsSectionId] { sectionOrder.orderedSections }
    private var currentSection: DevToolsSectionId? {
        guard currentIndex >= 0, currentIndex < orderedSections.count else { return orderedSections.first }
        return orderedSections[currentIndex]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: currentIndex) { _, new in
            if new >= 0, new < orderedSections.count {
                selectedSectionId = orderedSections[new].rawValue
            }
        }
        .onAppear {
            if let idx = orderedSections.firstIndex(where: { $0.rawValue == selectedSectionId }) {
                currentIndex = idx
            }
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 8) {
            Button {
                if currentIndex > 0 { currentIndex -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(currentIndex > 0 ? accentColor : accentColor.opacity(0.4))
            .buttonStyle(.plain)
            .disabled(currentIndex <= 0)
            
            Button {
                if currentIndex < orderedSections.count - 1 { currentIndex += 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(currentIndex < orderedSections.count - 1 ? accentColor : accentColor.opacity(0.4))
            .buttonStyle(.plain)
            .disabled(currentIndex >= orderedSections.count - 1)
            
            Button {
                reloadId = UUID()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(accentColor)
            .buttonStyle(.plain)
            
            Text(currentSection?.title ?? "General")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.5))
    }
    
    @ViewBuilder
    private var content: some View {
        if let section = currentSection {
            sectionContent(section)
                .id("\(section.rawValue)-\(reloadId)")
        }
    }
    
    @ViewBuilder
    private func sectionContent(_ section: DevToolsSectionId) -> some View {
        switch section {
        case .general:
            DevToolsGeneralView(
                accentColor: accentColor,
                localIP: localIP,
                eluminatiumURL: eluminatiumURL,
                downloadRecords: downloadRecords,
                formatDate: formatDate,
                onRecordSelect: onRecordSelect,
                onClearDownloads: onClearDownloads
            )
        case .console:
            DevToolsConsoleView(accentColor: accentColor)
        case .network:
            DevToolsNetworkView(accentColor: accentColor)
        case .programming:
            DevToolsProgrammingView(accentColor: accentColor)
        case .designer:
            DevToolsDesignerView(accentColor: accentColor)
        case .viewTypes:
            DevToolsViewTypesView(accentColor: accentColor)
        case .architecture:
            DevToolsArchitectureView(accentColor: accentColor)
        }
    }
}

// MARK: - General – najosnovnije (Info + Preuzete datoteke)
private struct DevToolsGeneralView: View {
    let accentColor: Color
    let localIP: String
    let eluminatiumURL: String
    let downloadRecords: [DownloadRecord]
    let formatDate: (Date) -> String
    let onRecordSelect: (DownloadRecord?) -> Void
    let onClearDownloads: () -> Void
    
    var body: some View {
        VSplitView {
            VStack(alignment: .leading, spacing: 6) {
                Text("Dev Info")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accentColor)
                DevToolsInfoRow(label: "IP", value: localIP)
                DevToolsInfoRow(label: "Swift", value: "Alexandria")
                DevToolsInfoRow(label: "URL", value: eluminatiumURL.isEmpty ? "—" : eluminatiumURL)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.black.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(minHeight: 80)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Preuzete datoteke")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(accentColor)
                    Spacer()
                    Button("Očisti", action: onClearDownloads)
                        .font(.system(size: 10))
                        .foregroundColor(accentColor)
                }
                .padding(.horizontal, 4)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(downloadRecords) { r in
                            Button {
                                if r.filename.lowercased().hasSuffix(".zip") {
                                    onRecordSelect(r)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.filename)
                                        .font(.system(size: 10, design: .monospaced))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Text(formatDate(r.date))
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(r.filename.lowercased().hasSuffix(".zip") ? Color.white.opacity(0.1) : Color.white.opacity(0.06))
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                        if downloadRecords.isEmpty {
                            Text("Nema preuzetih datoteka")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(8)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(minHeight: 100)
        }
        .padding(8)
    }
}

private struct DevToolsInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

/// Način prikaza konzole: u panelu, iznad ekrana (overlay), ili split (gore ekran, dolje konzola)
enum DevToolsConsoleLayoutMode: String, CaseIterable {
    case panel = "panel"
    case overlay = "overlay"
    case split = "split"
    
    var label: String {
        switch self {
        case .panel: return "U panelu"
        case .overlay: return "Iznad ekrana"
        case .split: return "Split"
        }
    }
}

// MARK: - Console s +/− za prozirnost u 6 faza i odabir prikaza (panel / iznad ekrana / split)
private struct DevToolsConsoleView: View {
    @Environment(\.consoleStore) private var consoleStore
    @AppStorage("devToolsConsoleOpacityPhase") private var opacityPhase: Int = 5
    @AppStorage("devToolsConsoleLayoutMode") private var layoutModeRaw: String = DevToolsConsoleLayoutMode.panel.rawValue
    let accentColor: Color
    private let phaseCount = 6
    private var layoutMode: DevToolsConsoleLayoutMode {
        DevToolsConsoleLayoutMode(rawValue: layoutModeRaw) ?? .panel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("Prikaz")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                ForEach(DevToolsConsoleLayoutMode.allCases, id: \.rawValue) { mode in
                    Button {
                        layoutModeRaw = mode.rawValue
                    } label: {
                        Text(mode.label)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(layoutMode == mode ? accentColor : .white.opacity(0.6))
                    .buttonStyle(.plain)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(layoutMode == mode ? accentColor.opacity(0.2) : Color.clear))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.3))
            
            ConsoleView(
                store: consoleStore,
                onCollapse: nil,
                opacityPhase: Binding(
                    get: { min(max(opacityPhase, 0), phaseCount - 1) },
                    set: { opacityPhase = $0 }
                )
            )
            .frame(minHeight: 120)
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Network – tko je i kada došao
private struct DevToolsNetworkView: View {
    let accentColor: Color
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Network")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentColor)
                Text("Pregled spajanja – tko je i kada došao. (U izradi: integracija s mrežnim događajima.)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }
}

// MARK: - Programming – linija po liniju izvršavanje
private struct DevToolsProgrammingView: View {
    let accentColor: Color
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Programming")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentColor)
                Text("Pregled izvršavanja linija po liniju – kao u debuggeru. (U izradi.)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }
}

// MARK: - Designer – palit/gasit grupe (botuni, tabovi, vizualizacija)
private struct DevToolsDesignerView: View {
    let accentColor: Color
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Designer")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentColor)
                Text("Uključi/isključi grupe elemenata (botuni, tabovi, itd.) za vizualizaciju. (U izradi.)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }
}

// MARK: - View Types – simulacija uređaja i dimenzija ekrana (Apple uređaji, ikone)
private struct DevToolsViewTypesView: View {
    @AppStorage("devToolsViewTypesSelectedDevice") private var selectedDeviceId: String = ""
    let accentColor: Color
    
    private static let devices: [(id: String, name: String, width: CGFloat, height: CGFloat, icon: String)] = [
        ("iphone15", "iPhone 15", 393, 852, "iphone"),
        ("iphone15pro", "iPhone 15 Pro Max", 430, 932, "iphone"),
        ("iphone14", "iPhone 14", 390, 844, "iphone"),
        ("ipad11", "iPad Pro 11\"", 834, 1194, "ipad"),
        ("ipad13", "iPad Pro 12.9\"", 1024, 1366, "ipad"),
        ("ipadair", "iPad Air", 820, 1180, "ipad"),
        ("macbook13", "MacBook 13\"", 1280, 800, "laptopcomputer"),
        ("macbook14", "MacBook 14\"", 1512, 982, "laptopcomputer"),
        ("macbook16", "MacBook 16\"", 1728, 1117, "laptopcomputer"),
        ("imac24", "iMac 24\"", 1920, 1080, "desktopcomputer"),
        ("macstudio", "Mac Studio Display", 2560, 1440, "display"),
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("View Types")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentColor)
                Text("Simulacija Apple uređaja i dimenzija ekrana. Odaberi uređaj za pregled.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                ForEach(Self.devices, id: \.id) { device in
                    Button {
                        selectedDeviceId = selectedDeviceId == device.id ? "" : device.id
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: device.icon)
                                .font(.system(size: 18))
                                .foregroundColor(accentColor)
                                .frame(width: 28, alignment: .center)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                Text("\(Int(device.width)) × \(Int(device.height)) pt")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            if selectedDeviceId == device.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(accentColor)
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(selectedDeviceId == device.id ? accentColor.opacity(0.15) : Color.white.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }
}

// MARK: - Architecture – samo datoteke i povezivanja (bez prikaza app stranice); koristi se i na cijelom lijevom ekranu kad je Architecture odabran
struct DevToolsArchitectureView: View {
    let accentColor: Color
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Architecture")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentColor)
                Text("Samo struktura: datoteke i povezivanja – gdje je main, kako su povezane. Ako je OOP, struktura klasa. Bez prikaza app stranice. (U izradi.)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }
}
