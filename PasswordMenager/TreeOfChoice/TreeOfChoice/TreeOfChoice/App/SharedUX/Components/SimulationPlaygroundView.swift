//
//  SimulationPlaygroundView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Interaktivni playground za testiranje scenarija i simulacije
struct SimulationPlaygroundView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @State private var isRunning = false
    @State private var selectedMode: SimulationMode = .labConnect
    @State private var simulationSpeed: Double = 1.0
    @State private var networkConditions = NetworkConditions()
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    enum SimulationMode {
        case labConnect
        case realConnect
        case labSecurity
        case realSecurity
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Control Panel
            controlPanel
            
            // Simulation Area
            simulationArea
        }
    }
    
    // MARK: - Subviews
    
    private var controlPanel: some View {
        VStack(spacing: 12) {
            // Mode Selector
            HStack(spacing: 12) {
                Text(localization.text("simulation.mode"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Picker("", selection: $selectedMode) {
                    Text(localization.text("mode.labConnect.title")).tag(SimulationMode.labConnect)
                    Text(localization.text("mode.realConnect.title")).tag(SimulationMode.realConnect)
                    Text(localization.text("mode.labSecurity.title")).tag(SimulationMode.labSecurity)
                    Text(localization.text("mode.realSecurity.title")).tag(SimulationMode.realSecurity)
                }
                .pickerStyle(.segmented)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Controls
            HStack(spacing: 16) {
                // Play/Pause
                Button(action: {
                    isRunning.toggle()
                }) {
                    Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(isRunning ? .red : accentOrange)
                }
                
                // Speed Control
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.text("simulation.speed"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack {
                        Slider(value: $simulationSpeed, in: 0.1...5.0)
                            .frame(width: 200)
                        
                        Text("\(simulationSpeed, specifier: "%.1f")x")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 40)
                    }
                }
                
                Spacer()
                
                // Network Conditions
                Button(action: {
                    // Show network conditions panel
                }) {
                    Label(localization.text("simulation.networkConditions"), systemImage: "network")
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accentOrange)
                        .cornerRadius(8)
                }
            }
            
            // Network Conditions Sliders
            if networkConditions.isExpanded {
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    networkConditionsView
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
    }
    
    private var networkConditionsView: some View {
        VStack(spacing: 12) {
            // Packet Loss
            HStack {
                Text(localization.text("simulation.packetLoss"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 120, alignment: .leading)
                
                Slider(value: $networkConditions.packetLoss, in: 0...100)
                
                Text("\(Int(networkConditions.packetLoss))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 50)
            }
            
            // Latency
            HStack {
                Text(localization.text("simulation.latency"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 120, alignment: .leading)
                
                Slider(value: $networkConditions.latency, in: 0...1000)
                
                Text("\(Int(networkConditions.latency))ms")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 50)
            }
            
            // Bandwidth
            HStack {
                Text(localization.text("simulation.bandwidth"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 120, alignment: .leading)
                
                Slider(value: $networkConditions.bandwidth, in: 0...100)
                
                Text("\(Int(networkConditions.bandwidth))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 50)
            }
        }
    }
    
    private var simulationArea: some View {
        ZStack {
            // Background
            Color.black.opacity(0.2)
            
            if isRunning {
                // Running simulation visualization
                simulationVisualization
            } else {
                // Idle state
                idleState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var simulationVisualization: some View {
        VStack(spacing: 20) {
            // Agent nodes
            HStack(spacing: 40) {
                AgentNodeView(name: "Watchman", isActive: true)
                AgentNodeView(name: "Connection", isActive: true)
                AgentNodeView(name: "Counterintelligence", isActive: true)
            }
            
            // Network flow visualization
            NetworkFlowView()
        }
        .padding(32)
    }
    
    private var idleState: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.3))
            
            Text(localization.text("simulation.idle"))
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Text(localization.text("simulation.idleDescription"))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Supporting Views

struct AgentNodeView: View {
    let name: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(isActive ? Color(red: 1.0, green: 0.36, blue: 0.0) : Color.white.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: iconForAgent(name))
                        .foregroundColor(.white)
                )
            
            Text(name)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private func iconForAgent(_ name: String) -> String {
        switch name.lowercased() {
        case "watchman": return "eye"
        case "connection": return "network"
        case "counterintelligence": return "shield"
        default: return "circle"
        }
    }
}

struct NetworkFlowView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
            }
            .stroke(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.36, blue: 0.0), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, dash: [5, 5])
            )
        }
        .frame(height: 2)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationOffset = 100
            }
        }
    }
}

// MARK: - Models

struct NetworkConditions {
    var packetLoss: Double = 0
    var latency: Double = 0
    var bandwidth: Double = 100
    var isExpanded: Bool = false
}
















