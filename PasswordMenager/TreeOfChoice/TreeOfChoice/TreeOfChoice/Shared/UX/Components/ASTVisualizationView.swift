//
//  ASTVisualizationView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Vizualizacija AST strukture Python koda
struct ASTVisualizationView: View {
    let astNode: ASTNode?
    let localization: LocalizationManager
    
    var body: some View {
        ScrollView {
            if let node = astNode {
                ASTNodeView(node: node, level: 0)
                    .padding(16)
            } else {
                Text(localization.text("python.astNotAvailable"))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ASTNodeView: View {
    let node: ASTNode
    let level: Int
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if !node.children.isEmpty {
                    Button(action: {
                        isExpanded.toggle()
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                        .frame(width: 16)
                }
                
                // Node type badge
                Text(node.type)
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(colorForType(node.type))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForType(node.type).opacity(0.2))
                    .cornerRadius(4)
                
                // Node name
                if let name = node.name {
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                // Line number
                if let lineNumber = node.lineNumber {
                    Text("(line \(lineNumber))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, CGFloat(level * 16) + 8)
            .background(Color.white.opacity(level % 2 == 0 ? 0.05 : 0.02))
            .cornerRadius(4)
            
            // Children
            if isExpanded && !node.children.isEmpty {
                ForEach(Array(node.children.enumerated()), id: \.offset) { _, child in
                    ASTNodeView(node: child, level: level + 1)
                }
            }
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "functiondef", "function":
            return .green
        case "classdef", "class":
            return .blue
        case "import", "importfrom":
            return .orange
        case "if", "ifexp":
            return .purple
        case "for", "while":
            return .pink
        case "return":
            return .red
        default:
            return .gray
        }
    }
}

