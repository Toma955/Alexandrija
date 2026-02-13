//
//  CodeView.swift
//  Alexandria
//
//  Vizualizacija koda – kod → UX. Syntax highlighting za Swift.
//

import SwiftUI
import AppKit

/// Jedna linija koda s atributima (boja po tipu tokena)
struct CodeLine: Identifiable {
    let id = UUID()
    let number: Int
    let segments: [CodeSegment]
}

struct CodeSegment {
    let text: String
    let tokenType: CodeTokenType
}

enum CodeTokenType {
    case plain
    case keyword
    case string
    case comment
    case number
    case typeName
    case function
}

// MARK: - Parser – Swift kod u tokene
enum CodeParser {
    private static let keywords: Set<String> = [
        "import", "struct", "class", "enum", "protocol", "extension",
        "func", "var", "let", "return", "if", "else", "switch", "case",
        "for", "in", "while", "guard", "try", "catch", "throw", "async", "await",
        "private", "public", "internal", "static", "final", "override",
        "self", "nil", "true", "false", "some", "any"
    ]
    
    static func parse(_ source: String) -> [CodeLine] {
        let lines = source.components(separatedBy: .newlines)
        return lines.enumerated().map { index, line in
            CodeLine(number: index + 1, segments: parseLine(line))
        }
    }
    
    private static func parseLine(_ line: String) -> [CodeSegment] {
        var segments: [CodeSegment] = []
        var i = line.startIndex
        
        while i < line.endIndex {
            // Komentar //
            if line[i] == "/", i < line.index(before: line.endIndex),
               line[line.index(after: i)] == "/" {
                let rest = String(line[i...])
                segments.append(CodeSegment(text: rest, tokenType: .comment))
                break
            }
            // String "..."
            if line[i] == "\"" {
                var end = line.index(after: i)
                while end < line.endIndex {
                    if line[end] == "\\", line.index(after: end) < line.endIndex {
                        end = line.index(end, offsetBy: 2)
                    } else if line[end] == "\"" {
                        end = line.index(after: end)
                        break
                    } else {
                        end = line.index(after: end)
                    }
                }
                segments.append(CodeSegment(text: String(line[i..<end]), tokenType: .string))
                i = end
                continue
            }
            // Broj
            if line[i].isNumber {
                var end = i
                while end < line.endIndex, (line[end].isNumber || line[end] == ".") { end = line.index(after: end) }
                segments.append(CodeSegment(text: String(line[i..<end]), tokenType: .number))
                i = end
                continue
            }
            // Riječ (keyword, type, function)
            if line[i].isLetter || line[i] == "_" {
                var end = i
                while end < line.endIndex, (line[end].isLetter || line[end].isNumber || line[end] == "_") {
                    end = line.index(after: end)
                }
                let word = String(line[i..<end])
                let type: CodeTokenType = keywords.contains(word) ? .keyword : (word.first?.isUppercase == true ? .typeName : .function)
                segments.append(CodeSegment(text: word, tokenType: type))
                i = end
                continue
            }
            // Ostalo
            let next = line.index(after: i)
            segments.append(CodeSegment(text: String(line[i..<next]), tokenType: .plain))
            i = next
        }
        return segments
    }
}

// MARK: - Code View – prikaz koda s syntax highlighting
struct CodeView: View {
    let source: String
    let accentColor: Color
    
    init(source: String, accentColor: Color = Color(hex: "ff5c00")) {
        self.source = source
        self.accentColor = accentColor
    }
    
    private var lines: [CodeLine] {
        CodeParser.parse(source)
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(lines) { line in
                    HStack(alignment: .top, spacing: 0) {
                        Text("\(line.number)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 36, alignment: .trailing)
                        
                        HStack(spacing: 0) {
                            ForEach(Array(line.segments.enumerated()), id: \.offset) { _, seg in
                                Text(seg.text)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(colorFor(seg.tokenType))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                }
            }
            .padding(16)
        }
        .background(Color.black.opacity(0.85))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func colorFor(_ type: CodeTokenType) -> Color {
        switch type {
        case .plain: return .white
        case .keyword: return Color(red: 0.9, green: 0.4, blue: 0.9)
        case .string: return Color(red: 0.9, green: 0.7, blue: 0.4)
        case .comment: return Color(red: 0.4, green: 0.7, blue: 0.4)
        case .number: return Color(red: 0.6, green: 0.8, blue: 1.0)
        case .typeName: return accentColor
        case .function: return Color(red: 0.6, green: 0.9, blue: 1.0)
        }
    }
}

#Preview {
    CodeView(source: """
    import SwiftUI

    struct ContentView: View {
        var body: some View {
            Text("Hello")
        }
    }
    """)
    .frame(width: 400, height: 200)
}
