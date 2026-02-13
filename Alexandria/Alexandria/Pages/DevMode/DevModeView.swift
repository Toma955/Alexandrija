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
            // Lijevo: Eluminatium/search sadržaj – učitava se kao u Search tabu
            EluminatiumView(
                initialSearchQuery: .constant(nil),
                currentAddress: $currentAddress,
                onOpenAppFromSearch: nil,
                onSwitchToDevMode: nil
            )
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
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(4)
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
