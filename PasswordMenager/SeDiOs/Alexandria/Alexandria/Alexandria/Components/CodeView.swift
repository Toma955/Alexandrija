//
//  CodeView.swift
//  Alexandria
//
//  Vizualizacija koda – Xcode-like prikaz s gutterom i syntax highlightingom.
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

// MARK: - Xcode-like boje (tamna tema)
private enum XcodeStyle {
    static let background = Color(hex: "1e1e1e")
    static let gutterBackground = Color(hex: "252526")
    static let gutterSeparator = Color.white.opacity(0.08)
    static let lineNumber = Color.white.opacity(0.45)
    static let plain = Color(hex: "d4d4d4")
    static let keyword = Color(hex: "c586c0")
    static let string = Color(hex: "ce9178")
    static let comment = Color(hex: "6a9955")
    static let number = Color(hex: "b5cea8")
    static let typeName = Color(hex: "4ec9b0")
    static let function = Color(hex: "dcdcaa")
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

// MARK: - Normalizacija izvora (čisti prikaz i kopiranje – jedan oblik novih redova, indentacija ostaje)
private func normalizedSource(_ raw: String) -> String {
    var s = raw
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")
    while s.hasSuffix("\n\n") { s = String(s.dropLast()) }
    if !s.hasSuffix("\n") { s += "\n" }
    return s
}

// MARK: - Code View – Xcode-like prikaz (gutter, monospace, tamna tema, kopiraj)
struct CodeView: View {
    let source: String
    let accentColor: Color
    let showCopyButton: Bool
    
    @State private var copyFeedback: Bool = false
    /// Keš parsiranih linija da se ne re-parsira pri svakom crtanju (izbjegava zapinjanje).
    @State private var cachedLines: [CodeLine] = []
    
    private static let lineNumberWidth: CGFloat = 44
    private static let fontSize: CGFloat = 12
    private static let lineHeight: CGFloat = 20
    
    /// Normalizirani izvor – jedan oblik novih redova, bez razmaka na kraju; uvijek završava novim redom.
    private var displaySource: String {
        normalizedSource(source)
    }
    
    init(source: String, accentColor: Color = Color(hex: "ff5c00"), showCopyButton: Bool = true) {
        self.source = source
        self.accentColor = accentColor
        self.showCopyButton = showCopyButton
        _cachedLines = State(initialValue: CodeParser.parse(normalizedSource(source)))
    }
    
    private var lines: [CodeLine] {
        cachedLines
    }
    
    private var codeFont: Font {
        Font.system(size: Self.fontSize, weight: .regular, design: .monospaced)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Vertikalni scroll zajedno za gutter + kod; samo kod scrolla vodoravno (kao Xcode)
            ScrollView(.vertical, showsIndicators: true) {
            HStack(alignment: .top, spacing: 0) {
                // Gutter – fiksna širina, ne pomiče se vodoravno
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(lines, id: \.number) { line in
                        Text("\(line.number)")
                            .font(codeFont)
                            .foregroundColor(XcodeStyle.lineNumber)
                            .frame(height: Self.lineHeight)
                    }
                }
                .frame(width: Self.lineNumberWidth)
                .padding(.top, 16)
                .padding(.trailing, 10)
                .padding(.leading, 8)
                .background(XcodeStyle.gutterBackground)
                
                Rectangle()
                    .fill(XcodeStyle.gutterSeparator)
                    .frame(width: 1)
                
                ScrollView(.horizontal, showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(lines, id: \.number) { line in
                            HStack(spacing: 0) {
                                ForEach(Array(line.segments.enumerated()), id: \.offset) { _, seg in
                                    Text(seg.text)
                                        .font(codeFont)
                                        .foregroundColor(colorFor(seg.tokenType))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: Self.lineHeight)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity)
                .background(XcodeStyle.background)
            }
            }
            .background(XcodeStyle.background)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if showCopyButton {
                copyButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: source) { _, newSource in
            cachedLines = CodeParser.parse(normalizedSource(newSource))
        }
    }
    
    private var copyButton: some View {
        HStack(spacing: 6) {
            if copyFeedback {
                Text("Kopirano!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(XcodeStyle.comment)
            }
            Button {
                copySourceToPasteboard()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                    Text("Kopiraj kod")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(XcodeStyle.gutterBackground)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }
    
    private func copySourceToPasteboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(displaySource, forType: .string)
        copyFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copyFeedback = false
        }
    }
    
    private func colorFor(_ type: CodeTokenType) -> Color {
        switch type {
        case .plain: return XcodeStyle.plain
        case .keyword: return XcodeStyle.keyword
        case .string: return XcodeStyle.string
        case .comment: return XcodeStyle.comment
        case .number: return XcodeStyle.number
        case .typeName: return XcodeStyle.typeName
        case .function: return XcodeStyle.function
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
