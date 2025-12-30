//
//  TreeLibraryView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Tree Library - upravljanje svim binarnim stablima odluke
struct TreeLibraryView: View {
    @EnvironmentObject private var localization: LocalizationManager
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    @State private var trees: [TreeLibraryItem] = []
    @State private var selectedTree: TreeLibraryItem?
    @State private var showImportPicker = false
    @State private var searchText = ""
    
    var body: some View {
        HStack(spacing: 0) {
            // Left sidebar - Tree list
            leftSidebar
                .frame(width: 300)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Main content - Tree details/editor
            mainContent
                .frame(maxWidth: .infinity)
        }
        .background(Color.black.opacity(0.2))
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json, .text],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }
    
    // MARK: - Subviews
    
    private var leftSidebar: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(localization.text("treeLibrary.title"))
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showImportPicker = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.4))
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField(localization.text("treeLibrary.search"), text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .padding(16)
            
            // Tree list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredTrees) { tree in
                        TreeLibraryItemView(
                            tree: tree,
                            isSelected: selectedTree?.id == tree.id
                        ) {
                            selectedTree = tree
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.black.opacity(0.4))
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            if let tree = selectedTree {
                TreeDetailView(tree: tree)
                    .environmentObject(localization)
            } else {
                emptyStateView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tree")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.3))
            
            Text(localization.text("treeLibrary.selectTree"))
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var filteredTrees: [TreeLibraryItem] {
        if searchText.isEmpty {
            return trees
        }
        return trees.filter { tree in
            tree.name.localizedCaseInsensitiveContains(searchText) ||
            tree.agentType.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Actions
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                importTree(from: url)
            }
        case .failure(let error):
            print("Import error: \(error)")
        }
    }
    
    private func importTree(from url: URL) {
        // TODO: Implement actual import logic
        let newTree = TreeLibraryItem(
            name: url.lastPathComponent,
            agentType: .connection,
            createdAt: Date()
        )
        trees.append(newTree)
        selectedTree = newTree
    }
}

// MARK: - Tree Library Item

struct TreeLibraryItem: Identifiable {
    let id = UUID()
    let name: String
    let agentType: AgentType
    let createdAt: Date
    var nodeCount: Int = 0
}

struct TreeLibraryItemView: View {
    let tree: TreeLibraryItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: iconForAgent(tree.agentType))
                    .foregroundColor(colorForAgent(tree.agentType))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tree.name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text(tree.agentType.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
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
        case .intelligence: return "brain"
        case .analysis: return "chart.bar"
        case .monitoring: return "chart.line.uptrend.xyaxis"
        }
    }
    
    private func colorForAgent(_ agent: AgentType) -> Color {
        switch agent {
        case .watchman: return .blue
        case .connection: return .green
        case .counterintelligence: return .orange
        case .security: return .red
        case .intelligence: return .purple
        case .analysis: return .cyan
        case .monitoring: return .yellow
        }
    }
}

// MARK: - Tree Detail View

struct TreeDetailView: View {
    @EnvironmentObject private var localization: LocalizationManager
    let tree: TreeLibraryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(tree.name)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                HStack {
                    Text(tree.agentType.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("\(tree.nodeCount) nodes")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(24)
            .background(Color.black.opacity(0.4))
            
            // Tree visualization/editor
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(localization.text("treeLibrary.treeStructure"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // TODO: Add tree visualization/editor
                    Text(localization.text("treeLibrary.treeEditorPlaceholder"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(40)
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}















