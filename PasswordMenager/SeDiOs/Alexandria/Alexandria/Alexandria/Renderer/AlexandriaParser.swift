//
//  AlexandriaParser.swift
//  Alexandria
//
//  Parser – Swift-like DSL → AlexandriaViewNode tree.
//

import Foundation

enum AlexandriaParseError: Error, LocalizedError {
    case unexpectedEnd
    case expected(String)
    case invalidNumber
    
    var errorDescription: String? {
        switch self {
        case .unexpectedEnd: return "Neočekivan kraj ulaza"
        case .expected(let s): return "Očekivano: \(s)"
        case .invalidNumber: return "Neispravan broj"
        }
    }
}

final class AlexandriaParser {
    private var input: String
    private var index: String.Index
    private var depth: Int = 0
    private let maxDepth = 100
    
    init(source: String) {
        self.input = source
        self.index = source.startIndex
    }
    
    func parse() throws -> AlexandriaViewNode {
        depth = 0
        skipWhitespaceAndNewlines()
        let node = try parseView()
        skipWhitespaceAndNewlines()
        guard index >= input.endIndex else {
            throw AlexandriaParseError.expected("end of input")
        }
        return node
    }
    
    private var current: Character? {
        index < input.endIndex ? input[index] : nil
    }
    
    private func advance() {
        if index < input.endIndex { index = input.index(after: index) }
    }
    
    private func skipWhitespaceAndNewlines() {
        while index < input.endIndex {
            let c = input[index]
            if c.isWhitespace || c.isNewline || c == "\t" {
                advance()
            } else if current == "/", peekNext() == "/" {
                skipLineComment()
            } else {
                break
            }
        }
    }
    
    private func peekNext() -> Character? {
        guard index < input.endIndex else { return nil }
        let next = input.index(after: index)
        guard next < input.endIndex else { return nil }
        return input[next]
    }
    
    private func skipLineComment() {
        while index < input.endIndex, input[index] != "\n" { advance() }
    }
    
    /// Preskače opcionalne prazne zagrade () – npr. Divider(), Spacer()
    private func skipOptionalParens() {
        skipWhitespaceAndNewlines()
        guard current == "(" else { return }
        advance()
        skipWhitespaceAndNewlines()
        guard current == ")" else { return }
        advance()
    }
    
    /// Preskače opcionalne zagrade s bilo kojim sadržajem – npr. ZStack(), ZStack(spacing: 8)
    private func skipOptionalSpacing() {
        skipWhitespaceAndNewlines()
        guard current == "(" else { return }
        advance()
        while index < input.endIndex, current != ")" { advance() }
        if current == ")" { advance() }
    }
    
    private func parseIdentifier() -> String {
        var result = ""
        while index < input.endIndex, (input[index].isLetter || input[index].isNumber || input[index] == "_") {
            result.append(input[index])
            advance()
        }
        return result
    }
    
    private func parseView() throws -> AlexandriaViewNode {
        depth += 1
        defer { depth -= 1 }
        guard depth <= maxDepth else {
            throw AlexandriaParseError.expected("prevelika dubina ugniježđenja (max \(maxDepth))")
        }
        skipWhitespaceAndNewlines()
        guard index < input.endIndex else { throw AlexandriaParseError.unexpectedEnd }
        
        let word = parseIdentifier()
        switch word.lowercased() {
        case "vstack":
            return try parseVStack()
        case "hstack":
            return try parseHStack()
        case "zstack":
            return try parseZStack()
        case "lazyvstack":
            return try parseLazyVStack()
        case "lazyhstack":
            return try parseLazyHStack()
        case "scrollview":
            return try parseScrollView()
        case "list":
            return try parseList()
        case "form":
            return try parseForm()
        case "grid":
            return try parseGrid()
        case "tabview":
            return try parseTabView()
        case "group":
            return try parseGroup()
        case "groupbox":
            return try parseGroupBox()
        case "section":
            return try parseSection()
        case "disclosuregroup":
            return try parseDisclosureGroup()
        case "text":
            return try parseText()
        case "button":
            return try parseButton()
        case "image":
            return try parseImage()
        case "label":
            return try parseLabel()
        case "link":
            return try parseLink()
        case "textfield":
            return try parseTextField()
        case "securefield":
            return try parseSecureField()
        case "texteditor":
            return try parseTextEditor()
        case "toggle":
            return try parseToggle()
        case "slider":
            return try parseSlider()
        case "stepper":
            return try parseStepper()
        case "picker":
            return try parsePicker()
        case "progressview":
            return try parseProgressView()
        case "gauge":
            return try parseGauge()
        case "menu":
            return try parseMenu()
        case "spacer":
            skipOptionalParens()  // Spacer() – Eluminatium šalje sa zagradama
            return .spacer
        case "divider":
            skipOptionalParens()  // Divider() – Eluminatium šalje sa zagradama
            return .divider
        case "color":
            return try parseColor()
        case "rectangle":
            skipOptionalParens()
            return .rectangle
        case "roundedrectangle":
            return try parseRoundedRectangle()
        case "circle":
            skipOptionalParens()
            return .circle
        case "ellipse":
            skipOptionalParens()
            return .ellipse
        case "capsule":
            skipOptionalParens()
            return .capsule
        case "padding":
            return try parsePadding()
        case "frame":
            return try parseFrame()
        case "position", "positioned":
            return try parsePositioned()
        case "background":
            return try parseBackground()
        case "foreground":
            return try parseForeground()
        default:
            let expected = "VStack, HStack, ZStack, ScrollView, Text, Button, Image, Spacer, Divider, Color, Rectangle, Circle"
            if word.isEmpty {
                throw AlexandriaParseError.expected(expected)
            }
            throw AlexandriaParseError.expected("\(expected) – pronađeno: „\(word)“")
        }
    }
    
    private func parseOptionalSpacing() throws -> CGFloat? {
        skipWhitespaceAndNewlines()
        if current != "(" { return nil }
        advance()
        skipWhitespaceAndNewlines()
        guard parseIdentifier().lowercased() == "spacing" else {
            while index < input.endIndex, current != ")" { advance() }
            if current == ")" { advance() }
            return nil
        }
        skipWhitespaceAndNewlines()
        if current == ":" { advance(); skipWhitespaceAndNewlines() }
        let spacing = try parseCGFloat()
        skipWhitespaceAndNewlines()
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        return spacing
    }
    
    private func parseVStack() throws -> AlexandriaViewNode {
        let spacing = try parseOptionalSpacing()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        var children: [AlexandriaViewNode] = []
        while true {
            skipWhitespaceAndNewlines()
            if current == "}" { break }
            children.append(try parseView())
        }
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .vStack(children: children, spacing: spacing)
    }
    
    private func parseHStack() throws -> AlexandriaViewNode {
        let spacing = try parseOptionalSpacing()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        var children: [AlexandriaViewNode] = []
        while true {
            skipWhitespaceAndNewlines()
            if current == "}" { break }
            children.append(try parseView())
        }
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .hStack(children: children, spacing: spacing)
    }
    
    private func parseZStack() throws -> AlexandriaViewNode {
        skipOptionalSpacing()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        var children: [AlexandriaViewNode] = []
        while true {
            skipWhitespaceAndNewlines()
            if current == "}" { break }
            children.append(try parseView())
        }
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .zStack(children: children)
    }
    
    private func parseLazyVStack() throws -> AlexandriaViewNode {
        let spacing = try parseOptionalSpacing()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        var children: [AlexandriaViewNode] = []
        while true {
            skipWhitespaceAndNewlines()
            if current == "}" { break }
            children.append(try parseView())
        }
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .lazyVStack(children: children, spacing: spacing)
    }
    
    private func parseLazyHStack() throws -> AlexandriaViewNode {
        let spacing = try parseOptionalSpacing()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        var children: [AlexandriaViewNode] = []
        while true {
            skipWhitespaceAndNewlines()
            if current == "}" { break }
            children.append(try parseView())
        }
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .lazyHStack(children: children, spacing: spacing)
    }
    
    private func parseScrollView() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        let child = try parseView()
        skipWhitespaceAndNewlines()
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .scrollView(child: child)
    }
    
    private func parseList() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        var children: [AlexandriaViewNode] = []
        while true {
            skipWhitespaceAndNewlines()
            if current == "}" { break }
            children.append(try parseView())
        }
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .list(children: children)
    }
    
    private func parseForm() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        var children: [AlexandriaViewNode] = []
        while true {
            skipWhitespaceAndNewlines()
            if current == "}" { break }
            children.append(try parseView())
        }
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .form(children: children)
    }
    
    private func parseGrid() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        var children: [AlexandriaViewNode] = []
        while true {
            skipWhitespaceAndNewlines()
            if current == "}" { break }
            children.append(try parseView())
        }
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .grid(children: children)
    }
    
    private func parseTabView() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        var tabs: [TabItem] = []
        while true {
            skipWhitespaceAndNewlines()
            if current == "}" { break }
            let label = try parseStringOrIdentifier()
            skipWhitespaceAndNewlines()
            guard current == "{" else { throw AlexandriaParseError.expected("{") }
            advance()
            let content = try parseView()
            skipWhitespaceAndNewlines()
            guard current == "}" else { throw AlexandriaParseError.expected("}") }
            advance()
            tabs.append(TabItem(label: label, content: content))
        }
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .tabView(tabs: tabs)
    }
    
    private func parseStringOrIdentifier() throws -> String {
        skipWhitespaceAndNewlines()
        if current == "\"" { return try parseString() }
        return parseIdentifier()
    }
    
    private func parseGroup() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        let child = try parseView()
        skipWhitespaceAndNewlines()
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .group(child: child)
    }
    
    private func parseGroupBox() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let label = try parseString()
        skipWhitespaceAndNewlines()
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        let child = try parseView()
        skipWhitespaceAndNewlines()
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .groupBox(label: label, child: child)
    }
    
    private func parseSection() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        var header: String? = nil, footer: String? = nil
        if current == "(" {
            advance()
            skipWhitespaceAndNewlines()
            if current == "\"" { header = try parseString() }
            skipWhitespaceAndNewlines()
            if current == "," { advance(); skipWhitespaceAndNewlines(); if current == "\"" { footer = try parseString() } }
            skipWhitespaceAndNewlines()
            while index < input.endIndex, current != ")" { advance() }
            if current == ")" { advance() }
            skipWhitespaceAndNewlines()
        }
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        let child = try parseView()
        skipWhitespaceAndNewlines()
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .section(header: header, footer: footer, child: child)
    }
    
    private func parseDisclosureGroup() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let label = try parseString()
        skipWhitespaceAndNewlines()
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        let child = try parseView()
        skipWhitespaceAndNewlines()
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .disclosureGroup(label: label, child: child)
    }
    
    private func parseLabel() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let title = try parseString()
        skipWhitespaceAndNewlines()
        var sysImg = "doc"
        if current == "," { advance(); skipWhitespaceAndNewlines(); sysImg = try parseString() }
        skipWhitespaceAndNewlines()
        while index < input.endIndex, current != ")" { advance() }
        if current == ")" { advance() }
        return .label(title, systemImage: sysImg)
    }
    
    private func parseLink() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let title = try parseString()
        skipWhitespaceAndNewlines()
        var url = "https://"
        if current == "," { advance(); skipWhitespaceAndNewlines(); url = try parseString() }
        skipWhitespaceAndNewlines()
        while index < input.endIndex, current != ")" { advance() }
        if current == ")" { advance() }
        return .link(title, url: url)
    }
    
    private func parseTextField() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let placeholder = try parseString()
        skipWhitespaceAndNewlines()
        while index < input.endIndex, current != ")" { advance() }
        if current == ")" { advance() }
        return .textField(placeholder: placeholder)
    }
    
    private func parseSecureField() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let placeholder = try parseString()
        skipWhitespaceAndNewlines()
        while index < input.endIndex, current != ")" { advance() }
        if current == ")" { advance() }
        return .secureField(placeholder: placeholder)
    }
    
    private func parseTextEditor() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let placeholder = try parseString()
        skipWhitespaceAndNewlines()
        while index < input.endIndex, current != ")" { advance() }
        if current == ")" { advance() }
        return .textEditor(placeholder: placeholder)
    }
    
    private func parseToggle() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let label = try parseString()
        skipWhitespaceAndNewlines()
        var isOn = false
        if current == "," { advance(); skipWhitespaceAndNewlines(); if parseIdentifier().lowercased() == "ison" { skipWhitespaceAndNewlines(); if current == ":" { advance(); skipWhitespaceAndNewlines() }; isOn = try parseCGFloat() > 0 } }
        skipWhitespaceAndNewlines()
        while index < input.endIndex, current != ")" { advance() }
        if current == ")" { advance() }
        return .toggle(label: label, isOn: isOn)
    }
    
    private func parseSlider() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        var value: CGFloat = 0.5, minV: CGFloat = 0, maxV: CGFloat = 1
        while index < input.endIndex, current != ")" {
            skipWhitespaceAndNewlines()
            let id = parseIdentifier().lowercased()
            skipWhitespaceAndNewlines()
            if current == ":" { advance(); skipWhitespaceAndNewlines() }
            if id == "value" { value = try parseCGFloat() }
            else if id == "in" { minV = try parseCGFloat(); skipWhitespaceAndNewlines(); if current == "." { advance(); advance(); advance(); maxV = try parseCGFloat() } }
            skipWhitespaceAndNewlines()
            if current == "," { advance() }
        }
        if current == ")" { advance() }
        return .slider(value: value, range: minV...maxV)
    }
    
    private func parseStepper() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let label = try parseString()
        skipWhitespaceAndNewlines()
        var value: CGFloat = 0, step: CGFloat = 1
        if current == "," { advance(); skipWhitespaceAndNewlines(); value = try parseCGFloat() }
        if current == "," { advance(); skipWhitespaceAndNewlines(); step = try parseCGFloat() }
        skipWhitespaceAndNewlines()
        while index < input.endIndex, current != ")" { advance() }
        if current == ")" { advance() }
        return .stepper(label: label, value: value, step: step)
    }
    
    private func parsePicker() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let label = try parseString()
        skipWhitespaceAndNewlines()
        var options: [String] = []
        if current == "," { advance(); skipWhitespaceAndNewlines(); if current == "[" { advance(); while current != "]" { skipWhitespaceAndNewlines(); if current == "\"" { options.append(try parseString()) }; skipWhitespaceAndNewlines(); if current == "," { advance() } }; if current == "]" { advance() } } }
        skipWhitespaceAndNewlines()
        while index < input.endIndex, current != ")" { advance() }
        if current == ")" { advance() }
        return .picker(label: label, options: options.isEmpty ? ["A", "B", "C"] : options)
    }
    
    private func parseProgressView() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        var value: CGFloat? = nil
        if current == "(" {
            advance()
            skipWhitespaceAndNewlines()
            if current != ")" { value = try parseCGFloat() }
            skipWhitespaceAndNewlines()
            while index < input.endIndex, current != ")" { advance() }
            if current == ")" { advance() }
        }
        return .progressView(value: value)
    }
    
    private func parseGauge() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        var value: CGFloat = 0.5, minV: CGFloat = 0, maxV: CGFloat = 1, label = ""
        while index < input.endIndex, current != ")" {
            skipWhitespaceAndNewlines()
            let id = parseIdentifier().lowercased()
            skipWhitespaceAndNewlines()
            if current == ":" { advance(); skipWhitespaceAndNewlines() }
            if id == "value" { value = try parseCGFloat() }
            else if id == "in" { minV = try parseCGFloat(); skipWhitespaceAndNewlines(); if current == "." { advance(); advance(); advance(); maxV = try parseCGFloat() } }
            else if id == "label" { label = try parseString() }
            skipWhitespaceAndNewlines()
            if current == "," { advance() }
        }
        if current == ")" { advance() }
        return .gauge(value: value, range: minV...maxV, label: label)
    }
    
    private func parseMenu() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let label = try parseString()
        skipWhitespaceAndNewlines()
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        var children: [AlexandriaViewNode] = []
        while true {
            skipWhitespaceAndNewlines()
            if current == "}" { break }
            children.append(try parseView())
        }
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .menu(label: label, children: children)
    }
    
    private func parseColor() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        skipWhitespaceAndNewlines()
        var hex: String
        if current == "\"" {
            hex = try parseString()
        } else {
            guard parseIdentifier().lowercased() == "hex" else { throw AlexandriaParseError.expected("hex: or \"") }
            skipWhitespaceAndNewlines()
            if current == ":" { advance(); skipWhitespaceAndNewlines() }
            hex = try parseString()
        }
        skipWhitespaceAndNewlines()
        while index < input.endIndex, current != ")" { advance() }
        if current == ")" { advance() }
        return .color(hex)
    }
    
    private func parseRoundedRectangle() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        skipWhitespaceAndNewlines()
        var radius: CGFloat = 8
        if current != ")" {
            let id = parseIdentifier().lowercased()
            if id == "cornerradius" || id == "radius" {
                skipWhitespaceAndNewlines()
                if current == ":" { advance(); skipWhitespaceAndNewlines() }
                radius = try parseCGFloat()
            }
            skipWhitespaceAndNewlines()
            while index < input.endIndex, current != ")" { advance() }
        }
        if current == ")" { advance() }
        return .roundedRectangle(cornerRadius: radius)
    }
    
    private func parseText() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let content = try parseString()
        skipWhitespaceAndNewlines()
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        return .text(content)
    }
    
    private func parseString() throws -> String {
        skipWhitespaceAndNewlines()
        guard current == "\"" else { throw AlexandriaParseError.expected("\"") }
        advance()
        var result = ""
        while index < input.endIndex {
            if input[index] == "\\" {
                advance()
                if index < input.endIndex {
                    result.append(input[index])
                    advance()
                }
            } else if input[index] == "\"" {
                advance()
                return result
            } else {
                result.append(input[index])
                advance()
            }
        }
        throw AlexandriaParseError.expected("closing \"")
    }
    
    private func parseButton() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let label = try parseString()
        skipWhitespaceAndNewlines()
        var action: String? = nil
        if current == "," {
            advance()
            skipWhitespaceAndNewlines()
            if current == "{" {
                advance()
                action = "tap"
                while index < input.endIndex, current != "}" { advance() }
                if current == "}" { advance() }
            }
        }
        skipWhitespaceAndNewlines()
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        return .button(label, action: action)
    }
    
    private func parseImage() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let name = try parseString()
        skipWhitespaceAndNewlines()
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        return .image(name)
    }
    
    private func parseCGFloat() throws -> CGFloat {
        var numStr = ""
        while index < input.endIndex, (input[index].isNumber || input[index] == ".") {
            numStr.append(input[index])
            advance()
        }
        guard let val = Double(numStr) else { throw AlexandriaParseError.invalidNumber }
        return CGFloat(val)
    }
    
    private func parsePadding() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let amount = try parseCGFloat()
        skipWhitespaceAndNewlines()
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        let child = try parseView()
        skipWhitespaceAndNewlines()
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .padding(amount, child: child)
    }
    
    private func parseFrame() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        var width: CGFloat? = nil, height: CGFloat? = nil
        while index < input.endIndex, current != ")" {
            skipWhitespaceAndNewlines()
            let id = parseIdentifier().lowercased()
            skipWhitespaceAndNewlines()
            if current == ":" { advance(); skipWhitespaceAndNewlines() }
            if id == "width" { width = try parseCGFloat() }
            else if id == "height" { height = try parseCGFloat() }
            skipWhitespaceAndNewlines()
            if current == "," { advance() }
        }
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        let child = try parseView()
        skipWhitespaceAndNewlines()
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .frame(width: width, height: height, child: child)
    }
    
    private func parsePositioned() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        var x: CGFloat = 0, y: CGFloat = 0, width: CGFloat? = nil, height: CGFloat? = nil
        while index < input.endIndex, current != ")" {
            skipWhitespaceAndNewlines()
            let id = parseIdentifier().lowercased()
            skipWhitespaceAndNewlines()
            if current == ":" { advance(); skipWhitespaceAndNewlines() }
            if id == "x" { x = try parseCGFloat() }
            else if id == "y" { y = try parseCGFloat() }
            else if id == "width" { width = try parseCGFloat() }
            else if id == "height" { height = try parseCGFloat() }
            skipWhitespaceAndNewlines()
            if current == "," { advance() }
        }
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        let child = try parseView()
        skipWhitespaceAndNewlines()
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .positioned(x: x, y: y, width: width, height: height, child: child)
    }
    
    private func parseBackground() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let colorHex = try parseString()
        skipWhitespaceAndNewlines()
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        let child = try parseView()
        skipWhitespaceAndNewlines()
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .background(colorHex, child: child)
    }
    
    private func parseForeground() throws -> AlexandriaViewNode {
        skipWhitespaceAndNewlines()
        guard current == "(" else { throw AlexandriaParseError.expected("(") }
        advance()
        let colorHex = try parseString()
        skipWhitespaceAndNewlines()
        guard current == ")" else { throw AlexandriaParseError.expected(")") }
        advance()
        skipWhitespaceAndNewlines()
        guard current == "{" else { throw AlexandriaParseError.expected("{") }
        advance()
        let child = try parseView()
        skipWhitespaceAndNewlines()
        guard current == "}" else { throw AlexandriaParseError.expected("}") }
        advance()
        return .foreground(colorHex, child: child)
    }
}
