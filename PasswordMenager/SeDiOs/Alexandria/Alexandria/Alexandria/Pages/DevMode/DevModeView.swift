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
    @State private var localIP: String = "—"
    @State private var showConsole = false
    @State private var selectedDownloadRecord: DownloadRecord?
    @ObservedObject private var downloadTracker = DownloadTracker.shared
    
    private let accentColor = Color.white
    
    private var eluminatiumURL: String {
        let url = SearchEngineManager.shared.selectedEngineURL
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/$", with: "", options: .regularExpression)
        return url.isEmpty ? "" : url
    }
    
    private var mainContent: some View {
        HSplitView {
            // Lijevo: radni prostor – search ili prikaz odabrane preuzete app (iznad konzole)
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
            
            // Desno: Info + Preuzete datoteke (VSplitView – pomicljivo gore-dolje)
            VSplitView {
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text("Dev Info")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(accentColor)
                    InfoRow(label: "IP", value: localIP)
                    InfoRow(label: "Swift", value: "Alexandria")
                    InfoRow(label: "URL", value: eluminatiumURL.isEmpty ? "—" : eluminatiumURL)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(minHeight: 80)
                
                // Preuzete datoteke – resizable
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Preuzete datoteke")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(accentColor)
                        Spacer()
                        Button("Očisti") {
                            downloadTracker.clear()
                        }
                        .font(.system(size: 10))
                        .foregroundColor(accentColor)
                    }
                    .padding(.horizontal, 4)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(downloadTracker.records) { r in
                                Button {
                                    if r.filename.lowercased().hasSuffix(".zip") {
                                        selectedDownloadRecord = r
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
                            if downloadTracker.records.isEmpty {
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(minHeight: 100)
            }
            .frame(width: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
    }
    
    var body: some View {
        Group {
            if showConsole {
                VSplitView {
                    mainContent
                    ConsoleView(store: ConsoleStore.shared, onCollapse: { showConsole = false })
                        .frame(minHeight: 80)
                }
            } else {
                VStack(spacing: 0) {
                    mainContent
                    Button {
                        showConsole = true
                    } label: {
                        HStack {
                            Image(systemName: "terminal")
                                .font(.system(size: 12))
                            Text("Console")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(accentColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
                        AlexandriaRenderer(node: node)
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
        await MainActor.run {
            ConsoleStore.shared.log("Dev Mode: učitavam Swift izvornik: \(appId) (iz Preuzete datoteke)", type: .info)
        }
        do {
            let source = try await EluminatiumService.shared.fetchSource(appId: appId)
            await MainActor.run { loadedSource = source }
            let node = try AlexandriaParser(source: source).parse()
            await MainActor.run {
                ConsoleStore.shared.log("Dev Mode: \(appId) učitana ✓", type: .info)
                state = .app(node)
            }
        } catch {
            await MainActor.run {
                ConsoleStore.shared.log("Dev Mode: \(appId) – greška: \(error.localizedDescription)", type: .error)
                state = .error(error.localizedDescription)
            }
        }
    }
}
