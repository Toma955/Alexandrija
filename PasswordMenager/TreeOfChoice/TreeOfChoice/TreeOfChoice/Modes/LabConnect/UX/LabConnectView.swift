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
    @State private var selectedTree: DecisionTreeItem?
    @State private var selectedScript: NetworkScript?
    @State private var showTreeSelector = false
    @State private var showScriptSelector = false
    @State private var isTraining = false
    @State private var trainingProgress: Double = 0.0
    @State private var currentEpoch: Int = 0
    
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
        .sheet(isPresented: $showTreeSelector) {
            TreeSelectorView(selectedTree: $selectedTree) { tree in
                showTreeSelector = false
            }
            .environmentObject(localization)
        }
        .sheet(isPresented: $showScriptSelector) {
            ScriptSelectorView(selectedScript: $selectedScript) { script in
                showScriptSelector = false
            }
            .environmentObject(localization)
        }
    }
    
    // MARK: - Actions
    
    private func startTraining() {
        guard selectedTree != nil && selectedScript != nil else { return }
        
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
        HStack(spacing: 0) {
            // Left panel - Controls
            leftPanel
                .frame(width: 300)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Center - Network Topology Canvas
            NetworkTopologyCanvasView()
                .environmentObject(localization)
                .frame(maxWidth: .infinity)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Right panel - Status & Logs
            rightPanel
                .frame(width: 300)
        }
    }
    
    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.text("labConnect.controls"))
                .font(.headline)
                .foregroundColor(.white)
            
            // Tree selection
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.text("labConnect.selectTree"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Button(action: {
                    showTreeSelector = true
                }) {
                    HStack {
                        Text(selectedTree?.name ?? localization.text("labConnect.noTreeSelected"))
                            .foregroundColor(selectedTree != nil ? .white : .white.opacity(0.6))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Network script selection
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.text("labConnect.selectScript"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Button(action: {
                    showScriptSelector = true
                }) {
                    HStack {
                        Text(selectedScript?.name ?? localization.text("labConnect.noScriptSelected"))
                            .foregroundColor(selectedScript != nil ? .white : .white.opacity(0.6))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.black.opacity(0.4))
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
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.text("labConnect.status"))
                .font(.headline)
                .foregroundColor(.white)
            
            // Status indicators
            VStack(alignment: .leading, spacing: 12) {
                StatusIndicatorView(
                    label: localization.text("labConnect.agentStatus"),
                    value: localization.text("labConnect.idle"),
                    color: .gray
                )
                
                StatusIndicatorView(
                    label: localization.text("labConnect.trainingStatus"),
                    value: localization.text("labConnect.notStarted"),
                    color: .gray
                )
                
                StatusIndicatorView(
                    label: localization.text("labConnect.epoch"),
                    value: "\(currentEpoch)",
                    color: .white
                )
                
                if isTraining {
                    StatusIndicatorView(
                        label: localization.text("labConnect.progress"),
                        value: "\(Int(trainingProgress * 100))%",
                        color: accentOrange
                    )
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Logs
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.text("labConnect.logs"))
                    .font(.headline)
                    .foregroundColor(.white)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        LogEntryView(message: localization.text("labConnect.logReady"), timestamp: Date())
                    }
                }
                .frame(maxHeight: 300)
                .padding(8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.black.opacity(0.4))
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
