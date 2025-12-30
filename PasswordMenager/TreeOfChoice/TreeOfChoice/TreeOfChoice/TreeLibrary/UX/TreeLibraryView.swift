//
//  TreeLibraryView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// View za Tree Library - upravljanje svim binarnim stablima odluke
struct TreeLibraryView: View {
    @EnvironmentObject private var localization: LocalizationManager
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    @State private var trees: [DecisionTreeItem] = []
    @State private var selectedTree: DecisionTreeItem?
    @State private var showImportPicker = false
    @State private var showExportPicker = false
    @State private var searchText = ""
    @State private var isLoading = false
    
    // Stanja za agente i connection opcije (0 = original, 1 = zelena, 2 = crvena)
    @State private var agentStates: [UUID: [AgentType: Int]] = [:] // [treeId: [agent: state]]
    @State private var connectionStates: [UUID: [ConnectionOption: Int]] = [:] // [treeId: [option: state]]
    @State private var headerAgentStates: [AgentType: Int] = [:] // Stanja za header agente
    @State private var headerConnectionStates: [ConnectionOption: Int] = [:] // Stanja za header connection opcije
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - Tree table
        VStack(spacing: 0) {
            // Top toolbar with search and filters
            topToolbar
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Main content - Tree table
            treeTableView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 400)
            .frame(maxWidth: selectedTree != nil ? 600 : .infinity)
            
            // Right side - Tree detail view (when tree is selected)
            if let selectedTree = selectedTree {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                TreeDetailView(tree: selectedTree)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.black.opacity(0.2))
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json, .text],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $showExportPicker,
            document: TreeDocument(tree: selectedTree),
            contentType: .json,
            defaultFilename: selectedTree?.name ?? "tree"
        ) { result in
            // Export handled by FileDocument
        }
        .onAppear {
            loadTrees()
        }
        .onReceive(NotificationCenter.default.publisher(for: .treeListDidUpdate)) { _ in
            loadTrees()
        }
    }
    
    // MARK: - Subviews
    
    private var topToolbar: some View {
        HStack(spacing: 16) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(accentOrange)
                
                TextField("Search trees...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            // Import button
            Button(action: {
                showImportPicker = true
            }) {
            HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Export button (only if tree is selected)
            if selectedTree != nil {
            Button(action: {
                    showExportPicker = true
            }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
        .padding(16)
    }
    
    private var treeTableView: some View {
        // Header i redovi tablice
        VStack(alignment: .leading, spacing: 0) {
            // Header
                tableHeader
                
                Divider()
                .background(Color.white)
                .frame(height: 1)
            
            // Prvih par redova s random podacima - filtrirani na temelju header botuna
            let allRows = generateRandomRows()
            let filteredRows = filterRowsByHeaderState(allRows)
            
            ForEach(Array(filteredRows.enumerated()), id: \.element.id) { index, tree in
                        TreeTableRowView(
                            index: index + 1,
                            tree: tree,
                            isSelected: selectedTree?.id == tree.id,
                    isEvenRow: index % 2 == 1,
                            agentState: [:], // Ne koristi se - boje su fiksne ovisno o podacima
                            connectionState: [:], // Ne koristi se - boje su fiksne ovisno o podacima
                            onTap: {
                            selectedTree = tree
                            },
                            onAgentClick: { _ in
                                // Ne mijenja boje - samo header botuni mijenjaju boje
                            },
                            onConnectionClick: { _ in
                                // Ne mijenja boje - samo header botuni mijenjaju boje
                            },
                            onDelete: {
                                deleteTree(tree)
                            }
                        )
                        
                            Divider()
                    .background(Color.white)
                    .frame(height: 1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func filterRowsByHeaderState(_ rows: [DecisionTreeItem]) -> [DecisionTreeItem] {
        return rows.filter { tree in
            // Provjeri agent filtere
            var agentMatches = true
            for agent in [AgentType.watchman, .connection, .counterintelligence] {
                let headerState = headerAgentStates[agent] ?? 0
                if headerState == 1 { // Zeleno - uključi samo redove s tim agentom
                    if tree.agentType != agent {
                        agentMatches = false
                        break
                    }
                } else if headerState == 2 { // Crveno - isključi redove s tim agentom
                    if tree.agentType == agent {
                        agentMatches = false
                        break
                    }
                }
                // headerState == 0 (narančasto) - nema filtera
            }
            
            if !agentMatches { return false }
            
            // Provjeri connection filtere
            for option in [ConnectionOption.bluetooth, .localhost, .arp, .internet, .satellite] {
                let headerState = headerConnectionStates[option] ?? 0
                let hasOption = tree.connectionOptions.contains(option)
                
                if headerState == 1 { // Zeleno - uključi samo redove s tom opcijom
                    if !hasOption {
                        return false
                    }
                } else if headerState == 2 { // Crveno - isključi redove s tom opcijom
                    if hasOption {
                        return false
                    }
                }
                // headerState == 0 (narančasto) - nema filtera
            }
            
            return true
        }
    }
    
    private func generateRandomRows() -> [DecisionTreeItem] {
        let names = ["Alpha Tree", "Beta Decision", "Gamma Path", "Delta Choice", "Epsilon Route"]
        let agentTypes: [AgentType] = [.watchman, .connection, .counterintelligence]
        let allConnections: [ConnectionOption] = [.bluetooth, .localhost, .arp, .internet, .satellite]
        return names.map { name in
            // Samo jedan agent tip
            let randomAgent = agentTypes.randomElement() ?? .watchman
            
            // Za connection opcije: najčešće 1-2, ali mogu biti i svi (10% šanse za sve)
            let connectionCount: Int
            if Int.random(in: 1...10) == 1 {
                // 10% šanse za sve 5
                connectionCount = 5
            } else {
                // 90% šanse za 1-2
                connectionCount = Int.random(in: 1...2)
            }
            let randomConnections = Array(allConnections.shuffled().prefix(connectionCount))
            
            return DecisionTreeItem(
                name: name,
                agentType: randomAgent,
                createdAt: Date(),
                nodeCount: Int.random(in: 5...50),
                isActive: Bool.random(),
                connectionOptions: Set(randomConnections)
            )
        }
    }
    
    private func tableFooter(count: Int) -> some View {
        HStack(spacing: 0) {
            // Num.
            Text("Num.")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 80, alignment: .leading)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Povećalo
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 50)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Info
            Image(systemName: "info.circle")
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 50)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Name
            HStack {
                Spacer()
                Text("Name")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: 50)
                Spacer()
            }
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // 3 Agent botuni
            HStack(spacing: 12) {
                ForEach(1...3, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 40, height: 40)
                }
            }
            .frame(width: 260)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // 5 Connection botuna
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 36, height: 36)
                }
            }
            .frame(width: 310)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Polje sa brojevima redova
            HStack(spacing: 4) {
                ForEach(1...min(10, count), id: \.self) { num in
                    Text("\(num)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 24)
                }
            }
            .frame(width: 300)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Polje sa *
            Text("*")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 250)
        }
        .background(Color.black.opacity(0.3))
    }
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            // Num.
            Text("Num.")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 80)
                .multilineTextAlignment(.center)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Narančasti krug sa povećalom (klikabilni botun)
            Button(action: {
                // TODO: Search/filter action
            }) {
                ZStack {
                    Circle()
                        .fill(accentOrange)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 50)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Narančasti krug sa Info (klikabilni botun)
            Button(action: {
                // TODO: Info action
            }) {
                ZStack {
                    Circle()
                        .fill(accentOrange)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "info.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 50)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Narančasti krug sa smećem (klikabilni botun)
            Button(action: {
                // TODO: Delete action
            }) {
                ZStack {
                    Circle()
                        .fill(accentOrange)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 50)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Name
            Text("Name")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 120)
                .multilineTextAlignment(.center)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // 3 Agent botuni u headeru (klikabilni, veći)
            HStack(spacing: 12) {
                // Watchman botun
                Button(action: {
                    toggleHeaderAgentState(.watchman)
                }) {
                    ZStack {
                        Circle()
                            .fill(getHeaderAgentColor(for: .watchman))
                            .frame(width: 40, height: 40)
                        
                        if let customIcon = loadHeaderAgentIcon(.watchman) {
                            Image(nsImage: customIcon)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.white)
                } else {
                    Image(systemName: "eye")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                // Connection botun
                Button(action: {
                    toggleHeaderAgentState(.connection)
                }) {
                    ZStack {
                        Circle()
                            .fill(getHeaderAgentColor(for: .connection))
                            .frame(width: 40, height: 40)
                        
                        if let customIcon = loadHeaderAgentIcon(.connection) {
                            Image(nsImage: customIcon)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.white)
                } else {
                    Image(systemName: "network")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                // Security (Counter Intelligence) botun
                Button(action: {
                    toggleHeaderAgentState(.counterintelligence)
                }) {
                    ZStack {
                        Circle()
                            .fill(getHeaderAgentColor(for: .counterintelligence))
                            .frame(width: 40, height: 40)
                        
                        if let customIcon = loadHeaderAgentIcon(.counterintelligence) {
                            Image(nsImage: customIcon)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.white)
            } else {
                    Image(systemName: "shield")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                }
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(width: 260)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // 5 Connection botuna u headeru (klikabilni, veći)
            HStack(spacing: 8) {
                ForEach([ConnectionOption.bluetooth, .localhost, .arp, .internet, .satellite], id: \.self) { option in
                    Button(action: {
                        toggleHeaderConnectionState(option)
                    }) {
                        ZStack {
                            Circle()
                                .fill(getHeaderConnectionColor(for: option))
                                .frame(width: 36, height: 36)
                            
                            // Koristi custom ikone iz Icons foldera gdje su dostupne
                            if let customIcon = loadHeaderConnectionIcon(option) {
                                Image(nsImage: customIcon)
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white)
                            } else {
                                // Fallback na SF Symbol - uvijek prikaži ikonu
                                Image(systemName: option.icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 310)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Polje sa #
            Text("#")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 300)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Polje sa *
            Text("*")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 100)
        }
        .background(Color.black.opacity(0.3))
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
    
    private var filteredTrees: [DecisionTreeItem] {
        if searchText.isEmpty {
            return trees
        }
        return trees.filter { tree in
            tree.name.localizedCaseInsensitiveContains(searchText) ||
            tree.agentType.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func generateEmptyRows() -> [DecisionTreeItem] {
        let agentTypes: [AgentType] = [.watchman, .connection, .counterintelligence, .security, .intelligence, .analysis, .monitoring]
        return (1...10).map { index in
            DecisionTreeItem(
                name: "Tree \(index)",
                agentType: agentTypes[index % agentTypes.count],
                createdAt: Date(),
                nodeCount: 0,
                isActive: false,
                connectionOptions: []
            )
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
    
    private func loadTrees() {
        isLoading = true
        do {
            trees = try TreeStorageService.shared.loadAllTrees()
            // Ako je prethodno odabrano stablo još u listi, zadrži ga
            if let selected = selectedTree,
               !trees.contains(where: { $0.id == selected.id }) {
                selectedTree = nil
            }
        } catch {
            print("Error loading trees: \(error)")
        }
        isLoading = false
    }
    
    private func importTree(from url: URL) {
        do {
            let importedTree = try TreeStorageService.shared.loadTree(from: url)
            // Spremi u trees folder
            _ = try TreeStorageService.shared.saveTree(importedTree)
            loadTrees() // Osvježi listu
            selectedTree = importedTree
        } catch {
            print("Error importing tree: \(error)")
        }
    }
    
    private func deleteTree(_ tree: DecisionTreeItem) {
        do {
            try TreeStorageService.shared.deleteTree(tree)
            if selectedTree?.id == tree.id {
                selectedTree = nil
            }
            // Očisti stanja za obrisano stablo
            agentStates.removeValue(forKey: tree.id)
            connectionStates.removeValue(forKey: tree.id)
            loadTrees() // Osvježi listu
        } catch {
            print("Error deleting tree: \(error)")
        }
    }
    
    private func toggleAgentState(for treeId: UUID, agent: AgentType) {
        if agentStates[treeId] == nil {
            agentStates[treeId] = [:]
        }
        let currentState = agentStates[treeId]?[agent] ?? 0
        let newState = (currentState + 1) % 3 // 0 -> 1 -> 2 -> 0
        agentStates[treeId]?[agent] = newState
    }
    
    private func toggleConnectionState(for treeId: UUID, option: ConnectionOption) {
        if connectionStates[treeId] == nil {
            connectionStates[treeId] = [:]
        }
        let currentState = connectionStates[treeId]?[option] ?? 0
        let newState = (currentState + 1) % 3 // 0 -> 1 -> 2 -> 0
        connectionStates[treeId]?[option] = newState
    }
    
    private func toggleHeaderAgentState(_ agent: AgentType) {
        let currentState = headerAgentStates[agent] ?? 0
        let newState = (currentState + 1) % 3 // 0 -> 1 -> 2 -> 0
        headerAgentStates[agent] = newState
    }
    
    private func getHeaderAgentColor(for agent: AgentType) -> Color {
        let state = headerAgentStates[agent] ?? 0
        switch state {
        case 0: return accentOrange             // Default - narančasta
        case 1: return .green                   // Prvi klik - zelena
        case 2: return .red                    // Drugi klik - crvena
        default: return accentOrange
        }
    }
    
    private func toggleHeaderConnectionState(_ option: ConnectionOption) {
        let currentState = headerConnectionStates[option] ?? 0
        let newState = (currentState + 1) % 3 // 0 -> 1 -> 2 -> 0
        headerConnectionStates[option] = newState
    }
    
    private func getHeaderConnectionColor(for option: ConnectionOption) -> Color {
        let state = headerConnectionStates[option] ?? 0
        switch state {
        case 0: return accentOrange             // Default - narančasta
        case 1: return .green                   // Prvi klik - zelena
        case 2: return .red                    // Drugi klik - crvena
        default: return accentOrange
        }
    }
    
    // MARK: - Helper Methods for Header Icons
    
    private func loadHeaderAgentIcon(_ agent: AgentType) -> NSImage? {
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
    
    private func loadHeaderConnectionIcon(_ option: ConnectionOption) -> NSImage? {
        let iconName: String?
        switch option {
        case .bluetooth: iconName = "Bluetooth"
        case .satellite: iconName = "satellite"
        default: return nil
        }
        
        guard let name = iconName else { return nil }
        
        if let imageURL = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Shared/UX/Icons") {
            return NSImage(contentsOf: imageURL)
        }
        if let imageURL = Bundle.main.url(forResource: name, withExtension: "png") {
            return NSImage(contentsOf: imageURL)
        }
        return nil
    }
}

// MARK: - Tree Detail View

struct TreeDetailView: View {
    @EnvironmentObject private var localization: LocalizationManager
    let tree: DecisionTreeItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(tree.name)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Text(tree.agentType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    
                    if tree.nodeCount > 0 {
                    Text("\(tree.nodeCount) nodes")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                    }
                    
                    if !tree.connectionOptions.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(tree.connectionOptions), id: \.self) { option in
                                Image(systemName: option.icon)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                    }
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

// MARK: - TreeTableRowView

struct TreeTableRowView: View {
    let index: Int
    let tree: DecisionTreeItem
    let isSelected: Bool
    let isEvenRow: Bool
    let agentState: [AgentType: Int]
    let connectionState: [ConnectionOption: Int]
    let onTap: () -> Void
    let onAgentClick: (AgentType) -> Void
    let onConnectionClick: (ConnectionOption) -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    @State private var showZoom = false
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        HStack(spacing: 0) {
            // Redni broj
            Text("\(index)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 80)
                .multilineTextAlignment(.center)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Narančasti krug sa povećalom
            Button(action: {
                showZoom.toggle()
                onTap()
            }) {
                ZStack {
                    Circle()
                        .fill(accentOrange)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 50)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Narančasti krug sa Info
            Button(action: {
                // TODO: Show info
            }) {
                ZStack {
                    Circle()
                        .fill(accentOrange)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "info.circle")
                        .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 50)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Narančasti krug sa smećem
                Button(action: {
                showDeleteConfirmation = true
                }) {
                    ZStack {
                        Circle()
                        .fill(accentOrange)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
            .frame(width: 50)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Nazivi
            Button(action: onTap) {
                Text(tree.name)
                    .font(.subheadline)
                                .foregroundColor(.white)
                    .frame(width: 120)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)
                }
                .buttonStyle(.plain)
                
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // 3 Agent botuni - samo jedan može biti aktivan (ne mijenjaju boje klikom)
            HStack(spacing: 12) {
                ForEach([AgentType.watchman, .connection, .counterintelligence], id: \.self) { agent in
                    // Ne klikabilni - samo prikazuju podatke
                    ZStack {
                        // Ako je ovo agent tip stabla, prikaži aktivnu boju, inače siva
                        let isActive = tree.agentType == agent
                        Circle()
                            .fill(isActive ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                        
                        if let customIcon = loadAgentIcon(agent) {
                            Image(nsImage: customIcon)
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundColor(isActive ? .white : .white.opacity(0.5))
                        } else {
                            Image(systemName: agent.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isActive ? .white : .white.opacity(0.5))
                        }
                    }
                }
            }
            .frame(width: 260)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // 5 Connection botuna - prikazuje samo one koji su u connectionOptions (ne mijenjaju boje klikom)
            HStack(spacing: 8) {
                ForEach([ConnectionOption.bluetooth, .localhost, .arp, .internet, .satellite], id: \.self) { option in
                    // Ne klikabilni - samo prikazuju podatke
                    ZStack {
                        // Ako je opcija u connectionOptions stabla, prikaži aktivnu boju, inače siva
                        let isActive = tree.connectionOptions.contains(option)
                        Circle()
                            .fill(isActive ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 36, height: 36)
                        
                        if let customIcon = loadConnectionIcon(option) {
                            Image(nsImage: customIcon)
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(isActive ? .white : .white.opacity(0.5))
                        } else {
                            // Fallback na SF Symbol - uvijek prikaži ikonu
                            Image(systemName: option.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isActive ? .white : .white.opacity(0.5))
                                .frame(width: 24, height: 24)
                        }
                    }
                }
            }
            .frame(width: 310)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Polje sa #
            Text("#")
                .font(.headline)
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 300)
                .multilineTextAlignment(.center)
            
            Divider()
                .background(Color.white)
                .frame(height: 40)
            
            // Polje sa *
            Text("*")
                .font(.headline)
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 100)
                .multilineTextAlignment(.center)
        }
        .background(
            isSelected ? Color.white.opacity(0.1) :
            (isEvenRow ? Color.gray.opacity(0.2) : Color.black.opacity(0.3))
        )
        .contextMenu {
            Button(role: .destructive, action: {
                showDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Tree", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \"\(tree.name)\"? This action cannot be undone.")
        }
    }
    
    private func getAgentColor(for agent: AgentType) -> Color {
        // U redovima boja ovisi samo o tome je li agent aktivan u podacima
        // Ne mijenja se klikom - samo header botuni mijenjaju boje
        return .green // Fiksna zelena boja za aktivne agente
    }
    
    private func getConnectionColor(for option: ConnectionOption) -> Color {
        // U redovima boja ovisi samo o tome je li connection opcija aktivna u podacima
        // Ne mijenja se klikom - samo header botuni mijenjaju boje
        return .green // Fiksna zelena boja za aktivne connection opcije
    }
    
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
        return nil
    }
    
    private func loadConnectionIcon(_ option: ConnectionOption) -> NSImage? {
        let iconName: String?
        switch option {
        case .bluetooth: iconName = "Bluetooth"
        case .satellite: iconName = "satellite"
        case .localhost: iconName = nil
        case .arp: iconName = nil
        case .internet: iconName = nil
        }
        
        guard let name = iconName else { return nil }
        
        // Pokušaj učitati iz Shared/UX/Icons foldera
        if let imageURL = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Shared/UX/Icons") {
            if let image = NSImage(contentsOf: imageURL) {
                return image
            }
        }
        
        // Fallback: Pokušaj direktno iz bundle-a
        if let imageURL = Bundle.main.url(forResource: name, withExtension: "png") {
            return NSImage(contentsOf: imageURL)
        }
        
        return nil
    }
}











