//
//  SwiftTestGenerator.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Generator za automatsko kreiranje Swift testova
final class SwiftTestGenerator {
    
    static let shared = SwiftTestGenerator()
    
    private init() {}
    
    /// Generira testove za Swift kod na osnovu Python strukture
    func generateTests(for pythonScript: PythonScript, swiftCode: String) -> [SwiftTest] {
        var tests: [SwiftTest] = []
        
        // Generiraj unit testove za funkcije
        if let structure = analyzeSwiftCode(swiftCode) {
            for function in structure.functions {
                let unitTest = generateUnitTest(for: function)
                tests.append(unitTest)
            }
            
            // Generiraj integration testove
            if structure.functions.count > 1 {
                let integrationTest = generateIntegrationTest(for: structure)
                tests.append(integrationTest)
            }
        }
        
        return tests
    }
    
    // MARK: - Private Methods
    
    private func analyzeSwiftCode(_ code: String) -> SwiftCodeStructure? {
        var functions: [SwiftFunction] = []
        var classes: [SwiftClass] = []
        
        let lines = code.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Detektiraj funkcije
            if trimmed.hasPrefix("func ") {
                let funcInfo = extractFunctionInfo(from: trimmed, at: index + 1)
                functions.append(funcInfo)
            }
            
            // Detektiraj klase
            if trimmed.hasPrefix("class ") {
                let classInfo = extractClassInfo(from: trimmed, at: index + 1)
                classes.append(classInfo)
            }
        }
        
        return SwiftCodeStructure(functions: functions, classes: classes)
    }
    
    private func extractFunctionInfo(from line: String, at lineNumber: Int) -> SwiftFunction {
        let pattern = #"func\s+(\w+)\s*\((.*?)\)\s*(?:->\s*(\w+))?"#
        var name = "function"
        var parameters: [String] = []
        var returnType: String? = nil
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
            if match.numberOfRanges > 1 {
                let nameRange = match.range(at: 1)
                if let swiftRange = Range(nameRange, in: line) {
                    name = String(line[swiftRange])
                }
            }
            if match.numberOfRanges > 2 {
                let paramsRange = match.range(at: 2)
                if let swiftRange = Range(paramsRange, in: line) {
                    let paramsString = String(line[swiftRange])
                    parameters = paramsString
                        .components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                }
            }
            if match.numberOfRanges > 3 {
                let returnRange = match.range(at: 3)
                if let swiftRange = Range(returnRange, in: line) {
                    returnType = String(line[swiftRange])
                }
            }
        }
        
        return SwiftFunction(
            name: name,
            parameters: parameters,
            returnType: returnType,
            lineNumber: lineNumber
        )
    }
    
    private func extractClassInfo(from line: String, at lineNumber: Int) -> SwiftClass {
        let pattern = #"class\s+(\w+)"#
        var name = "Class"
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
           match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: line) {
                name = String(line[swiftRange])
            }
        }
        
        return SwiftClass(name: name, lineNumber: lineNumber)
    }
    
    private func generateUnitTest(for function: SwiftFunction) -> SwiftTest {
        let testName = "test\(function.name.capitalized)"
        let paramValues = generateTestParameterValues(for: function.parameters)
        let assertion = generateAssertion(for: function)
        
        let testCode = """
        func \(testName)() {
            // Arrange
            \(paramValues)
            
            // Act
            \(generateFunctionCall(function: function, with: paramValues))
            
            // Assert
            \(assertion)
        }
        """
        
        return SwiftTest(
            name: testName,
            code: testCode,
            testType: .unit
        )
    }
    
    private func generateIntegrationTest(for structure: SwiftCodeStructure) -> SwiftTest {
        let testName = "testIntegration"
        var testCode = "func \(testName)() {\n"
        
        // Testiraj interakciju između funkcija
        if structure.functions.count >= 2 {
            let firstFunc = structure.functions[0]
            let secondFunc = structure.functions[1]
            
            testCode += """
                // Test integration between \(firstFunc.name) and \(secondFunc.name)
                let result1 = \(generateFunctionCall(function: firstFunc, with: generateTestParameterValues(for: firstFunc.parameters)))
                let result2 = \(generateFunctionCall(function: secondFunc, with: generateTestParameterValues(for: secondFunc.parameters)))
                
                // Verify integration
                XCTAssertNotNil(result1)
                XCTAssertNotNil(result2)
            """
        }
        
        testCode += "\n}"
        
        return SwiftTest(
            name: testName,
            code: testCode,
            testType: .integration
        )
    }
    
    private func generateTestParameterValues(for parameters: [String]) -> String {
        var values: [String] = []
        for (index, param) in parameters.enumerated() {
            let paramName = param.components(separatedBy: ":").first?.trimmingCharacters(in: .whitespaces) ?? "param\(index)"
            let paramType = param.contains(":") ? param.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) : nil
            
            let defaultValue = generateDefaultValue(for: paramType ?? "Any")
            values.append("let \(paramName) = \(defaultValue)")
        }
        return values.joined(separator: "\n        ")
    }
    
    private func generateDefaultValue(for type: String) -> String {
        let lowerType = type.lowercased()
        switch lowerType {
        case "int":
            return "42"
        case "double", "float":
            return "3.14"
        case "string":
            return "\"test\""
        case "bool":
            return "true"
        case "[any]", "array":
            return "[]"
        case "[string: any]", "dictionary", "dict":
            return "[:]"
        default:
            return "nil"
        }
    }
    
    private func generateFunctionCall(function: SwiftFunction, with paramValues: String) -> String {
        let paramNames = function.parameters
            .map { $0.components(separatedBy: ":").first?.trimmingCharacters(in: .whitespaces) ?? "" }
            .filter { !$0.isEmpty }
        
        let callParams = paramNames.map { name in
            // Pokušaj pronaći vrijednost iz paramValues
            if paramValues.contains("let \(name) =") {
                return name
            }
            return generateDefaultValue(for: "Any")
        }.joined(separator: ", ")
        
        if let returnType = function.returnType {
            return "let result = \(function.name)(\(callParams))"
        } else {
            return "\(function.name)(\(callParams))"
        }
    }
    
    private func generateAssertion(for function: SwiftFunction) -> String {
        if let returnType = function.returnType {
            switch returnType.lowercased() {
            case "int", "double", "float":
                return "XCTAssertNotNil(result)"
            case "string":
                return "XCTAssertNotNil(result)\n        XCTAssertFalse(result.isEmpty)"
            case "bool":
                return "XCTAssertNotNil(result)"
            default:
                return "XCTAssertNotNil(result)"
            }
        } else {
            return "// No return value to assert"
        }
    }
}

// MARK: - Supporting Types

struct SwiftCodeStructure {
    let functions: [SwiftFunction]
    let classes: [SwiftClass]
}

struct SwiftFunction {
    let name: String
    let parameters: [String]
    let returnType: String?
    let lineNumber: Int
}

struct SwiftClass {
    let name: String
    let lineNumber: Int
}







