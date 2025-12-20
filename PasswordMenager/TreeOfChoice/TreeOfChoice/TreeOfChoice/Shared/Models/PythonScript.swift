//
//  PythonScript.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Model za Python skriptu
struct PythonScript: Identifiable, Codable {
    let id: UUID
    let name: String
    let content: String
    let fileURL: URL?
    let createdAt: Date
    var convertedSwiftCode: String?
    var conversionStatus: ConversionStatus
    var astStructure: ASTNode?
    var dependencies: [String]
    var tests: [SwiftTest]?
    
    init(name: String, content: String, fileURL: URL? = nil) {
        self.id = UUID()
        self.name = name
        self.content = content
        self.fileURL = fileURL
        self.createdAt = Date()
        self.conversionStatus = .pending
        self.astStructure = nil
        self.dependencies = []
        self.tests = nil
    }
}

enum ConversionStatus: String, Codable {
    case pending = "pending"
    case analyzing = "analyzing"
    case converting = "converting"
    case success = "success"
    case failed = "failed"
    case testing = "testing"
}

/// AST Node za Python kod
struct ASTNode: Codable {
    let type: String
    let name: String?
    let value: String?
    let children: [ASTNode]
    let lineNumber: Int?
    let attributes: [String: String]
}

/// Swift test model
struct SwiftTest: Identifiable, Codable {
    let id: UUID
    let name: String
    let code: String
    let testType: TestType
    
    init(name: String, code: String, testType: TestType) {
        self.id = UUID()
        self.name = name
        self.code = code
        self.testType = testType
    }
}

enum TestType: String, Codable {
    case unit = "unit"
    case integration = "integration"
    case performance = "performance"
}




