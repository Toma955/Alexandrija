//
//  CreateTreeDialog.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit

// MARK: - Status Type

enum StatusType {
    case success
    case error
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

/// Dialog za kreiranje novog stabla odluke
struct CreateTreeDialog: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isPresented: Bool
    var onTreeCreated: ((DecisionTreeItem) -> Void)? = nil
    
    @State private var treeName: String = ""
    @State private var selectedAgent: AgentType = .watchman
    @State private var description: String = ""
    @State private var hashField: String = ""  // Polje "#"
    @State private var starField: String = ""   // Polje "*"
    
    // Opcije koje se mogu odabrati (najmanje jedna, najviše sve)
    @State private var selectedOptions: Set<ConnectionOption> = []
    
    // Status poruka
    @State private var showStatusMessage = false
    @State private var statusMessage: String = ""
    @State private var statusType: StatusType = .success
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    // Samo 3 agenta: Watchman, Connection, Security (Counter Intelligence)
    private let availableAgents: [AgentType] = [.watchman, .connection, .counterintelligence]
    
    // 5 opcija za odabir
    private let connectionOptions: [ConnectionOption] = [.bluetooth, .localhost, .arp, .internet, .satellite]
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Dialog content
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Create New Tree")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Tree Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tree Name")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Enter tree name", text: $treeName)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                
                // Agent Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Agent Type")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        ForEach(availableAgents, id: \.self) { agent in
                            AgentSelectionButton(
                                agent: agent,
                                isSelected: selectedAgent == agent,
                                action: {
                                    selectedAgent = agent
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                
                // Connection Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connection Options")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ForEach(connectionOptions, id: \.self) { option in
                            ConnectionOptionButton(
                                option: option,
                                isSelected: selectedOptions.contains(option),
                                action: {
                                    toggleOption(option)
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Polje "#" (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("# (Optional)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Enter #", text: $hashField)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                
                // Polje "*" (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("* (Optional)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Enter *", text: $starField)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                
                // Description (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Enter description", text: $description, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .lineLimit(3...6)
                }
                
                // Buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    
                    Button("Create") {
                        createTree()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentOrange)
                    .frame(maxWidth: .infinity)
                    .disabled(treeName.isEmpty || selectedOptions.isEmpty)
                }
            }
            .padding(24)
            .frame(width: 550)
            .background(Color.black.opacity(0.95))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accentOrange.opacity(0.5), lineWidth: 2)
            )
            .overlay(alignment: .top) {
                if showStatusMessage {
                    StatusToastView(
                        message: statusMessage,
                        type: statusType,
                        isVisible: $showStatusMessage
                    )
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    private func toggleOption(_ option: ConnectionOption) {
        if selectedOptions.contains(option) {
            // Ne dozvoli da se deselektira ako je to posljednja opcija
            if selectedOptions.count > 1 {
                selectedOptions.remove(option)
            }
        } else {
            selectedOptions.insert(option)
        }
    }
    
    private func createTree() {
        guard !treeName.isEmpty, !selectedOptions.isEmpty else { return }
        
        // Kreiraj novo stablo s poljima "#" i "*"
        let newTree = DecisionTreeItem(
            name: treeName,
            agentType: selectedAgent,
            createdAt: Date(),
            nodeCount: 0,
            isActive: false,
            connectionOptions: selectedOptions,
            hashField: hashField.isEmpty ? nil : hashField,
            starField: starField.isEmpty ? nil : starField
        )
        
        // Spremi stablo u JSON datoteku
        do {
            let fileURL = try TreeStorageService.shared.saveTree(newTree)
            print("Tree saved successfully to: \(fileURL.path)")
            print("Selected options: \(selectedOptions.map { $0.displayName })")
            
            // Prikaži uspješnu poruku
            showStatusMessage(type: .success, message: "Tree '\(treeName)' created successfully!")
            
            // Zatvori dialog i otvori info view nakon kratke pauze
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPresented = false
                // Pozovi callback s kreiranim stablom
                onTreeCreated?(newTree)
                // Resetiraj polja
                resetFields()
            }
        } catch {
            print("Error saving tree: \(error)")
            // Prikaži error poruku
            showStatusMessage(type: .error, message: "Failed to create tree: \(error.localizedDescription)")
        }
    }
    
    private func showStatusMessage(type: StatusType, message: String) {
        statusType = type
        statusMessage = message
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showStatusMessage = true
        }
        
        // Automatski sakrij poruku nakon 3 sekunde
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showStatusMessage = false
            }
        }
    }
    
    private func resetFields() {
        treeName = ""
        selectedAgent = .watchman
        description = ""
        hashField = ""
        starField = ""
        selectedOptions = []
    }
}

// MARK: - Agent Selection Button

struct AgentSelectionButton: View {
    let agent: AgentType
    let isSelected: Bool
    let action: () -> Void
    
    /// Vraća ime ikone za agenta
    private var iconName: String {
        switch agent {
        case .watchman: return "Watchmen Amblem"
        case .connection: return "Conection Agent Amblem"
        case .counterintelligence: return "Counter Inteligence Agent"
        default: return ""
        }
    }
    
    /// Učitava custom ikonu iz Icons foldera
    private var customIcon: NSImage? {
        // Pokušaj učitati iz Shared/UX/Icons foldera
        if let imageURL = Bundle.main.url(forResource: iconName, withExtension: "png", subdirectory: "Shared/UX/Icons") {
            return NSImage(contentsOf: imageURL)
        }
        // Fallback: Pokušaj direktno iz bundle-a
        if let imageURL = Bundle.main.url(forResource: iconName, withExtension: "png") {
            return NSImage(contentsOf: imageURL)
        }
        return nil
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Okrugla custom ikona iz foldera
                if let nsImage = customIcon {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                        )
                } else {
                    // Fallback na SF Symbol ako ikona nije pronađena
                    ZStack {
                        Circle()
                            .fill(isSelected ? agent.color : Color.white.opacity(0.1))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: agent.icon)
                            .font(.system(size: 35, weight: .medium))
                            .foregroundColor(isSelected ? .white : agent.color)
                    }
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                    )
                }
                
                Text(agent.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Connection Option Button

struct ConnectionOptionButton: View {
    let option: ConnectionOption
    let isSelected: Bool
    let action: () -> Void
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    /// Vraća ime custom ikone za opciju ako postoji
    private var customIconName: String? {
        switch option {
        case .bluetooth: return "Bluetooth"
        case .satellite: return "satellite"
        default: return nil
        }
    }
    
    /// Učitava custom ikonu iz Icons foldera
    private var customIcon: NSImage? {
        guard let iconName = customIconName else { return nil }
        
        // Pokušaj učitati iz Shared/UX/Icons foldera
        if let imageURL = Bundle.main.url(forResource: iconName, withExtension: "png", subdirectory: "Shared/UX/Icons") {
            return NSImage(contentsOf: imageURL)
        }
        // Fallback: Pokušaj direktno iz bundle-a
        if let imageURL = Bundle.main.url(forResource: iconName, withExtension: "png") {
            return NSImage(contentsOf: imageURL)
        }
        return nil
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accentOrange : Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    // Custom ikona ili SF Symbol
                    if let nsImage = customIcon {
                        Image(nsImage: nsImage)
                            .renderingMode(.template) // Omogućava primjenu boje
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(isSelected ? .white : accentOrange)
                    } else {
                        Image(systemName: option.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(isSelected ? .white : accentOrange)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : accentOrange.opacity(0.5), lineWidth: isSelected ? 2 : 1)
                )
                
                Text(option.displayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? accentOrange : .white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Toast View

struct StatusToastView: View {
    let message: String
    let type: StatusType
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(type.color)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isVisible = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: type.color.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

