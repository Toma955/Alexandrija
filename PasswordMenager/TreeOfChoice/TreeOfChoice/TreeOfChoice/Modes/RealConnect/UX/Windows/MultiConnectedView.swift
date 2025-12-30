//
//  MultiConnectedView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import Combine
#if os(macOS)
import AppKit
#endif

struct MultiConnectedView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @StateObject private var roomSessionA = RoomSessionManager() // Client A
    @StateObject private var roomSessionB = RoomSessionManager() // Client B
    @StateObject private var keyManager = SessionKeyManager.shared
    
    @State private var isPinging = false
    @State private var serverStatus: ServerStatus = .unknown
    @State private var networkLogs: [LogsPanelView.LogEntry] = []
    @State private var showSettings = false
    @State private var serverAddress: String = "https://amessagesserver.onrender.com"
    
    @State private var clientACode: String = ""
    @State private var clientBCode: String = ""
    
    enum ServerStatus {
        case unknown
        case alive
        case dead
        
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .alive: return .green
            case .dead: return .red
            }
        }
        
        var text: String {
            switch self {
            case .unknown: return "Unknown"
            case .alive: return "Alive"
            case .dead: return "Dead"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header s ping botunom i settings
            HStack {
                Spacer()
                
                // Settings botun
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                
                // Ping botun
                Button(action: {
                    pingServer()
                }) {
                    HStack(spacing: 8) {
                        if isPinging {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "network")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                        Text("Ping Server")
                            .font(.system(size: 13, weight: .semibold))
                        
                        // Status indicator
                        Circle()
                            .fill(serverStatus.color)
                            .frame(width: 8, height: 8)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .disabled(isPinging)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .sheet(isPresented: $showSettings) {
                MultiConnectSettingsView(
                    isPresented: $showSettings,
                    serverAddress: $serverAddress
                )
            }
            
            // Gornji red: Client A, Topology, Client B
            HStack(spacing: 16) {
                // Client A
                ClientPanelView(
                    clientName: "Client A",
                    isLeftSide: true,
                    roomSession: roomSessionA,
                    roomCode: $clientACode,
                    onConnect: { code in
                        connectClientA(code: code)
                    }
                )
                .frame(width: 300)
                
                // Topology kvadrat
                TopologyPanelView()
                    .frame(maxWidth: .infinity)
                
                // Client B
                ClientPanelView(
                    clientName: "Client B",
                    isLeftSide: false,
                    roomSession: roomSessionB,
                    roomCode: $clientBCode,
                    onConnect: { code in
                        connectClientB(code: code)
                    }
                )
                .frame(width: 300)
            }
            .frame(height: 400)
            .padding(.horizontal, 16)
            
            // Veliki kvadrat za logove ispod
            LogsPanelView(logs: $networkLogs)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            setupNetworkLogging()
            addLog("Multi Connected session started", level: .info)
        }
    }
    
    private func setupNetworkLogging() {
        // Postavi callback za logove iz RoomSessionManager A
        roomSessionA.systemMessageHandler = { message in
            addLog("[Client A] System: \(message)", level: .info)
        }
        
        // Pratimo promjene u RoomSessionManager A
        roomSessionA.$isSessionReady
            .sink { isReady in
                if isReady {
                    addLog("[Client A] Session ready - connection established", level: .info)
                }
            }
            .store(in: &cancellables)
        
        roomSessionA.$lastError
            .compactMap { $0 }
            .sink { error in
                addLog("[Client A] Error: \(error)", level: .error)
            }
            .store(in: &cancellables)
        
        roomSessionA.$messages
            .sink { messages in
                if let lastMessage = messages.last {
                    let direction = lastMessage.direction == .outgoing ? "Sent" : "Received"
                    addLog("[Client A] \(direction) message: \(lastMessage.text)", level: .info)
                }
            }
            .store(in: &cancellables)
        
        // Pratimo network logove iz RoomSessionManager A
        roomSessionA.$networkLogs
            .sink { logs in
                if let lastLog = logs.last, !networkLogs.contains(where: { $0.message.contains("[Client A]") && $0.message.contains(lastLog) }) {
                    addLog("[Client A] \(lastLog)", level: .info)
                }
            }
            .store(in: &cancellables)
        
        // Postavi callback za logove iz RoomSessionManager B
        roomSessionB.systemMessageHandler = { message in
            addLog("[Client B] System: \(message)", level: .info)
        }
        
        // Pratimo promjene u RoomSessionManager B
        roomSessionB.$isSessionReady
            .sink { isReady in
                if isReady {
                    addLog("[Client B] Session ready - connection established", level: .info)
                }
            }
            .store(in: &cancellables)
        
        roomSessionB.$lastError
            .compactMap { $0 }
            .sink { error in
                addLog("[Client B] Error: \(error)", level: .error)
            }
            .store(in: &cancellables)
        
        roomSessionB.$messages
            .sink { messages in
                if let lastMessage = messages.last {
                    let direction = lastMessage.direction == .outgoing ? "Sent" : "Received"
                    addLog("[Client B] \(direction) message: \(lastMessage.text)", level: .info)
                }
            }
            .store(in: &cancellables)
        
        // Pratimo network logove iz RoomSessionManager B
        roomSessionB.$networkLogs
            .sink { logs in
                if let lastLog = logs.last, !networkLogs.contains(where: { $0.message.contains("[Client B]") && $0.message.contains(lastLog) }) {
                    addLog("[Client B] \(lastLog)", level: .info)
                }
            }
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
    
    private func pingServer() {
        isPinging = true
        serverStatus = .unknown
        addLog("Pinging server at \(serverAddress)...", level: .info)
        
        // Koristi custom server address (koristimo roomSessionA za ping)
        roomSessionA.pingServerWithAddress(serverAddress) { success, message in
            DispatchQueue.main.async {
                isPinging = false
                serverStatus = success ? .alive : .dead
                
                if success {
                    addLog("Server ping successful - server is alive", level: .info)
                } else {
                    addLog("Server ping failed: \(message ?? "Unknown error")", level: .error)
                }
            }
        }
    }
    
    private func connectClientA(code: String) {
        addLog("[Client A] Starting connection to room: \(code)", level: .info)
        clientACode = code
        
        roomSessionA.joinRoom(
            code: code,
            masterKey: keyManager.masterKey,
            serverAddress: serverAddress.isEmpty ? nil : serverAddress
        ) { success, errorText in
            DispatchQueue.main.async {
                if success {
                    addLog("[Client A] Successfully connected to room: \(code)", level: .info)
                } else {
                    addLog("[Client A] Failed to connect: \(errorText ?? "Unknown error")", level: .error)
                }
            }
        }
    }
    
    private func connectClientB(code: String) {
        addLog("[Client B] Starting connection to room: \(code)", level: .info)
        clientBCode = code
        
        roomSessionB.joinRoom(
            code: code,
            masterKey: keyManager.masterKey,
            serverAddress: serverAddress.isEmpty ? nil : serverAddress
        ) { success, errorText in
            DispatchQueue.main.async {
                if success {
                    addLog("[Client B] Successfully connected to room: \(code)", level: .info)
                } else {
                    addLog("[Client B] Failed to connect: \(errorText ?? "Unknown error")", level: .error)
                }
            }
        }
    }
    
    private func addLog(_ message: String, level: LogsPanelView.LogEntry.LogLevel) {
        let log = LogsPanelView.LogEntry(
            timestamp: Date(),
            message: message,
            level: level
        )
        networkLogs.append(log)
        
        // Zadrži samo zadnjih 200 logova
        if networkLogs.count > 200 {
            networkLogs.removeFirst()
        }
    }
}

// MARK: - Client Panel View

struct ClientPanelView: View {
    let clientName: String
    let isLeftSide: Bool
    let roomSession: RoomSessionManager
    @Binding var roomCode: String
    let onConnect: (String) -> Void
    
    @StateObject private var clientControlPanel = ClientControlPanelElement()
    @State private var showConnectionDialog = false
    
    var body: some View {
        ZStack {
            // Background okvir
            VStack(spacing: 8) {
                HStack {
                    Text(clientName)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Connection status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(roomSession.isSessionReady ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(roomSession.isSessionReady ? "Connected" : "Disconnected")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 12)
                
                // Room code display
                if !roomCode.isEmpty {
                    Text("Room: \(roomCode)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 12)
                }
                
                // Connect button (ako nije spojen)
                if !roomSession.isSessionReady {
                    Button(action: {
                        showConnectionDialog = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                            Text("Connect")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.7))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .zIndex(1)
            
            // View-ovi unutar okvira
            if clientControlPanel.showUser {
                ClientUserView(
                    isPresented: $clientControlPanel.showUser,
                    clientName: clientName
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(5)
            }
            
            if clientControlPanel.showTopology {
                ClientTopologyView(
                    isPresented: $clientControlPanel.showTopology,
                    clientName: clientName
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(5)
            }
            
            if clientControlPanel.showLogs {
                ClientLogsView(
                    isPresented: $clientControlPanel.showLogs,
                    clientName: clientName
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(5)
            }
            
            // Control Panel na dnu
            VStack {
                Spacer()
                ClientControlPanelView(
                    clientControlPanel: clientControlPanel,
                    clientName: clientName
                )
                .frame(height: 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(20)
        }
        .sheet(isPresented: $showConnectionDialog) {
            ConnectionToRoomView(
                title: "Spoji se na sobu",
                buttonTitle: "Poveži se",
                showsConnectButton: true,
                isServerConnected: true,
                message: nil
            ) { code in
                onConnect(code)
                showConnectionDialog = false
            } onCancel: {
                showConnectionDialog = false
            }
            .frame(width: 500, height: 300)
        }
    }
}

// MARK: - Topology Panel View

struct TopologyPanelView: View {
    var body: some View {
        VStack {
            Text("Topology")
                .font(.headline.bold())
                .foregroundColor(.white)
                .padding(.top, 12)
            
            Spacer()
            
            // Placeholder za topologiju
            VStack(spacing: 16) {
                Image(systemName: "network")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("Network Topology")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Logs Panel View

struct LogsPanelView: View {
    @Binding var logs: [LogEntry]
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let level: LogLevel
        
        enum LogLevel {
            case info, warning, error
            
            var color: Color {
                switch self {
                case .info: return .blue
                case .warning: return .orange
                case .error: return .red
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Network Logs")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                // Copy logs button
                Button(action: {
                    copyLogsToClipboard()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12, weight: .medium))
                        Text("Copy")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
                .disabled(logs.isEmpty)
                
                // Clear logs button
                Button(action: {
                    logs.removeAll()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                        Text("Clear")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
                .disabled(logs.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.horizontal, 16)
            
            // Logs list
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if logs.isEmpty {
                            Text("No logs available")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        } else {
                            ForEach(logs) { log in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(log.level.color)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(log.message)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        HStack(spacing: 8) {
                                            Text(log.timestamp, style: .time)
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.5))
                                            
                                            Text(log.timestamp, style: .date)
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                                .id(log.id)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: logs.count) { _ in
                    if let lastLog = logs.last {
                        withAnimation {
                            proxy.scrollTo(lastLog.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func copyLogsToClipboard() {
        let logText = logs.map { log in
            let timeString = log.timestamp.formatted(date: .omitted, time: .standard)
            let levelString = log.level == .error ? "ERROR" : log.level == .warning ? "WARN" : "INFO"
            return "[\(timeString)] [\(levelString)] \(log.message)"
        }.joined(separator: "\n")
        
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(logText, forType: .string)
        #else
        UIPasteboard.general.string = logText
        #endif
    }
}
