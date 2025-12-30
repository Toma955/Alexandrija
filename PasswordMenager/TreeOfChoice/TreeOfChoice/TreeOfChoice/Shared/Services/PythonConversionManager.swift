//
//  PythonConversionManager.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation
import Combine

/// Glavni manager koji koordinira cijeli proces konverzije Python → Swift
final class PythonConversionManager: ObservableObject {
    
    static let shared = PythonConversionManager()
    
    @Published var scripts: [PythonScript] = []
    @Published var currentScript: PythonScript?
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    private let parser = PythonParserService.shared
    private let transpiler = PythonToSwiftTranspiler.shared
    private let testGenerator = SwiftTestGenerator.shared
    
    private init() {}
    
    /// Učitava Python skriptu i započinje proces konverzije
    func loadPythonScript(from url: URL) async {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let name = url.lastPathComponent
            
            var script = PythonScript(name: name, content: content, fileURL: url)
            script.conversionStatus = .analyzing
            
            await MainActor.run {
                self.scripts.append(script)
                self.currentScript = script
                self.isProcessing = true
                self.errorMessage = nil
            }
            
            // Analiziraj strukturu
            let dependencies = parser.extractDependencies(content)
            let structure = parser.analyzeStructure(content)
            
            // Parsiraj AST
            let astNode = try await parser.parsePythonCode(content)
            
            await MainActor.run {
                if let index = self.scripts.firstIndex(where: { $0.id == script.id }) {
                    self.scripts[index].dependencies = dependencies
                    self.scripts[index].astStructure = astNode
                    self.scripts[index].conversionStatus = .converting
                }
            }
            
            // Konvertiraj u Swift
            let swiftCode = try await transpiler.transpile(content)
            
            await MainActor.run {
                if let index = self.scripts.firstIndex(where: { $0.id == script.id }) {
                    self.scripts[index].convertedSwiftCode = swiftCode
                    self.scripts[index].conversionStatus = .testing
                }
            }
            
            // Generiraj testove
            let tests = testGenerator.generateTests(for: script, swiftCode: swiftCode)
            
            await MainActor.run {
                if let index = self.scripts.firstIndex(where: { $0.id == script.id }) {
                    self.scripts[index].tests = tests
                    self.scripts[index].conversionStatus = .success
                    self.isProcessing = false
                    self.currentScript = self.scripts[index]
                }
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
                if let index = self.scripts.firstIndex(where: { $0.id == self.currentScript?.id }) {
                    self.scripts[index].conversionStatus = .failed
                }
            }
        }
    }
    
    /// Učitava Python kod direktno iz stringa
    func loadPythonCode(_ code: String, name: String = "Untitled.py") async {
        var script = PythonScript(name: name, content: code)
        script.conversionStatus = .analyzing
        
        await MainActor.run {
            self.scripts.append(script)
            self.currentScript = script
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        do {
            // Analiziraj strukturu
            let dependencies = parser.extractDependencies(code)
            let astNode = try await parser.parsePythonCode(code)
            
            await MainActor.run {
                if let index = self.scripts.firstIndex(where: { $0.id == script.id }) {
                    self.scripts[index].dependencies = dependencies
                    self.scripts[index].astStructure = astNode
                    self.scripts[index].conversionStatus = .converting
                }
            }
            
            // Konvertiraj u Swift
            let swiftCode = try await transpiler.transpile(code)
            
            await MainActor.run {
                if let index = self.scripts.firstIndex(where: { $0.id == script.id }) {
                    self.scripts[index].convertedSwiftCode = swiftCode
                    self.scripts[index].conversionStatus = .testing
                }
            }
            
            // Generiraj testove
            let tests = testGenerator.generateTests(for: script, swiftCode: swiftCode)
            
            await MainActor.run {
                if let index = self.scripts.firstIndex(where: { $0.id == script.id }) {
                    self.scripts[index].tests = tests
                    self.scripts[index].conversionStatus = .success
                    self.isProcessing = false
                    self.currentScript = self.scripts[index]
                }
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
                if let index = self.scripts.firstIndex(where: { $0.id == script.id }) {
                    self.scripts[index].conversionStatus = .failed
                }
            }
        }
    }
    
    /// Briše skriptu
    func removeScript(_ script: PythonScript) {
        scripts.removeAll { $0.id == script.id }
        if currentScript?.id == script.id {
            currentScript = scripts.first
        }
    }
}
















