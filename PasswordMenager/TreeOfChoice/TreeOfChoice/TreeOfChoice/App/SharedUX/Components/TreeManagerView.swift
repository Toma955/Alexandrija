//
//  TreeManagerView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import UniformTypeIdentifiers

/// View za upravljanje binarnim stablima odluke (import/export)
struct TreeManagerView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @State private var trees: [DecisionTreeItem] = []
    @State private var showImportPicker = false
    @State private var showExportPicker = false
    @State private var selectedTree: DecisionTreeItem?
    @State private var showTreeEditor = false
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView
            
            // Content
            if trees.isEmpty {
                emptyStateView
            } else {
                treeListView
            }
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json, .text],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        // FileExporter will be implemented when needed
    }
    
    // MARK: - Subviews
    
    private var toolbarView: some View {
        HStack(spacing: 12) {
            Button(action: {
                showImportPicker = true
            }) {
                Label(localization.text("trees.import"), systemImage: "square.and.arrow.down")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentOrange)
                    .cornerRadius(8)
            }
            
            Button(action: {
                if let tree = selectedTree {
                    showExportPicker = true
                }
            }) {
                Label(localization.text("trees.export"), systemImage: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentOrange)
                    .cornerRadius(8)
            }
            .disabled(selectedTree == nil)
            .opacity(selectedTree == nil ? 0.5 : 1.0)
            
            Button(action: {
                createNewTree()
            }) {
                Label(localization.text("trees.create"), systemImage: "plus")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentOrange)
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Text("\(trees.count) \(localization.text("trees.count"))")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tree")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
            
            Text(localization.text("trees.empty"))
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Text(localization.text("trees.emptyDescription"))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                showImportPicker = true
            }) {
                Text(localization.text("trees.importFirst"))
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accentOrange)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var treeListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(trees) { tree in
                    TreeCardView(
                        tree: tree,
                        isSelected: selectedTree?.id == tree.id
                    ) {
                        selectedTree = tree
                    }
                }
            }
            .padding(16)
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
    
    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Exported to: \(url)")
        case .failure(let error):
            print("Export error: \(error)")
        }
    }
    
    private func importTree(from url: URL) {
        // TODO: Implement actual import logic
        let newTree = DecisionTreeItem(
            name: url.lastPathComponent,
            agentType: .connection,
            createdAt: Date()
        )
        trees.append(newTree)
    }
    
    private func createNewTree() {
        let newTree = DecisionTreeItem(
            name: localization.text("trees.newTree"),
            agentType: .connection,
            createdAt: Date()
        )
        trees.append(newTree)
        selectedTree = newTree
        showTreeEditor = true
    }
}

// MARK: - Tree Card

struct TreeCardView: View {
    let tree: DecisionTreeItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: iconForAgent(tree.agentType))
                    .font(.title2)
                    .foregroundColor(colorForAgent(tree.agentType))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tree.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(tree.agentType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(tree.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.0))
                }
            }
            .padding(16)
            .background(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(red: 1.0, green: 0.36, blue: 0.0) : Color.clear, lineWidth: 2)
            )
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

// MARK: - Models

struct DecisionTreeItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let agentType: AgentType
    let createdAt: Date
    var nodeCount: Int = 0
    var isActive: Bool = false
    
    init(name: String, agentType: AgentType, createdAt: Date, nodeCount: Int = 0, isActive: Bool = false) {
        self.id = UUID()
        self.name = name
        self.agentType = agentType
        self.createdAt = createdAt
        self.nodeCount = nodeCount
        self.isActive = isActive
    }
}

enum AgentType: String, Codable {
    case watchman = "watchman"
    case connection = "connection"
    case counterintelligence = "counterintelligence"
    case security = "security"
    
    var displayName: String {
        switch self {
        case .watchman: return "Watchman"
        case .connection: return "Connection"
        case .counterintelligence: return "Counterintelligence"
        case .security: return "Security"
        }
    }
    
    var icon: String {
        switch self {
        case .watchman: return "eye"
        case .connection: return "network"
        case .counterintelligence: return "shield"
        case .security: return "lock.shield"
        }
    }
    
    var color: Color {
        switch self {
        case .watchman: return .blue
        case .connection: return .green
        case .counterintelligence: return .orange
        case .security: return .red
        }
    }
}

// MARK: - Document for Export

struct TreeDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var tree: DecisionTreeItem?
    
    init(tree: DecisionTreeItem?) {
        self.tree = tree
    }
    
    init(configuration: ReadConfiguration) throws {
        // Not needed for export
        tree = nil
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(tree)
        return FileWrapper(regularFileWithContents: data)
    }
}

