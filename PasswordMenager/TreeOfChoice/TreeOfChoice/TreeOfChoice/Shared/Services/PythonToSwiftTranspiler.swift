//
//  PythonToSwiftTranspiler.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Transpiler koji konvertira Python kod u Swift kod
final class PythonToSwiftTranspiler {
    
    static let shared = PythonToSwiftTranspiler()
    
    private init() {}
    
    /// Konvertira Python kod u Swift
    func transpile(_ pythonCode: String) async throws -> String {
        var swiftCode = """
        // Auto-generated Swift code from Python
        // Generated on \(Date())
        
        import Foundation
        
        """
        
        let lines = pythonCode.components(separatedBy: .newlines)
        var indentLevel = 0
        var inFunction = false
        var inClass = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Preskoči prazne linije i komentare
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                swiftCode += line + "\n"
                continue
            }
            
            // Konvertiraj import statements
            if trimmed.hasPrefix("import ") || trimmed.hasPrefix("from ") {
                swiftCode += convertImport(trimmed) + "\n"
                continue
            }
            
            // Konvertiraj funkcije
            if trimmed.hasPrefix("def ") {
                let swiftFunc = convertFunction(trimmed)
                swiftCode += swiftFunc + "\n"
                inFunction = true
                indentLevel += 1
                continue
            }
            
            // Konvertiraj klase
            if trimmed.hasPrefix("class ") {
                let swiftClass = convertClass(trimmed)
                swiftCode += swiftClass + "\n"
                inClass = true
                indentLevel += 1
                continue
            }
            
            // Konvertiraj if statements
            if trimmed.hasPrefix("if ") {
                let swiftIf = convertIfStatement(trimmed)
                swiftCode += swiftIf + "\n"
                indentLevel += 1
                continue
            }
            
            // Konvertiraj for loops
            if trimmed.hasPrefix("for ") {
                let swiftFor = convertForLoop(trimmed)
                swiftCode += swiftFor + "\n"
                indentLevel += 1
                continue
            }
            
            // Konvertiraj while loops
            if trimmed.hasPrefix("while ") {
                let swiftWhile = convertWhileLoop(trimmed)
                swiftCode += swiftWhile + "\n"
                indentLevel += 1
                continue
            }
            
            // Konvertiraj return statements
            if trimmed.hasPrefix("return ") {
                let swiftReturn = convertReturn(trimmed)
                swiftCode += swiftReturn + "\n"
                continue
            }
            
            // Konvertiraj varijable i dodjeljivanja
            if trimmed.contains("=") {
                let swiftAssignment = convertAssignment(trimmed)
                swiftCode += swiftAssignment + "\n"
                continue
            }
            
            // Konvertiraj print statements
            if trimmed.hasPrefix("print(") {
                let swiftPrint = convertPrint(trimmed)
                swiftCode += swiftPrint + "\n"
                continue
            }
            
            // Detektiraj smanjenje indentacije
            let currentIndent = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            if currentIndent < indentLevel * 4 && (trimmed.hasSuffix(":") || !trimmed.isEmpty) {
                indentLevel = max(0, currentIndent / 4)
            }
            
            // Default: dodaj liniju s konverzijom indentacije
            let indent = String(repeating: "    ", count: indentLevel)
            swiftCode += indent + convertExpression(trimmed) + "\n"
        }
        
        return swiftCode
    }
    
    // MARK: - Conversion Methods
    
    private func convertImport(_ line: String) -> String {
        if line.hasPrefix("import ") {
            let module = String(line.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            // Swift nema direktan ekvivalent, možemo koristiti Foundation ili kreirati wrapper
            return "// import \(module) - requires manual Swift equivalent"
        } else if line.hasPrefix("from ") {
            let parts = line.dropFirst(5).components(separatedBy: " import ")
            if parts.count == 2 {
                return "// from \(parts[0]) import \(parts[1]) - requires manual Swift equivalent"
            }
        }
        return "// \(line)"
    }
    
    private func convertFunction(_ line: String) -> String {
        let pattern = #"def\s+(\w+)\s*\((.*?)\)\s*:?\s*->\s*(\w+)?"#
        var funcName = "function"
        var params = ""
        var returnType = ""
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
            if match.numberOfRanges > 1 {
                let nameRange = match.range(at: 1)
                if let swiftRange = Range(nameRange, in: line) {
                    funcName = String(line[swiftRange])
                }
            }
            if match.numberOfRanges > 2 {
                let paramsRange = match.range(at: 2)
                if let swiftRange = Range(paramsRange, in: line) {
                    params = String(line[swiftRange])
                }
            }
            if match.numberOfRanges > 3 {
                let returnRange = match.range(at: 3)
                if let swiftRange = Range(returnRange, in: line) {
                    returnType = String(line[swiftRange])
                }
            }
        }
        
        let swiftParams = convertParameters(params)
        let swiftReturn = returnType.isEmpty ? "" : " -> \(mapPythonTypeToSwift(returnType))"
        
        return "func \(funcName)(\(swiftParams))\(swiftReturn) {"
    }
    
    private func convertClass(_ line: String) -> String {
        let pattern = #"class\s+(\w+)(?:\(.*?\))?\s*:"#
        var className = "Class"
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
           match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: line) {
                className = String(line[swiftRange])
            }
        }
        
        return "class \(className) {"
    }
    
    private func convertIfStatement(_ line: String) -> String {
        let condition = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        let swiftCondition = convertExpression(condition.replacingOccurrences(of: ":", with: ""))
        return "if \(swiftCondition) {"
    }
    
    private func convertForLoop(_ line: String) -> String {
        let pattern = #"for\s+(\w+)\s+in\s+(.+?)\s*:"#
        var varName = "item"
        var iterable = "[]"
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
            if match.numberOfRanges > 1 {
                let varRange = match.range(at: 1)
                if let swiftRange = Range(varRange, in: line) {
                    varName = String(line[swiftRange])
                }
            }
            if match.numberOfRanges > 2 {
                let iterRange = match.range(at: 2)
                if let swiftRange = Range(iterRange, in: line) {
                    iterable = String(line[swiftRange])
                }
            }
        }
        
        let swiftIterable = convertExpression(iterable)
        return "for \(varName) in \(swiftIterable) {"
    }
    
    private func convertWhileLoop(_ line: String) -> String {
        let condition = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
        let swiftCondition = convertExpression(condition.replacingOccurrences(of: ":", with: ""))
        return "while \(swiftCondition) {"
    }
    
    private func convertReturn(_ line: String) -> String {
        let value = String(line.dropFirst(7)).trimmingCharacters(in: .whitespaces)
        let swiftValue = convertExpression(value)
        return "return \(swiftValue)"
    }
    
    private func convertAssignment(_ line: String) -> String {
        let parts = line.components(separatedBy: "=")
        guard parts.count == 2 else { return line }
        
        let varName = parts[0].trimmingCharacters(in: .whitespaces)
        let value = parts[1].trimmingCharacters(in: .whitespaces)
        
        // Detektiraj tip varijable
        let swiftValue = convertExpression(value)
        
        // Provjeri je li deklaracija ili dodjeljivanje
        if varName.contains(" ") {
            // Možda je tip anotacija
            return "let \(varName) = \(swiftValue)"
        } else {
            return "let \(varName) = \(swiftValue)"
        }
    }
    
    private func convertPrint(_ line: String) -> String {
        let content = String(line.dropFirst(5).dropLast())
        let swiftContent = convertExpression(content)
        return "print(\(swiftContent))"
    }
    
    private func convertExpression(_ expr: String) -> String {
        var result = expr
        
        // Konvertiraj None u nil
        result = result.replacingOccurrences(of: "None", with: "nil")
        
        // Konvertiraj True/False
        result = result.replacingOccurrences(of: "True", with: "true")
        result = result.replacingOccurrences(of: "False", with: "false")
        
        // Konvertiraj and/or u &&/||
        result = result.replacingOccurrences(of: " and ", with: " && ")
        result = result.replacingOccurrences(of: " or ", with: " || ")
        result = result.replacingOccurrences(of: " not ", with: " !")
        
        // Konvertiraj == u == (ostaje isto)
        // Konvertiraj != u != (ostaje isto)
        
        return result
    }
    
    private func convertParameters(_ params: String) -> String {
        if params.isEmpty { return "" }
        
        return params
            .components(separatedBy: ",")
            .map { param in
                let trimmed = param.trimmingCharacters(in: .whitespaces)
                let parts = trimmed.components(separatedBy: ":")
                if parts.count == 2 {
                    let name = parts[0].trimmingCharacters(in: .whitespaces)
                    let type = parts[1].trimmingCharacters(in: .whitespaces)
                    return "\(name): \(mapPythonTypeToSwift(type))"
                } else if trimmed.contains("=") {
                    let defaultParts = trimmed.components(separatedBy: "=")
                    if defaultParts.count == 2 {
                        let name = defaultParts[0].trimmingCharacters(in: .whitespaces)
                        let defaultValue = defaultParts[1].trimmingCharacters(in: .whitespaces)
                        return "\(name) = \(convertExpression(defaultValue))"
                    }
                }
                return trimmed
            }
            .joined(separator: ", ")
    }
    
    private func mapPythonTypeToSwift(_ pythonType: String) -> String {
        let type = pythonType.lowercased()
        switch type {
        case "int", "integer":
            return "Int"
        case "float":
            return "Double"
        case "str", "string":
            return "String"
        case "bool", "boolean":
            return "Bool"
        case "list":
            return "[Any]"
        case "dict":
            return "[String: Any]"
        case "tuple":
            return "(Any, Any)"
        default:
            return "Any"
        }
    }
}








