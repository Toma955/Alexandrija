//
//  TreeCreatorView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import UniformTypeIdentifiers

/// View za Tree Creator mod - kreiranje i uređivanje binarnih stabala odluke
struct TreeCreatorView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @State private var showCreateTreeDialog = false
    @State private var showTreeInfoView = false
    @State private var createdTree: DecisionTreeItem?
    @State private var showOpenTreePicker = false
    @State private var showTreeList = false
    @State private var trees: [DecisionTreeItem] = []
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
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
        .fileImporter(
            isPresented: $showOpenTreePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleOpenTree(result)
        }
        .overlay {
            if showCreateTreeDialog {
                CreateTreeDialog(
                    isPresented: $showCreateTreeDialog,
                    onTreeCreated: { tree in
                        createdTree = tree
                        showTreeInfoView = true
                    }
                )
                .environmentObject(localization)
            }
            
            if showTreeList {
                TreeListOverlay(
                    isPresented: $showTreeList,
                    trees: trees,
                    onTreeSelected: { tree in
                        createdTree = tree
                        showTreeInfoView = true
                        showTreeList = false
                    }
                )
                .environmentObject(localization)
            }
            
            if showTreeInfoView, let tree = createdTree {
                TreeInfoView(isPresented: $showTreeInfoView, tree: tree)
                    .environmentObject(localization)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                    .zIndex(100)
            }
        }
        .onAppear {
            loadTrees()
        }
        .onReceive(NotificationCenter.default.publisher(for: .treeListDidUpdate)) { _ in
            loadTrees()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.text("treeCreator.title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(localization.text("treeCreator.homeDescription"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(24)
        .background(Color.black.opacity(0.6))
    }
    
    private var mainContentView: some View {
        ZStack {
            // Plus i Open botuni u centru
            HStack(spacing: 40) {
                // Open botun
                Button(action: {
                    if trees.isEmpty {
                        showOpenTreePicker = true
                    } else {
                        showTreeList = true
                    }
                }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(accentOrange)
                                .frame(width: 120, height: 120)
                                .shadow(color: accentOrange.opacity(0.5), radius: 20, x: 0, y: 0)
                            
                            Image(systemName: "folder.fill")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Open")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                // Plus botun
                Button(action: {
                    showCreateTreeDialog = true
                }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(accentOrange)
                                .frame(width: 120, height: 120)
                                .shadow(color: accentOrange.opacity(0.5), radius: 20, x: 0, y: 0)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Create")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .scaleEffect(showCreateTreeDialog ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showCreateTreeDialog)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func loadTrees() {
        do {
            trees = try TreeStorageService.shared.loadAllTrees()
        print("Loaded \(trees.count) trees")
        } catch {
            print("Error loading trees: \(error)")
        }
    }
    
    private func handleOpenTree(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                do {
                    let tree = try TreeStorageService.shared.loadTree(from: url)
                    createdTree = tree
                    showTreeInfoView = true
                } catch {
                    print("Error loading tree: \(error)")
                }
            }
        case .failure(let error):
            print("Error opening tree: \(error)")
        }
    }
}

// MARK: - Tree List Overlay

struct TreeListOverlay: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isPresented: Bool
    let trees: [DecisionTreeItem]
    let onTreeSelected: (DecisionTreeItem) -> Void
    
    @State private var searchText = ""
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var filteredTrees: [DecisionTreeItem] {
        if searchText.isEmpty {
            return trees
        }
        return trees.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // List panel
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open Tree")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("Select a tree to open")
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
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))
                    
                    TextField("Search trees...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Tree list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if filteredTrees.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tree")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text(searchText.isEmpty ? "No trees found" : "No trees match your search")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            ForEach(filteredTrees) { tree in
                                TreeListItemView(tree: tree) {
                                    onTreeSelected(tree)
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .frame(width: 500, height: 600)
            .background(Color.black.opacity(0.95))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accentOrange.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: accentOrange.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
}

// MARK: - Tree List Item View

struct TreeListItemView: View {
    let tree: DecisionTreeItem
    let onTap: () -> Void
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Agent icon
                ZStack {
                    Circle()
                        .fill(tree.agentType.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: tree.agentType.icon)
                        .font(.title3)
                        .foregroundColor(tree.agentType.color)
                }
                
                // Tree info
                VStack(alignment: .leading, spacing: 4) {
                    Text(tree.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Text(tree.agentType.displayName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        if tree.nodeCount > 0 {
                            Text("• \(tree.nodeCount) nodes")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Text(tree.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accentOrange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

