//
//  LabConnectView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Lab Connect mod - treniranje Connection agenta na simuliranim uvjetima
struct LabConnectView: View {
    @EnvironmentObject private var localization: LocalizationManager
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    @StateObject private var sessionStarterElement = SessionStarterElement()
    @StateObject private var canvasElement = CanvasElement()
    @State private var isTraining = false
    @State private var trainingProgress: Double = 0.0
    @State private var currentEpoch: Int = 0
    @State private var lineYPosition: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Pozadina
            Color.black.opacity(0.95)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content
                mainContentView
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
    }
    
    // MARK: - Actions
    
    private func startTraining() {
        isTraining = true
        trainingProgress = 0.0
        currentEpoch = 0
        
        // Simulate training progress
        Task {
            while isTraining {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                if !isTraining { break }
                
                await MainActor.run {
                    trainingProgress += 0.01
                    if trainingProgress >= 1.0 {
                        trainingProgress = 0.0
                        currentEpoch += 1
                    }
                }
            }
        }
    }
    
    private func stopTraining() {
        isTraining = false
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.text("mode.labConnect.title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(localization.text("mode.labConnect.description"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Training status indicator
            if isTraining {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                    Text("Training...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.6))
    }
    
    private var mainContentView: some View {
        ZStack {
            HStack(spacing: 0) {
                // Empty left panel (keeps original layout for topology positioning)
                Color.clear
                    .frame(width: 300)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Center - Network Topology Canvas
                NetworkTopologyCanvasView(canvasElement: canvasElement)
                    .environmentObject(localization)
                    .frame(maxWidth: .infinity)
                    .onPreferenceChange(LinePositionKey.self) { value in
                        lineYPosition = value
                    }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Empty right panel (keeps original layout for topology positioning)
                rightPanel
                    .frame(width: 300)
            }
            
            // Session Starter in top left corner (overlay) - iste dimenzije kao actionButtonsPanel
            HStack {
                VStack {
                    sessionStarterPanel
                        .padding(.leading, 5) // 5px od lijeve bijele linije
                    Spacer()
                }
                Spacer()
            }
            
            // Action buttons in top right corner (overlay) - ista pozicija i visina kao ComponentPaletteView
            HStack {
                Spacer()
                VStack {
                    actionButtonsPanel
                        .padding(.trailing, 5) // 5px od desne bijele linije
                    Spacer()
                }
            }
            
            // Bijela linija preko cijelog ekrana
            if lineYPosition > 0 {
                GeometryReader { fullGeometry in
                    let adjustedY = lineYPosition - fullGeometry.frame(in: .global).minY
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .offset(y: adjustedY)
                }
            }
        }
    }
    
    private var sessionStarterPanel: some View {
        SessionStarterElementView(sessionStarterElement: sessionStarterElement)
            .frame(width: 280, height: 200) // Iste dimenzije kao actionButtonsPanel
            .background(Color.gray.opacity(0.3))
            .cornerRadius(16)
    }
    
    private var simulationArea: some View {
        VStack(spacing: 20) {
            // Agent visualization
            HStack(spacing: 40) {
                AgentVisualizationView(name: "Connection Agent", isActive: true)
            }
            
            // Network topology
            NetworkTopologyView()
            
            // Status info
            VStack(spacing: 8) {
                Text(localization.text("labConnect.simulationStatus"))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(localization.text("labConnect.notRunning"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color.black.opacity(0.2))
    }
    
    private var rightPanel: some View {
        // Empty panel - keeps original layout structure for topology positioning
        Color.clear
    }
    
    private var actionButtonsPanel: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            // Row 1: Save As, Upload (Orange)
            ActionButton(title: "save as", icon: "square.and.arrow.down", color: accentOrange) {}
            ActionButton(title: "upload", icon: "square.and.arrow.up", color: accentOrange) {}

            // Row 2: Delete Topology, Delete Connections (Red)
            ActionButton(title: "delete topologi", icon: "trash", color: .red) {
                canvasElement.deleteAllTopology()
            }
            ActionButton(title: "delete conections", icon: "trash.circle", color: .red) {
                canvasElement.deleteAllConnections()
            }

            // Row 3: Autoconnect, Edit mode / Config mode (Green)
            ActionButton(title: "autocnect", icon: "arrow.triangle.2.circlepath", color: .green) {}
            ActionButton(title: canvasElement.isTestMode ? "Config mode" : "Edit mode", icon: "checkmark.circle", color: .green) {
                canvasElement.toggleTestMode()
            }
        }
        .padding(10)
        .frame(width: 280, height: 200) // Ista visina kao ComponentPaletteView: 200px
        .background(Color(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0))
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views

struct AgentVisualizationView: View {
    let name: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? Color(red: 1.0, green: 0.36, blue: 0.0) : Color.white.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "network")
                    .font(.title)
                    .foregroundColor(.white)
            }
            
            Text(name)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

struct NetworkTopologyView: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 60) {
                NodeView(label: "Node A")
                NodeView(label: "Node B")
            }
            
            // Connection line
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 200, y: 0))
            }
            .stroke(Color(red: 1.0, green: 0.36, blue: 0.0), lineWidth: 2)
            .frame(width: 200, height: 2)
        }
        .padding(20)
    }
}

struct NodeView: View {
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.blue.opacity(0.6))
                .frame(width: 50, height: 50)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct StatusIndicatorView: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct LogEntryView: View {
    let message: String
    let timestamp: Date
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 60, alignment: .leading)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

