//
//  ExportImportView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import UniformTypeIdentifiers

/// View za export i import topologije
struct ExportImportView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject var topology: NetworkTopology
    @Binding var isPresented: Bool
    @State private var showFilePicker = false
    @State private var showFileExporter = false
    @State private var exportDocument: TopologyDocument?
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text(localization.text("topology.exportImport"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Export
            VStack(alignment: .leading, spacing: 12) {
                Text(localization.text("topology.export"))
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(localization.text("topology.exportDescription"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Button(action: {
                    do {
                        let data = try topology.exportToJSON()
                        exportDocument = TopologyDocument(data: data)
                        showFileExporter = true
                    } catch {
                        print("Export error: \(error)")
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text(localization.text("topology.exportButton"))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            // Import
            VStack(alignment: .leading, spacing: 12) {
                Text(localization.text("topology.import"))
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(localization.text("topology.importDescription"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Button(action: {
                    showFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(localization.text("topology.importButton"))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 500, height: 400)
        .background(Color.black.opacity(0.9))
        .cornerRadius(12)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importTopology(from: url)
                }
            case .failure(let error):
                print("Import error: \(error)")
            }
        }
        .fileExporter(
            isPresented: $showFileExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "topology"
        ) { result in
            switch result {
            case .success:
                isPresented = false
            case .failure(let error):
                print("Export error: \(error)")
            }
        }
    }
    
    private func importTopology(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let importedTopology = try NetworkTopology.importFromJSON(data)
            
            // Copy imported topology to current topology
            topology.components = importedTopology.components
            topology.connections = importedTopology.connections
            topology.clientA = importedTopology.clientA
            topology.clientB = importedTopology.clientB
            topology.agentAssignments = importedTopology.agentAssignments
            
            isPresented = false
        } catch {
            print("Import error: \(error)")
        }
    }
}

// MARK: - Document

struct TopologyDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}




