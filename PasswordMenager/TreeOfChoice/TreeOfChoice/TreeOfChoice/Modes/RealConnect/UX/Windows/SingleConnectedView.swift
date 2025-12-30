//
//  SingleConnectedView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import Combine

struct SingleConnectedView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @StateObject private var roomSession = RoomSessionManager()
    @StateObject private var keyManager = SessionKeyManager.shared
    
    @State private var showConnectionView = true
    @State private var isConnecting = false
    @State private var connectionError: String? = nil
    @State private var serverAddress: String = "https://amessagesserver.onrender.com"
    @State private var messageText: String = ""
    @State private var networkLogs: [LogsPanelView.LogEntry] = []
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
            
            if showConnectionView {
                // Prikaži ConnectionToRoomView dok se ne spoji
                connectionView
            } else if roomSession.isSessionReady {
                // Prikaži chat interface kada je konekcija uspostavljena
                chatView
            } else if isConnecting {
                // Prikaži loading dok se spaja
                connectingView
            } else {
                // Greška ili nešto drugo
                connectionView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            setupNetworkLogging()
            addLog("Single Connected session started", level: .info)
        }
    }
    
    // MARK: - Connection View
    
    private var connectionView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ConnectionToRoomView(
                title: "Spoji se na sobu",
                buttonTitle: "Poveži se",
                showsConnectButton: true,
                isServerConnected: true, // Možemo dodati provjeru servera ako treba
                message: connectionError
            ) { code in
                connectToRoom(code: code)
            } onCancel: {
                // Vrati se nazad ili zatvori
            }
            .frame(width: 500)
            
            Spacer()
        }
        .padding(40)
    }
    
    // MARK: - Connecting View
    
    private var connectingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.orange)
            
            Text("Povezujem se na server...")
                .font(.headline)
                .foregroundColor(.white)
            
            if let error = connectionError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
        .padding(40)
    }
    
    // MARK: - Chat View
    
    private var chatView: some View {
        HStack(spacing: 0) {
            // Chat panel (lijevo)
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chat")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        if let code = roomSession.roomCode {
                            Text("Room: \(code)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(roomSession.isSessionReady ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(roomSession.isSessionReady ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Disconnect button
                    Button(action: {
                        disconnect()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Color.black.opacity(0.6))
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(roomSession.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isHighlighted: false,
                                    textScale: 1.0
                                )
                                .id(message.id)
                            }
                        }
                        .padding(16)
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
                
                // Input bar
                MessagesInputBar(
                    messageText: $messageText,
                    sendOnEnter: true,
                    controlSize: 40,
                    barWidth: .infinity,
                    barHeight: 60,
                    onSend: { text in
                        roomSession.sendText(text)
                    }
                )
                .padding(16)
            }
            .frame(width: 500)
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Logs panel (desno)
            LogsPanelView(logs: $networkLogs)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Functions
    
    @State private var cancellables = Set<AnyCancellable>()
    
    private func setupNetworkLogging() {
        // Postavi callback za logove iz RoomSessionManager
        roomSession.systemMessageHandler = { message in
            addLog("System: \(message)", level: .info)
        }
        
        // Pratimo promjene u RoomSessionManager
        roomSession.$isSessionReady
            .sink { isReady in
                if isReady {
                    addLog("Session ready - connection established", level: .info)
                }
            }
            .store(in: &cancellables)
        
        roomSession.$lastError
            .compactMap { $0 }
            .sink { error in
                addLog("Error: \(error)", level: .error)
            }
            .store(in: &cancellables)
        
        roomSession.$messages
            .sink { messages in
                if let lastMessage = messages.last {
                    let direction = lastMessage.direction == .outgoing ? "Sent" : "Received"
                    addLog("\(direction) message: \(lastMessage.text)", level: .info)
                }
            }
            .store(in: &cancellables)
        
        // Pratimo network logove iz RoomSessionManager
        roomSession.$networkLogs
            .sink { logs in
                // Konvertiraj string logove u LogEntry
                if let lastLog = logs.last, !networkLogs.contains(where: { $0.message == lastLog }) {
                    addLog(lastLog, level: .info)
                }
            }
            .store(in: &cancellables)
    }
    
    private func connectToRoom(code: String) {
        isConnecting = true
        connectionError = nil
        showConnectionView = false
        addLog("Starting connection to room: \(code)", level: .info)
        
        roomSession.joinRoom(
            code: code,
            masterKey: keyManager.masterKey,
            serverAddress: serverAddress.isEmpty ? nil : serverAddress
        ) { success, errorText in
            DispatchQueue.main.async {
                isConnecting = false
                
                if success {
                    addLog("Successfully connected to room: \(code)", level: .info)
                    showConnectionView = false
                    connectionError = nil
                } else {
                    addLog("Failed to connect: \(errorText ?? "Unknown error")", level: .error)
                    showConnectionView = true
                    connectionError = errorText ?? "Failed to connect"
                }
            }
        }
    }
    
    private func disconnect() {
        addLog("Disconnecting from room", level: .info)
        roomSession.close()
        showConnectionView = true
        isConnecting = false
        connectionError = nil
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
