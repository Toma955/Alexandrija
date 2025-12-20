//
//  PythonScriptView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import UniformTypeIdentifiers

/// Glavni view za prikaz i konverziju Python skripti
struct PythonScriptView: View {
    @StateObject private var conversionManager = PythonConversionManager.shared
    @EnvironmentObject private var localization: LocalizationManager
    @State private var selectedTab: TabSelection = .python
    @State private var showFilePicker = false
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    enum TabSelection {
        case python
        case swift
        case ast
        case dependencies
        case tests
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header s kontrolama
            headerView
            
            // Glavni content
            if let script = conversionManager.currentScript {
                contentView(for: script)
            } else {
                emptyStateView
            }
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.text, UTType(filenameExtension: "py") ?? .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text(localization.text("python.converter.title"))
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                showFilePicker = true
            }) {
                Label(localization.text("python.load"), systemImage: "doc.badge.plus")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accentOrange)
                    .cornerRadius(8)
            }
            
            if conversionManager.isProcessing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
                    .padding(.leading, 8)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.6))
    }
    
    @ViewBuilder
    private func contentView(for script: PythonScript) -> some View {
        VStack(spacing: 0) {
            // Tab selector
            tabSelector
            
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .python:
                    CodeEditorView(code: script.content, language: .python)
                case .swift:
                    if let swiftCode = script.convertedSwiftCode {
                        CodeEditorView(code: swiftCode, language: .swift)
                    } else {
                        Text(localization.text("python.swiftNotGenerated"))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                case .ast:
                    ASTVisualizationView(astNode: script.astStructure, localization: localization)
                case .dependencies:
                    DependencyListView(dependencies: script.dependencies, localization: localization)
                case .tests:
                    TestListView(tests: script.tests ?? [], localization: localization)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            PythonTabButton(title: localization.text("python.tab.python"), isSelected: selectedTab == .python) {
                selectedTab = .python
            }
            PythonTabButton(title: localization.text("python.tab.swift"), isSelected: selectedTab == .swift) {
                selectedTab = .swift
            }
            PythonTabButton(title: localization.text("python.tab.ast"), isSelected: selectedTab == .ast) {
                selectedTab = .ast
            }
            PythonTabButton(title: localization.text("python.tab.dependencies"), isSelected: selectedTab == .dependencies) {
                selectedTab = .dependencies
            }
            PythonTabButton(title: localization.text("python.tab.tests"), isSelected: selectedTab == .tests) {
                selectedTab = .tests
            }
        }
        .background(Color.black.opacity(0.4))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
            
            Text(localization.text("python.empty"))
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Button(action: {
                showFilePicker = true
            }) {
                Text(localization.text("python.loadScript"))
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
    
    // MARK: - Actions
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                Task {
                    await conversionManager.loadPythonScript(from: url)
                }
            }
        case .failure(let error):
            conversionManager.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Supporting Views

struct PythonTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

struct CodeEditorView: View {
    let code: String
    let language: CodeLanguage
    
    enum CodeLanguage {
        case python
        case swift
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(code.components(separatedBy: .newlines).enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 40, alignment: .trailing)
                        
                        Text(line.isEmpty ? " " : line)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.3))
    }
}

struct DependencyListView: View {
    let dependencies: [String]
    let localization: LocalizationManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if dependencies.isEmpty {
                    Text(localization.text("python.noDependencies"))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(dependencies, id: \.self) { dependency in
                        HStack {
                            Image(systemName: "cube.box")
                                .foregroundColor(.orange)
                            Text(dependency)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(16)
        }
    }
}

struct TestListView: View {
    let tests: [SwiftTest]
    let localization: LocalizationManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if tests.isEmpty {
                    Text(localization.text("python.noTests"))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(tests) { test in
                        TestCardView(test: test)
                    }
                }
            }
            .padding(16)
        }
    }
}

struct TestCardView: View {
    let test: SwiftTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(test.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(test.testType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(4)
            }
            
            CodeEditorView(code: test.code, language: .swift)
                .frame(height: 200)
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

