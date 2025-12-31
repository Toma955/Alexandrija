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
                    },
                    serverAddress: serverAddress
                )
                .frame(width: 300)
                
                // Topology kvadrat
                RealConnectTopologyView(
                    roomSessionA: roomSessionA,
                    roomSessionB: roomSessionB,
                    serverAddress: serverAddress,
                    clientACode: clientACode,
                    clientBCode: clientBCode
                )
                    .frame(maxWidth: .infinity)
                
                // Client B
                ClientPanelView(
                    clientName: "Client B",
                    isLeftSide: false,
                    roomSession: roomSessionB,
                    roomCode: $clientBCode,
                    onConnect: { code in
                        connectClientB(code: code)
                    },
                    serverAddress: serverAddress
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
        // Provjeri je li već spojen na istu sobu
        if roomSessionA.isSessionReady && roomSessionA.roomCode == code {
            addLog("[Client A] Already connected to room: \(code)", level: .info)
            clientACode = code
            return
        }
        
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
        // Provjeri je li već spojen na istu sobu
        if roomSessionB.isSessionReady && roomSessionB.roomCode == code {
            addLog("[Client B] Already connected to room: \(code)", level: .info)
            clientBCode = code
            return
        }
        
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
    let serverAddress: String
    
    @StateObject private var clientControlPanel = ClientControlPanelElement()
    @State private var messageText: String = ""
    @State private var showCustomInput: Bool = false
    @State private var sendInterval: TimeInterval = 0.0 // 0 = ne šalje se (crvena boja)
    @State private var autoSendTask: Task<Void, Never>?
    
    // Interval opcije: 0 (ne šalje), 5s, 10s, 20s, 40s, 60s, 120s (2min), 240s (4min)
    private let intervalOptions: [TimeInterval] = [0, 5, 10, 20, 40, 60, 120, 240]
    private var intervalDisplayName: String {
        if sendInterval == 0 {
            return "0"
        } else if sendInterval < 60 {
            return "\(Int(sendInterval))s"
        } else {
            let minutes = Int(sendInterval) / 60
            return "\(minutes)min"
        }
    }
    
    var body: some View {
        ZStack {
            // Background okvir
            if roomSession.isSessionReady {
                // Chat interface kada je spojen
                chatInterfaceView
            } else {
                // Connection status view kada nije spojen
                connectionStatusView
            }
            
            // View-ovi unutar okvira
            if clientControlPanel.showUser {
                ClientUserView(
                    isPresented: $clientControlPanel.showUser,
                    clientName: clientName,
                    roomSession: roomSession,
                    roomCode: Binding<String?>(
                        get: { roomCode },
                        set: { if let newValue = $0 { roomCode = newValue } }
                    ),
                    onConnect: onConnect,
                    serverAddress: serverAddress.isEmpty ? nil : serverAddress
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
    }
    
    // MARK: - Connection Status View (kada nije spojen)
    
    private var connectionStatusView: some View {
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
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .zIndex(1)
    }
    
    // MARK: - Chat Interface View (kada je spojen)
    
    private var chatInterfaceView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(clientName)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    if !roomCode.isEmpty {
                        Text("Room: \(roomCode)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Connected")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(roomSession.messages) { message in
                            MessageBubbleView(
                                message: message,
                                isHighlighted: false,
                                textScale: 0.9
                            )
                            .id(message.id)
                        }
                    }
                    .padding(8)
                }
                .onChange(of: roomSession.messages.count) { _ in
                    if let lastMessage = roomSession.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // 4 gumba: Custom, Sat, Random, X
            HStack(spacing: 12) {
                // 1. Custom button
                Button(action: {
                    showCustomInput.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .medium))
                        Text("Custom")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(showCustomInput ? Color(red: 1.0, green: 0.36, blue: 0.0) : Color(red: 1.0, green: 0.36, blue: 0.0).opacity(0.7))
                    )
                }
                .buttonStyle(.plain)
                
                // 2. Sat button (interval selector)
                Button(action: {
                    cycleInterval()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text(intervalDisplayName)
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(sendInterval == 0 ? Color.red.opacity(0.7) : Color(red: 1.0, green: 0.36, blue: 0.0).opacity(0.7))
                    )
                }
                .buttonStyle(.plain)
                
                // 3. Random button
                Button(action: {
                    sendRandomMessage()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 12, weight: .medium))
                        Text("Random")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 1.0, green: 0.36, blue: 0.0).opacity(0.7))
                    )
                }
                .buttonStyle(.plain)
                
                // 4. X button (disconnect)
                Button(action: {
                    disconnect()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                        Text("X")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.7))
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Input bar (samo ako je Custom button kliknut)
            if showCustomInput {
                MessagesInputBar(
                    messageText: $messageText,
                    sendOnEnter: true,
                    controlSize: 32,
                    barWidth: .infinity,
                    barHeight: 50,
                    onSend: { text in
                        roomSession.sendText(text)
                        messageText = "" // Očisti input nakon slanja
                    }
                )
                .padding(8)
            } else {
                // Placeholder kada Custom nije aktivan
                HStack {
                    Spacer()
                    if sendInterval > 0 {
                        Text("Auto sending: every \(intervalDisplayName)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text("Click Custom to send messages manually")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .frame(height: 50)
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .zIndex(1)
        .onDisappear {
            stopAutoSending()
        }
    }
    
    // MARK: - Auto Send Functions
    
    private func cycleInterval() {
        guard let currentIndex = intervalOptions.firstIndex(of: sendInterval) else {
            sendInterval = intervalOptions[0]
            restartAutoSending()
            return
        }
        
        let nextIndex = (currentIndex + 1) % intervalOptions.count
        sendInterval = intervalOptions[nextIndex]
        restartAutoSending()
    }
    
    private func startAutoSending() {
        stopAutoSending() // Zaustavi postojeći task ako postoji
        
        // Ne pokreći ako je interval 0
        guard sendInterval > 0 else { return }
        
        let currentRoomSession = roomSession
        
        autoSendTask = Task { @MainActor in
            while sendInterval > 0 && currentRoomSession.isSessionReady {
                // Čitaj trenutni interval dinamički (ažurira se svaki put)
                let currentInterval = sendInterval
                
                // Ako je interval postao 0, zaustavi
                guard currentInterval > 0 else { break }
                
                // Random vrijeme između 0 i sendInterval
                let randomDelay = Double.random(in: 0...currentInterval)
                
                // Čekaj random vrijeme
                try? await Task.sleep(nanoseconds: UInt64(randomDelay * 1_000_000_000))
                
                // Provjeri ponovno nakon sleep-a
                guard sendInterval > 0 && currentRoomSession.isSessionReady else { break }
                
                // Generiraj i pošalji random poruku
                let randomMessage = generateRandomMessage()
                currentRoomSession.sendText(randomMessage)
            }
        }
    }
    
    private func sendRandomMessage() {
        guard roomSession.isSessionReady else { return }
        
        // Generiraj i pošalji random poruku odmah
        let randomMessage = generateRandomMessage()
        roomSession.sendText(randomMessage)
    }
    
    private func disconnect() {
        // Zaustavi auto sending
        stopAutoSending()
        
        // Disconnect od sobe
        roomSession.close()
        
        // Resetuj stanje
        DispatchQueue.main.async {
            self.showCustomInput = false
            self.sendInterval = 0
        }
    }
    
    private func stopAutoSending() {
        autoSendTask?.cancel()
        autoSendTask = nil
    }
    
    private func restartAutoSending() {
        if sendInterval > 0 {
            stopAutoSending()
            startAutoSending()
        } else {
            stopAutoSending()
        }
    }
    
    private func generateRandomMessage() -> String {
        let messages = [
            "Hello!",
            "Test message",
            "Auto message \(Int.random(in: 1...1000))",
            "Random: \(UUID().uuidString.prefix(8))",
            "Ping",
            "Message at \(Date().formatted(date: .omitted, time: .shortened))",
            "Auto test",
            "Random text"
        ]
        return messages.randomElement() ?? "Auto message"
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
