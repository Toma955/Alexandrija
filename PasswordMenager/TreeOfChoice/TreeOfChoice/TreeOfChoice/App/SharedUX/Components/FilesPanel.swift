// App/SharedUX/Components/FilesPanel.swift
import SwiftUI

struct FilesPanel: View {
    @EnvironmentObject private var localization: LocalizationManager
    @State private var selectedTab: FilesTab = .trees
    @State private var showPythonConverter = false
    
    enum FilesTab {
        case trees
        case scripts
        case simulation
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
            
            // Tab selector
            tabSelector
            
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .trees:
                    TreeManagerView()
                case .scripts:
                    NetworkScriptsView()
                case .simulation:
                    SimulationPlaygroundView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.clear, lineWidth: 0)
        )
        .sheet(isPresented: $showPythonConverter) {
            PythonScriptView()
                .environmentObject(localization)
                .frame(minWidth: 1000, minHeight: 700)
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text(localization.text("files.title"))
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                showPythonConverter = true
            }) {
                Label(localization.text("files.pythonConverter"), systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 1.0, green: 0.36, blue: 0.0))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .focusable(false)
        }
        .padding(20)
        .background(Color.black.opacity(0.6))
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(
                title: localization.text("files.tab.trees"),
                icon: "tree",
                isSelected: selectedTab == .trees
            ) {
                selectedTab = .trees
            }
            
            TabButton(
                title: localization.text("files.tab.scripts"),
                icon: "doc.text",
                isSelected: selectedTab == .scripts
            ) {
                selectedTab = .scripts
            }
            
            TabButton(
                title: localization.text("files.tab.simulation"),
                icon: "play.circle",
                isSelected: selectedTab == .simulation
            ) {
                selectedTab = .simulation
            }
        }
        .background(Color.black.opacity(0.4))
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}







