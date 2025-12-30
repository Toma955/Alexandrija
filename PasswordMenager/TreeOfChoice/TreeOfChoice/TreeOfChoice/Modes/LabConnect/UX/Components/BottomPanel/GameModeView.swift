//
//  GameModeView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Game mode - prikazuje game mode specifičan sadržaj
struct GameModeView: View {
    @EnvironmentObject private var localization: LocalizationManager
    var canvasElement: CanvasElement? // Optional pristup topologiji
    
    var body: some View {
        Group {
            if let canvasElement = canvasElement {
                let topology = canvasElement.topologyViewElement.topologyElement.topology
                gameModeContent(topology: topology, canvasElement: canvasElement)
            } else {
                emptyState
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func gameModeContent(topology: NetworkTopology, canvasElement: CanvasElement) -> some View {
        GameModeContentView(topology: topology, canvasElement: canvasElement)
    }
    
    private var emptyState: some View {
        ZStack {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.3))
                Text("No elements")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - GameModeContentView

/// Helper view koji koristi @ObservedObject za automatsko ažuriranje
private struct GameModeContentView: View {
    @ObservedObject var topology: NetworkTopology
    var canvasElement: CanvasElement
    @State private var draggedComponent: NetworkComponent?
    
    var body: some View {
        ZStack {
            // Horizontalni scroll s elementima - centrirano
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 16) {
                        let elements = topology.components.filter { component in
                            component.isClientA != true && component.isClientB != true
                        }
                        
                        // Spacer na početku za centriranje
                        Spacer()
                        
                        if elements.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.circle.dashed")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.3))
                                Text("No elements")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(minWidth: 200)
                            .padding(.vertical, 40)
                        } else {
                            // Prikaži elemente iz topologije horizontalno
                            ForEach(elements) { component in
                                GameModeElementView(component: component)
                                    .onTapGesture {
                                        // Može se dodati akcija za klik
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            // Ukloni komponentu iz topologije
                                            canvasElement.topologyViewElement.deleteComponent(component)
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        
                        // Spacer na kraju za centriranje
                        Spacer()
                    }
                    .frame(minWidth: geometry.size.width) // Osiguraj da HStack zauzima punu širinu
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4) // Minimalni padding vertikalno da elementi se protežu prema gore i dolje
                }
            }
            .frame(maxHeight: .infinity) // Omogući proširenje prema gore i dolje
        }
    }
}
