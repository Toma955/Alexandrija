//
//  DevModeView.swift
//  Alexandria
//
//  Dev Mode – konzola, info, preuzete datoteke.
//

import SwiftUI
import Darwin

struct DevModeView: View {
    @Binding var currentAddress: String
    @Environment(\.consoleStore) private var consoleStore
    @State private var localIP: String = "—"
    @State private var selectedDownloadRecord: DownloadRecord?
    @ObservedObject private var downloadTracker = DownloadTracker.shared
    @AppStorage("devToolsConsoleLayoutMode") private var consoleLayoutModeRaw: String = DevToolsConsoleLayoutMode.panel.rawValue
    @AppStorage("devToolsConsoleOpacityPhase") private var consoleOpacityPhase: Int = 5
    @AppStorage("devToolsSelectedSectionId") private var devToolsSelectedSectionId: String = "general"
    
    private let accentColor = Color.white
    private var consoleLayoutMode: DevToolsConsoleLayoutMode {
        DevToolsConsoleLayoutMode(rawValue: consoleLayoutModeRaw) ?? .panel
    }
    
    private var eluminatiumURL: String {
        let url = SearchEngineManager.shared.selectedEngineURL
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/$", with: "", options: .regularExpression)
        return url.isEmpty ? "" : url
    }
    
    private var workspaceContent: some View {
        Group {
            if let record = selectedDownloadRecord {
                DevModeAppPreviewView(
                    record: record,
                    accentColor: accentColor,
                    onClose: { selectedDownloadRecord = nil }
                )
            } else {
                EluminatiumView(
                    initialSearchQuery: .constant(nil),
                    currentAddress: $currentAddress,
                    onOpenAppFromSearch: nil,
                    onSwitchToDevMode: nil
                )
            }
        }
        .frame(minWidth: 400)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func embeddedConsoleView(expandVertically: Bool) -> some View {
        ConsoleView(
            store: consoleStore,
            onCollapse: nil,
            opacityPhase: Binding(
                get: { min(max(consoleOpacityPhase, 0), 5) },
                set: { consoleOpacityPhase = $0 }
            ),
            expandVertically: expandVertically
        )
        .frame(minHeight: 140)
        .frame(maxWidth: expandVertically ? .infinity : nil, maxHeight: expandVertically ? .infinity : nil)
    }
    
    @ViewBuilder
    private var leftSideContent: some View {
        if devToolsSelectedSectionId == DevToolsSectionId.architecture.rawValue {
            DevToolsArchitectureView(accentColor: accentColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            switch consoleLayoutMode {
            case .panel:
                workspaceContent
            case .overlay:
                ZStack {
                    workspaceContent
                    embeddedConsoleView(expandVertically: true)
                        .background(Color.black.opacity(0.92))
                }
            case .split:
                VSplitView {
                    workspaceContent
                    embeddedConsoleView(expandVertically: false)
                }
            }
        }
    }
    
    private var mainContent: some View {
        HSplitView {
            leftSideContent
                .frame(minWidth: 400)
            
            DevToolsPanelView(
                accentColor: accentColor,
                eluminatiumURL: eluminatiumURL,
                localIP: localIP,
                downloadRecords: downloadTracker.records,
                formatDate: formatDate,
                onRecordSelect: { selectedDownloadRecord = $0 },
                onClearDownloads: { downloadTracker.clear() }
            )
            .frame(width: 280)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
    }
    
    var body: some View {
        mainContent
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
        )
        .padding(16)
        .task {
            currentAddress = eluminatiumURL.isEmpty ? "Dev Mode" : eluminatiumURL
            fetchLocalIP()
        }
    }
    
    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM. HH:mm:ss"
        return f.string(from: d)
    }
    
    private func fetchLocalIP() {
        Task {
            if let ip = getLocalIP() {
                await MainActor.run { localIP = ip }
            }
        }
    }
    
    private func getLocalIP() -> String? {
        var addr: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return "127.0.0.1" }
        defer { freeifaddrs(ifaddr) }
        
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let p = ptr {
            let interface = p.pointee
            if let addrPtr = interface.ifa_addr, interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" || name.hasPrefix("en") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(addrPtr, socklen_t(addrPtr.pointee.sa_len),
                                  &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        let ip = String(cString: hostname)
                        if ip != "127.0.0.1" { addr = ip; break }
                    }
                }
            }
            ptr = interface.ifa_next
        }
        return addr ?? "127.0.0.1"
    }
}

private struct InfoRow: View {
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

// MARK: - Prikaz preuzete app u radnom prostoru (iznad konzole) – Kod (linija po liniju) ili Pregled (gotov proizvod)
private struct DevModeAppPreviewView: View {
    let record: DownloadRecord
    let accentColor: Color
    var onClose: () -> Void
    
    @Environment(\.consoleStore) private var consoleStore
    @State private var state: PreviewState = .loading
    @State private var loadedSource: String = ""
    @State private var showCodeView = false
    
    private enum PreviewState {
        case loading
        case app(AlexandriaViewNode)
        case error(String)
    }
    
    private var appId: String {
        (record.filename as NSString).deletingPathExtension
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    onClose()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Nazad")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)
                Text(record.filename)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                if !loadedSource.isEmpty {
                    HStack(spacing: 8) {
                        Button { showCodeView = false } label: {
                            Text("Pregled").font(.system(size: 11, weight: .medium))
                                .foregroundColor(showCodeView ? .white.opacity(0.6) : accentColor)
                        }
                        .buttonStyle(.plain)
                        Button { showCodeView = true } label: {
                            Text("Kod").font(.system(size: 11, weight: .medium))
                                .foregroundColor(showCodeView ? accentColor : .white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.5))
            
            Group {
                switch state {
                case .loading:
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(accentColor)
                        Text("Učitavam \(appId)...")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .app(let node):
                    if showCodeView {
                        CodeView(source: loadedSource)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        AlexandriaRenderer(node: node, console: consoleStore)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(16)
                    }
                case .error(let message):
                    if !loadedSource.isEmpty {
                        CodeView(source: loadedSource)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                            Text(message)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            Button("Nazad") { onClose() }
                                .foregroundColor(accentColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: record.id) {
            await loadAndShow()
        }
    }
    
    private func loadAndShow() async {
        state = .loading
        loadedSource = ""
        let store = consoleStore
        await MainActor.run {
            store.log("Dev Mode: učitavam Swift izvornik: \(appId) (iz Preuzete datoteke)", type: .info)
        }
        do {
            let source = try await EluminatiumService.shared.fetchSource(appId: appId)
            await MainActor.run { loadedSource = source }
            let sourceToParse = source
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let node = try AlexandriaParser(source: sourceToParse).parse()
                    DispatchQueue.main.async {
                        store.log("Dev Mode: \(appId) učitana ✓", type: .info)
                        state = .app(node)
                    }
                } catch {
                    DispatchQueue.main.async {
                        store.log("Dev Mode: \(appId) – greška: \(error.localizedDescription)", type: .error)
                        state = .error(error.localizedDescription)
                    }
                }
            }
        } catch {
            await MainActor.run {
                store.log("Dev Mode: \(appId) – greška: \(error.localizedDescription)", type: .error)
                state = .error(error.localizedDescription)
            }
        }
    }
}
