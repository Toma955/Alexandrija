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
                gameModeContent(topology: topology)
            } else {
                emptyState
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func gameModeContent(topology: NetworkTopology) -> some View {
        GameModeContentView(topology: topology)
    }
    
    private var emptyState: some View {
        ZStack {
            // Pozadina - originalne dimenzije
            Color.black.opacity(0.95)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 1.0, green: 0.36, blue: 0.0), lineWidth: 2)
                )
            
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
    
    var body: some View {
        ZStack {
            // Pozadina - originalne dimenzije
            Color.black.opacity(0.95)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 1.0, green: 0.36, blue: 0.0), lineWidth: 2)
                )
            
            // Horizontalni scroll s elementima
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 16) {
                    let elements = topology.components.filter { component in
                        component.isClientA != true && component.isClientB != true
                    }
                    
                    // Spacer na početku da elementi počnu od sredine
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
                                        // Može se dodati akcija za uklanjanje
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    
                    // Spacer na kraju
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4) // Minimalni padding vertikalno da elementi se protežu prema gore i dolje
                .frame(minHeight: 0) // Omogući proširenje
            }
            .frame(maxHeight: .infinity) // Omogući proširenje prema gore i dolje
        }
    }
    
    private var emptyState: some View {
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
