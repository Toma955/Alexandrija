//
//  CanvasElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

// PreferenceKey za poziciju linije
struct LinePositionKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Element koji predstavlja canvas (pozor) - sadrži topologiju i palette
/// Odgovoran za koordinaciju između različitih elemenata na canvasu
class CanvasElement: ObservableObject {
    @Published var topologyViewElement: TopologyViewElement
    @Published var showComponentPalette: Bool = true
    @Published var draggedComponent: NetworkComponent?
    @Published var isTestMode: Bool = false // Test mode - fiksira elemente i mijenja izgled
    
    init() {
        self.topologyViewElement = TopologyViewElement()
    }
    
    func deleteAllTopology() {
        topologyViewElement.deleteAllTopology()
    }
    
    func toggleTestMode() {
        isTestMode.toggle()
    }
    
    @MainActor
    func deleteAllConnections() {
        topologyViewElement.topologyElement.deleteAllConnections()
        objectWillChange.send()
    }
}

/// View wrapper za CanvasElement
struct CanvasElementView: View {
    @ObservedObject var canvasElement: CanvasElement
    @EnvironmentObject private var localization: LocalizationManager
    @State private var lineYPosition: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 20) { // 20px razmak između palette i topologije
            // Component Palette above canvas - automatska visina
            if canvasElement.showComponentPalette {
                ComponentPaletteView(
                    draggedComponent: $canvasElement.draggedComponent,
                    isTestMode: canvasElement.isTestMode
                )
                .padding(.leading, 5) // 5px od lijeve bijele linije
                .padding(.trailing, 5) // 5px od desne bijele linije
            }
            
            // Topology frame - 55% of screen height, full width
            GeometryReader { screenGeometry in
                let frameHeight = screenGeometry.size.height * 0.55
                
                VStack(spacing: 0) {
                    // Topology frame with visible border
                    ZStack {
                        // Background
                        Color.black.opacity(0.3)
                        
                        // Topology view inside frame
                        GeometryReader { frameGeometry in
                            TopologyViewElementView(
                                topologyViewElement: canvasElement.topologyViewElement,
                                geometry: frameGeometry,
                                isTestMode: canvasElement.isTestMode
                            )
                        }
                    }
                    .frame(width: screenGeometry.size.width - 10, height: frameHeight) // -10 za padding lijevo/desno
                    .overlay(
                        // Visible border
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                    .cornerRadius(8)
                    .padding(.leading, 5) // 5px od lijeve bijele linije
                    .padding(.trailing, 5) // 5px od desne bijele linije
                    
                    // Bijela linija ispod topologije (samo za tracking pozicije)
                    Color.clear
                        .frame(height: 1)
                        .padding(.top, 10)
                        .background(
                            GeometryReader { lineGeometry in
                                Color.clear
                                    .preference(key: LinePositionKey.self, value: lineGeometry.frame(in: .global).minY + 0.5)
                            }
                        )
                    
                    Spacer()
                }
            }
        }
        .background(Color.black.opacity(0.2))
        .onPreferenceChange(LinePositionKey.self) { value in
            lineYPosition = value
        }
        .sheet(isPresented: $canvasElement.topologyViewElement.showComponentDetail) {
            if let component = canvasElement.topologyViewElement.selectedComponent {
                ComponentDetailView(
                    component: component,
                    topology: canvasElement.topologyViewElement.topologyElement.topology,
                    isPresented: $canvasElement.topologyViewElement.showComponentDetail
                )
                .environmentObject(localization)
            }
        }
    }
}

