//
//  PythonParserService.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Servis za parsiranje Python koda i ekstrakciju AST strukture
final class PythonParserService {
    
    static let shared = PythonParserService()
    
    private init() {}
    
    /// Parsira Python kod i vraća AST strukturu
    func parsePythonCode(_ code: String) async throws -> ASTNode {
        // Koristimo Python AST parser kroz Process
        return try await parseWithPythonAST(code: code)
    }
    
    /// Ekstraktira dependencies iz Python koda
    func extractDependencies(_ code: String) -> [String] {
        var dependencies: Set<String> = []
        
        // Regex za import statements
        let importPattern = #"^(?:from\s+(\S+)\s+)?import\s+(\S+)"#
        let regex = try? NSRegularExpression(pattern: importPattern, options: .anchorsMatchLines)
        
        let nsString = code as NSString
        let matches = regex?.matches(in: code, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches ?? [] {
            if match.numberOfRanges >= 3 {
                // from module import ...
                if match.range(at: 1).location != NSNotFound {
                    let module = nsString.substring(with: match.range(at: 1))
                    dependencies.insert(module)
                }
                // import module
                if match.range(at: 2).location != NSNotFound {
                    let module = nsString.substring(with: match.range(at: 2))
                    let moduleName = module.components(separatedBy: ".").first ?? module
                    dependencies.insert(moduleName)
                }
            }
        }
        
        return Array(dependencies).sorted()
    }
    
    /// Analizira strukturu Python koda (funkcije, klase, varijable)
    func analyzeStructure(_ code: String) -> CodeStructure {
        var functions: [FunctionInfo] = []
        var classes: [ClassInfo] = []
        var variables: [VariableInfo] = []
        
        let lines = code.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Detektiraj funkcije
            if trimmed.hasPrefix("def ") {
                let name = extractFunctionName(from: trimmed)
                functions.append(FunctionInfo(
                    name: name,
                    lineNumber: index + 1,
                    parameters: extractParameters(from: trimmed)
                ))
            }
            
            // Detektiraj klase
            if trimmed.hasPrefix("class ") {
                let name = extractClassName(from: trimmed)
                classes.append(ClassInfo(
                    name: name,
                    lineNumber: index + 1
                ))
            }
            
            // Detektiraj varijable (osnovno)
            if trimmed.contains("=") && !trimmed.hasPrefix("#") && !trimmed.hasPrefix("def ") {
                let parts = trimmed.components(separatedBy: "=")
                if parts.count == 2 {
                    let varName = parts[0].trimmingCharacters(in: .whitespaces)
                    if !varName.isEmpty && !varName.contains("(") {
                        variables.append(VariableInfo(
                            name: varName,
                            lineNumber: index + 1
                        ))
                    }
                }
            }
        }
        
        return CodeStructure(
            functions: functions,
            classes: classes,
            variables: variables,
            totalLines: lines.count
        )
    }
    
    // MARK: - Private Methods
    
    private func parseWithPythonAST(code: String) async throws -> ASTNode {
        // Kreiraj privremenu Python skriptu koja koristi ast modul
        let tempScript = """
        import ast
        import json
        import sys
        
        code = '''\(code.replacingOccurrences(of: "'", with: "\\'"))'''
        
        try:
            tree = ast.parse(code)
            result = {
                "type": "Module",
                "children": []
            }
            
            def node_to_dict(node):
                if isinstance(node, ast.FunctionDef):
                    return {
                        "type": "FunctionDef",
                        "name": node.name,
                        "lineNumber": node.lineno,
                        "children": [node_to_dict(child) for child in ast.walk(node) if child != node]
                    }
                elif isinstance(node, ast.ClassDef):
                    return {
                        "type": "ClassDef",
                        "name": node.name,
                        "lineNumber": node.lineno,
                        "children": [node_to_dict(child) for child in ast.walk(node) if child != node]
                    }
                elif isinstance(node, ast.Import):
                    return {
                        "type": "Import",
                        "children": [{"type": "alias", "name": alias.name} for alias in node.names]
                    }
                else:
                    return {"type": type(node).__name__, "children": []}
            
            for node in ast.walk(tree):
                if isinstance(node, (ast.FunctionDef, ast.ClassDef, ast.Import, ast.ImportFrom)):
                    result["children"].append(node_to_dict(node))
            
            print(json.dumps(result))
        except Exception as e:
            print(json.dumps({"error": str(e), "type": "Error"}))
        """
        
        return try await executePythonScript(tempScript)
    }
    
    private func executePythonScript(_ script: String) async throws -> ASTNode {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        let inputPipe = Pipe()
        process.standardInput = inputPipe
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
                
                let inputHandle = inputPipe.fileHandleForWriting
                if let data = script.data(using: .utf8) {
                    inputHandle.write(data)
                    inputHandle.closeFile()
                }
                
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8),
                   let jsonData = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    
                    if let error = json["error"] as? String {
                        continuation.resume(throwing: NSError(domain: "PythonParser", code: 1, userInfo: [NSLocalizedDescriptionKey: error]))
                        return
                    }
                    
                    let astNode = parseASTFromJSON(json)
                    continuation.resume(returning: astNode)
                } else {
                    // Fallback: jednostavna AST struktura
                    continuation.resume(returning: ASTNode(
                        type: "Module",
                        name: nil,
                        value: nil,
                        children: [],
                        lineNumber: nil,
                        attributes: [:]
                    ))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func parseASTFromJSON(_ json: [String: Any]) -> ASTNode {
        let type = json["type"] as? String ?? "Unknown"
        let name = json["name"] as? String
        let lineNumber = json["lineNumber"] as? Int
        let childrenJSON = json["children"] as? [[String: Any]] ?? []
        let children = childrenJSON.map { parseASTFromJSON($0) }
        
        return ASTNode(
            type: type,
            name: name,
            value: nil,
            children: children,
            lineNumber: lineNumber,
            attributes: [:]
        )
    }
    
    private func extractFunctionName(from line: String) -> String {
        let pattern = #"def\s+(\w+)\s*\("#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
           match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: line) {
                return String(line[swiftRange])
            }
        }
        return "unknown"
    }
    
    private func extractClassName(from line: String) -> String {
        let pattern = #"class\s+(\w+)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
           match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: line) {
                return String(line[swiftRange])
            }
        }
        return "unknown"
    }
    
    private func extractParameters(from line: String) -> [String] {
        guard let openParen = line.firstIndex(of: "("),
              let closeParen = line.firstIndex(of: ")") else {
            return []
        }
        
        let paramsString = String(line[line.index(after: openParen)..<closeParen])
        return paramsString
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).components(separatedBy: "=").first ?? $0 }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Supporting Types

struct CodeStructure {
    let functions: [FunctionInfo]
    let classes: [ClassInfo]
    let variables: [VariableInfo]
    let totalLines: Int
}

struct FunctionInfo {
    let name: String
    let lineNumber: Int
    let parameters: [String]
}

struct ClassInfo {
    let name: String
    let lineNumber: Int
}

struct VariableInfo {
    let name: String
    let lineNumber: Int
}
















