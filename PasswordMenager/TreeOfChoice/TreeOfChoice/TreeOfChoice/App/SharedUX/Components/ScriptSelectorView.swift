//
//  ScriptSelectorView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za odabir Python skripte
struct ScriptSelectorView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var selectedScript: NetworkScript?
    @State private var scripts: [NetworkScript] = []
    @State private var searchText = ""
    @State private var filterType: ScriptType?
    
    let onSelect: (NetworkScript?) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(localization.text("scriptSelector.title"))
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
                    
                    TextField(localization.text("scriptSelector.search"), text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                // Type filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: localization.text("scriptSelector.all"),
                            isSelected: filterType == nil
                        ) {
                            filterType = nil
                        }
                        
                        ForEach([ScriptType.network, .scenario, .training], id: \.self) { type in
                            FilterChip(
                                title: type.rawValue.capitalized,
                                isSelected: filterType == type
                            ) {
                                filterType = type
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.4))
            
            // Script list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredScripts) { script in
                        ScriptSelectorItemView(
                            script: script,
                            isSelected: selectedScript?.id == script.id
                        ) {
                            selectedScript = script
                            onSelect(script)
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
            loadScripts()
        }
    }
    
    private var filteredScripts: [NetworkScript] {
        var filtered = scripts
        
        if let type = filterType {
            filtered = filtered.filter { $0.scriptType == type }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    private func loadScripts() {
        // TODO: Load from actual storage
        scripts = [
            NetworkScript(name: "Basic Network", content: "", scriptType: .network, createdAt: Date()),
            NetworkScript(name: "Training Scenario", content: "", scriptType: .scenario, createdAt: Date())
        ]
    }
}

struct ScriptSelectorItemView: View {
    let script: NetworkScript
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: iconForType(script.scriptType))
                    .foregroundColor(colorForType(script.scriptType))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(script.name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text(script.scriptType.rawValue.capitalized)
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















