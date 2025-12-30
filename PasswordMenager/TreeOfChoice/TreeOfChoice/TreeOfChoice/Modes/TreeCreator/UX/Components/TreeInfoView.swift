//
//  TreeInfoView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit

/// View za prikaz informacija o kreiranom stablu
struct TreeInfoView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isPresented: Bool
    let tree: DecisionTreeItem
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Info panel
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Basic Info
                        basicInfoSection
                        
                        // Agent Info
                        agentInfoSection
                        
                        // Connection Options
                        connectionOptionsSection
                        
                        // Optional Fields
                        if tree.hashField != nil || tree.starField != nil {
                            optionalFieldsSection
                        }
                        
                        // Metadata
                        metadataSection
                    }
                    .padding(24)
                }
            }
            .frame(width: 600, height: 700)
            .background(Color.black.opacity(0.95))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accentOrange.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: accentOrange.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tree Created Successfully")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("Tree information")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
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
        .padding(24)
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(accentOrange)
            
            InfoRow(label: "Name", value: tree.name)
            InfoRow(label: "Created", value: tree.createdAt.formatted(date: .abbreviated, time: .shortened))
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var agentInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Agent Type")
                .font(.headline)
                .foregroundColor(accentOrange)
            
            HStack(spacing: 12) {
                // Agent icon
                if let nsImage = loadAgentIcon(tree.agentType) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(tree.agentType.color.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: tree.agentType.icon)
                            .font(.title3)
                            .foregroundColor(tree.agentType.color)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tree.agentType.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(tree.agentType.rawValue)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var connectionOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Options")
                .font(.headline)
                .foregroundColor(accentOrange)
            
            if tree.connectionOptions.isEmpty {
                Text("No connection options selected")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(tree.connectionOptions), id: \.self) { option in
                        ConnectionOptionChip(option: option)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var optionalFieldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Fields")
                .font(.headline)
                .foregroundColor(accentOrange)
            
            if let hashField = tree.hashField, !hashField.isEmpty {
                InfoRow(label: "#", value: hashField)
            }
            
            if let starField = tree.starField, !starField.isEmpty {
                InfoRow(label: "*", value: starField)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadata")
                .font(.headline)
                .foregroundColor(accentOrange)
            
            InfoRow(label: "Node Count", value: "\(tree.nodeCount)")
            InfoRow(label: "Status", value: tree.isActive ? "Active" : "Inactive")
            InfoRow(label: "Tree ID", value: tree.id.uuidString)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func loadAgentIcon(_ agent: AgentType) -> NSImage? {
        let iconName: String
        switch agent {
        case .watchman: iconName = "Watchmen Amblem"
        case .connection: iconName = "Conection Agent Amblem"
        case .counterintelligence: iconName = "Counter Inteligence Agent"
        default: return nil
        }
        
        if let imageURL = Bundle.main.url(forResource: iconName, withExtension: "png", subdirectory: "Shared/UX/Icons") {
            return NSImage(contentsOf: imageURL)
        }
        if let imageURL = Bundle.main.url(forResource: iconName, withExtension: "png") {
            return NSImage(contentsOf: imageURL)
        }
        return nil
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ConnectionOptionChip: View {
    let option: ConnectionOption
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    private var customIcon: NSImage? {
        let iconName: String?
        switch option {
        case .bluetooth: iconName = "Bluetooth"
        case .satellite: iconName = "satellite"
        default: iconName = nil
        }
        
        guard let iconName = iconName else { return nil }
        
        if let imageURL = Bundle.main.url(forResource: iconName, withExtension: "png", subdirectory: "Shared/UX/Icons") {
            return NSImage(contentsOf: imageURL)
        }
        if let imageURL = Bundle.main.url(forResource: iconName, withExtension: "png") {
            return NSImage(contentsOf: imageURL)
        }
        return nil
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let nsImage = customIcon {
                Image(nsImage: nsImage)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(accentOrange)
            } else {
                Image(systemName: option.icon)
                    .font(.caption)
                    .foregroundColor(accentOrange)
            }
            
            Text(option.displayName)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accentOrange.opacity(0.3), lineWidth: 1)
        )
    }
}


