//
//  TreeSelectorView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za odabir stabla odluke
struct TreeSelectorView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var selectedTree: DecisionTreeItem?
    @State private var trees: [DecisionTreeItem] = []
    @State private var searchText = ""
    @State private var filterAgent: AgentType?
    
    let onSelect: (DecisionTreeItem?) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(localization.text("treeSelector.title"))
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    onSelect(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.6))
            
            // Search and filter
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))
                    
                    TextField(localization.text("treeSelector.search"), text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                // Agent filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: localization.text("treeSelector.all"),
                            isSelected: filterAgent == nil
                        ) {
                            filterAgent = nil
                        }
                        
                        ForEach([AgentType.watchman, .connection, .counterintelligence, .security], id: \.self) { agent in
                            FilterChip(
                                title: agent.rawValue.capitalized,
                                isSelected: filterAgent == agent
                            ) {
                                filterAgent = agent
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.4))
            
            // Tree list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredTrees) { tree in
                        TreeSelectorItemView(
                            tree: tree,
                            isSelected: selectedTree?.id == tree.id
                        ) {
                            selectedTree = tree
                            onSelect(tree)
                        }
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 500, height: 600)
        .background(Color.black.opacity(0.95))
        .cornerRadius(12)
        .onAppear {
            loadTrees()
        }
    }
    
    private var filteredTrees: [DecisionTreeItem] {
        var filtered = trees
        
        if let agent = filterAgent {
            filtered = filtered.filter { $0.agentType == agent }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.agentType.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    private func loadTrees() {
        // TODO: Load from actual storage
        trees = [
            DecisionTreeItem(name: "Connection Basic", agentType: .connection, createdAt: Date()),
            DecisionTreeItem(name: "Watchman Monitor", agentType: .watchman, createdAt: Date()),
            DecisionTreeItem(name: "Security Advanced", agentType: .security, createdAt: Date())
        ]
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color(red: 1.0, green: 0.36, blue: 0.0) : Color.white.opacity(0.1))
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct TreeSelectorItemView: View {
    let tree: DecisionTreeItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: iconForAgent(tree.agentType))
                    .foregroundColor(colorForAgent(tree.agentType))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tree.name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text(tree.agentType.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.0))
                }
            }
            .padding(12)
            .background(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private func iconForAgent(_ agent: AgentType) -> String {
        switch agent {
        case .watchman: return "eye"
        case .connection: return "network"
        case .counterintelligence: return "shield"
        case .security: return "lock.shield"
        }
    }
    
    private func colorForAgent(_ agent: AgentType) -> Color {
        switch agent {
        case .watchman: return .blue
        case .connection: return .green
        case .counterintelligence: return .orange
        case .security: return .red
        }
    }
}









