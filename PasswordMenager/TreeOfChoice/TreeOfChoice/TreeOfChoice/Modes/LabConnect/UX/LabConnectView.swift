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
    @StateObject private var bottomControlPanel = BottomControlPanelElement()
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
                // Left panel s ClientSidesView
                GeometryReader { panelGeometry in
                    ClientSidesView(
                        geometry: panelGeometry,
                        lineYPosition: lineYPosition,
                        isLeftSide: true
                    )
                }
                .frame(width: 300)
                
                // Center - Network Topology Canvas
                NetworkTopologyCanvasView(canvasElement: canvasElement)
                    .environmentObject(localization)
                    .frame(maxWidth: .infinity)
                    .onPreferenceChange(LinePositionKey.self) { value in
                        lineYPosition = value
                    }
                
                // Right panel s ClientSidesView
                GeometryReader { panelGeometry in
                    ClientSidesView(
                        geometry: panelGeometry,
                        lineYPosition: lineYPosition,
                        isLeftSide: false
                    )
                }
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
            
            // Veliki kvadrat na dnu - 10px od dna ekrana, 10px od lijevog/desnog ruba, i 10px od vrha bijele linije ako postoji
            GeometryReader { fullGeometry in
                let squareWidth = fullGeometry.size.width - 20 // 10px lijevo + 10px desno = 20px ukupno
                let squareX = fullGeometry.size.width / 2 // Centar ekrana
                
                // Donji rub kvadrata - mora biti iznad narančastog control panela
                let bottomEdge: CGFloat
                if !bottomControlPanel.isGameMode && bottomControlPanel.isEditMode {
                    // U Edit mode-u, donja linija prozora mora biti iznad narančastog control panela
                    // Control panel ima visinu 60px + padding 20px = 80px, dodajem još malo prostora
                    bottomEdge = fullGeometry.size.height - 100 // Iznad narančastog control panela
                } else {
                    bottomEdge = fullGeometry.size.height - 10 // Normalna pozicija
                }
                
                // Gornji rub kvadrata - proširi prema gore kada je Edit mode u Track mode-u
                let topEdge: CGFloat
                if !bottomControlPanel.isGameMode && bottomControlPanel.isEditMode {
                    // U Edit mode-u u Track mode-u, proširi skroz do vrha iznad topologije (malo niže)
                    topEdge = 20 // Malo niže od vrha ekrana, iznad topologije
                } else if lineYPosition > 0 {
                    let adjustedY = lineYPosition - fullGeometry.frame(in: .global).minY
                    // Normalna pozicija - 10px ispod bijele linije
                    topEdge = adjustedY + 10
                } else {
                    // Ako nema linije, koristi fiksnu visinu
                    topEdge = bottomEdge - 200 // Fiksna visina 200px
                }
                
                let squareHeight = bottomEdge - topEdge
                let squareY = topEdge + (squareHeight / 2) // Centar kvadrata
                
                // Pozicija narančastog control panela - ispod prozora, blizu dna
                let controlPanelY: CGFloat
                if !bottomControlPanel.isGameMode && bottomControlPanel.isEditMode {
                    // U Edit mode-u, control panel je ispod prozora, blizu dna
                    controlPanelY = fullGeometry.size.height - 40 // Blizu dna (40px od dna)
                } else {
                    // Normalna pozicija - unutar prozora
                    controlPanelY = fullGeometry.size.height - 40
                }
                
                return ZStack {
                    if !bottomControlPanel.isGameMode && bottomControlPanel.isEditMode {
                        // Edit mode u Track mode-u - prozor i control panel odvojeno
                        // Prozor - samo sadržaj (TrackModeView)
                        ZStack {
                            // Background
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: squareWidth, height: squareHeight)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray, lineWidth: 2)
                                )
                            
                            // Sadržaj prozora (bez control panela)
                            TrackModeView()
                                .id("trackMode")
                        }
                        .frame(width: squareWidth, height: squareHeight)
                        .position(
                            x: squareX,
                            y: squareY
                        )
                        
                        // Narančasti control panel - ispod prozora
                        ControlPanelOnlyView(bottomControlPanel: bottomControlPanel)
                            .frame(width: squareWidth)
                            .position(
                                x: squareX,
                                y: controlPanelY
                            )
                    } else {
                        // Normalno stanje - control panel unutar prozora
                        ZStack {
                            // Background
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: squareWidth, height: squareHeight)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray, lineWidth: 2)
                                )
                            
                            // Bottom Control Panel Content (s view-ovima i control panelom)
                            BottomControlPanelView(bottomControlPanel: bottomControlPanel)
                                .frame(width: squareWidth, height: squareHeight)
                        }
                        .frame(width: squareWidth, height: squareHeight)
                        .position(
                            x: squareX,
                            y: squareY
                        )
                    }
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
            ActionButton(title: "delete topologi", icon: "trash", color: .red, fontSize: .caption2) {
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
    let fontSize: Font?
    let action: () -> Void
    
    init(title: String, icon: String, color: Color, fontSize: Font? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.fontSize = fontSize
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(fontSize ?? .caption)
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

// MARK: - Control Panel Only View (bez view-ova)

struct ControlPanelOnlyView: View {
    @ObservedObject var bottomControlPanel: BottomControlPanelElement
    @State private var isHovered: Bool = false
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        VStack {
            Spacer()
            animatedOrangeButton
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var animatedOrangeButton: some View {
        ZStack {
            if !bottomControlPanel.isExpanded {
                Button(action: {
                    isHovered = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        bottomControlPanel.toggleExpanded()
                    }
                }) {
                    Capsule()
                        .fill(accentOrange)
                        .frame(
                            width: isHovered ? 70 : 60,
                            height: isHovered ? 12 : 10
                        )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
            } else {
                RoundedRectangle(cornerRadius: 30)
                    .fill(accentOrange)
                    .frame(width: 320, height: 60)
            }
            
            if bottomControlPanel.isExpanded {
                expandedControls
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: bottomControlPanel.isExpanded)
        .onContinuousHover { phase in
            if !bottomControlPanel.isExpanded {
                switch phase {
                case .active:
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovered = true
                    }
                case .ended:
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovered = false
                    }
                }
            } else {
                isHovered = false
            }
        }
    }
    
    private var expandedControls: some View {
        HStack(spacing: 16) {
            // Toggle switch
            ZStack {
                Capsule()
                    .fill(accentOrange)
                    .frame(width: 42, height: 36)
                
                HStack(spacing: 8) {
                    // Game mode
                    ZStack {
                        if bottomControlPanel.isGameMode {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 38, height: 38)
                                .zIndex(0)
                        }
                        
                        if let nsImage = loadIcon(named: "gamepad") {
                            Color.white
                                .mask(
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 58, height: 58)
                                )
                                .frame(width: 58, height: 58)
                                .zIndex(1)
                        } else {
                            Image(systemName: "gamecontroller.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .zIndex(1)
                        }
                    }
                    .frame(width: 30, height: 40)
                    .offset(x: -20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !bottomControlPanel.isGameMode {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                bottomControlPanel.isGameMode = true
                            }
                        }
                    }
                    
                    // Track mode
                    ZStack {
                        if !bottomControlPanel.isGameMode {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 38, height: 38)
                                .zIndex(0)
                        }
                        
                        if let nsImage = loadIcon(named: "Tracks") {
                            Color.white
                                .mask(
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                )
                                .frame(width: 28, height: 28)
                                .zIndex(1)
                        } else {
                            Image(systemName: "map.fill")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .zIndex(1)
                        }
                    }
                    .frame(width: 20, height: 30)
                    .padding(.trailing, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if bottomControlPanel.isGameMode {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                bottomControlPanel.isGameMode = false
                            }
                        }
                    }
                }
            }
            
            // Edit/Close button - u Edit mode-u prikaži Close, inače Edit
            if !bottomControlPanel.isGameMode && bottomControlPanel.isEditMode {
                // Close button u Edit mode-u
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        bottomControlPanel.isEditMode = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else {
                // Edit button u normalnom stanju
                Button(action: {
                    if !bottomControlPanel.isGameMode {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            bottomControlPanel.isEditMode.toggle()
                        }
                    }
                }) {
                    Image(systemName: "pencil")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // Collapse button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    bottomControlPanel.toggleExpanded()
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // Play/Save button - u Edit mode-u prikaži Save, inače Play
            if !bottomControlPanel.isGameMode && bottomControlPanel.isEditMode {
                // Save button u Edit mode-u
                Button(action: {
                    // TODO: Implement Save action
                }) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else {
                // Play by step button u normalnom stanju
                Button(action: {}) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // One step
            Button(action: {}) {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private func loadIcon(named name: String) -> NSImage? {
        if let imageURL = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Shared/UX/Icons") {
            if let image = NSImage(contentsOf: imageURL) {
                return image
            }
        }
        if let imageURL = Bundle.main.url(forResource: name, withExtension: "png") {
            return NSImage(contentsOf: imageURL)
        }
        if let assetImage = NSImage(named: name) {
            return assetImage
        }
        return nil
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

