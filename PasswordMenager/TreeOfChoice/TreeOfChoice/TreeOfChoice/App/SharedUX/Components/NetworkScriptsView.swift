//
//  NetworkScriptsView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import UniformTypeIdentifiers

/// View za upravljanje mrežnim Python skriptama
struct NetworkScriptsView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @State private var scripts: [NetworkScript] = []
    @State private var showImportPicker = false
    @State private var showExportPicker = false
    @State private var selectedScript: NetworkScript?
    @State private var showScriptEditor = false
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView
            
            // Content
            if scripts.isEmpty {
                emptyStateView
            } else {
                scriptListView
            }
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.text, UTType(filenameExtension: "py") ?? .text],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .sheet(isPresented: $showScriptEditor) {
            if let script = selectedScript {
                ScriptEditorView(script: script)
                    .environmentObject(localization)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var toolbarView: some View {
        HStack(spacing: 12) {
            Button(action: {
                showImportPicker = true
            }) {
                Label(localization.text("scripts.import"), systemImage: "square.and.arrow.down")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentOrange)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .focusable(false)
            
            Button(action: {
                if let script = selectedScript {
                    exportScript(script)
                }
            }) {
                Label(localization.text("scripts.export"), systemImage: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentOrange)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .disabled(selectedScript == nil)
            .opacity(selectedScript == nil ? 0.5 : 1.0)
            
            Button(action: {
                createNewScript()
            }) {
                Label(localization.text("scripts.create"), systemImage: "plus")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentOrange)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .focusable(false)
            
            Spacer()
            
            Text("\(scripts.count) \(localization.text("scripts.count"))")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
            
            Text(localization.text("scripts.empty"))
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Text(localization.text("scripts.emptyDescription"))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                showImportPicker = true
            }) {
                Text(localization.text("scripts.importFirst"))
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accentOrange)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .focusable(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var scriptListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(scripts) { script in
                    ScriptCardView(
                        script: script,
                        isSelected: selectedScript?.id == script.id
                    ) {
                        selectedScript = script
                        showScriptEditor = true
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
                importScript(from: url)
            }
        case .failure(let error):
            print("Import error: \(error)")
        }
    }
    
    private func importScript(from url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let newScript = NetworkScript(
                name: url.lastPathComponent,
                content: content,
                scriptType: .network,
                createdAt: Date()
            )
            scripts.append(newScript)
            selectedScript = newScript
        } catch {
            print("Failed to import script: \(error)")
        }
    }
    
    private func createNewScript() {
        let newScript = NetworkScript(
            name: localization.text("scripts.newScript"),
            content: "# New network script\n",
            scriptType: .network,
            createdAt: Date()
        )
        scripts.append(newScript)
        selectedScript = newScript
        showScriptEditor = true
    }
    
    private func exportScript(_ script: NetworkScript) {
        // TODO: Implement export logic
        print("Exporting: \(script.name)")
    }
}

// MARK: - Script Card

struct ScriptCardView: View {
    let script: NetworkScript
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: iconForType(script.scriptType))
                    .font(.title2)
                    .foregroundColor(colorForType(script.scriptType))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(script.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(script.scriptType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(script.content.components(separatedBy: .newlines).count) lines")
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
    
    private func iconForType(_ type: ScriptType) -> String {
        switch type {
        case .network: return "network"
        case .scenario: return "list.bullet.rectangle"
        case .training: return "brain"
        }
    }
    
    private func colorForType(_ type: ScriptType) -> Color {
        switch type {
        case .network: return .blue
        case .scenario: return .purple
        case .training: return .orange
        }
    }
}

// MARK: - Models

struct NetworkScript: Identifiable {
    let id = UUID()
    let name: String
    var content: String
    let scriptType: ScriptType
    let createdAt: Date
}

enum ScriptType: String, Codable {
    case network = "network"
    case scenario = "scenario"
    case training = "training"
}

// MARK: - Script Editor

struct ScriptEditorView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    let script: NetworkScript
    @State private var editedContent: String
    
    init(script: NetworkScript) {
        self.script = script
        _editedContent = State(initialValue: script.content)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(script.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.0))
            }
            .padding(16)
            .background(Color.black.opacity(0.6))
            
            // Editor
            TextEditor(text: $editedContent)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color.black.opacity(0.3))
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.black.opacity(0.8))
    }
}







