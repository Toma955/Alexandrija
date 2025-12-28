//
//  RealConnectView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Real Connect mod - treniranje Connection agenta na stvarnim uvjetima
struct RealConnectView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    @State private var isConnected = false
    @State private var connectionStatus: ConnectionStatus = .disconnected
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
            
            VStack(spacing: 0) {
                headerView
                mainContentView
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.text("mode.realConnect.title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(localization.text("mode.realConnect.description"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Connection status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(colorForStatus(connectionStatus))
                    .frame(width: 12, height: 12)
                
                Text(statusText(connectionStatus))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(Color.black.opacity(0.6))
    }
    
    private var mainContentView: some View {
        HStack(spacing: 0) {
            leftPanel.frame(width: 300)
            Divider().background(Color.white.opacity(0.2))
            connectionArea.frame(maxWidth: .infinity)
            Divider().background(Color.white.opacity(0.2))
            rightPanel.frame(width: 300)
        }
    }
    
    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.text("realConnect.controls"))
                .font(.headline)
                .foregroundColor(.white)
            
            // Connection controls
            VStack(alignment: .leading, spacing: 12) {
                Button(action: {
                    connect()
                }) {
                    HStack {
                        Image(systemName: "network")
                        Text(localization.text("realConnect.connect"))
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accentOrange)
                    .cornerRadius(8)
                }
                .disabled(connectionStatus == .connected || connectionStatus == .connecting)
                
                Button(action: {
                    disconnect()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text(localization.text("realConnect.disconnect"))
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)
                }
                .disabled(connectionStatus != .connected)
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            // Settings
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.text("realConnect.settings"))
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.text("realConnect.selectTree"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Button(action: {}) {
                        HStack {
                            Text(localization.text("realConnect.noTreeSelected"))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.black.opacity(0.4))
    }
    
    private var connectionArea: some View {
        VStack(spacing: 30) {
            // Connection visualization
            if connectionStatus == .connected {
                HStack(spacing: 60) {
                    NodeView(label: "This Device")
                    NodeView(label: "Remote Device")
                }
                
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 200, y: 0))
                }
                .stroke(Color.green, lineWidth: 3)
                .frame(width: 200, height: 3)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "network.slash")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text(localization.text("realConnect.notConnected"))
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Agent status
            AgentVisualizationView(
                name: "Connection Agent",
                isActive: connectionStatus == .connected
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color.black.opacity(0.2))
    }
    
    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.text("realConnect.status"))
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                StatusIndicatorView(
                    label: localization.text("realConnect.connectionStatus"),
                    value: statusText(connectionStatus),
                    color: colorForStatus(connectionStatus)
                )
                
                StatusIndicatorView(
                    label: localization.text("realConnect.agentStatus"),
                    value: connectionStatus == .connected ? localization.text("realConnect.active") : localization.text("realConnect.idle"),
                    color: connectionStatus == .connected ? .green : .gray
                )
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    LogEntryView(message: localization.text("realConnect.logReady"), timestamp: Date())
                }
            }
            .frame(maxHeight: 300)
            .padding(8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding(20)
        .background(Color.black.opacity(0.4))
    }
    
    // MARK: - Actions
    
    private func connect() {
        connectionStatus = .connecting
        // TODO: Implement actual connection logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            connectionStatus = .connected
        }
    }
    
    private func disconnect() {
        connectionStatus = .disconnected
        // TODO: Implement disconnection logic
    }
    
    private func colorForStatus(_ status: ConnectionStatus) -> Color {
        switch status {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .error: return .red
        }
    }
    
    private func statusText(_ status: ConnectionStatus) -> String {
        switch status {
        case .disconnected: return localization.text("realConnect.disconnected")
        case .connecting: return localization.text("realConnect.connecting")
        case .connected: return localization.text("realConnect.connected")
        case .error: return localization.text("realConnect.error")
        }
    }
}










