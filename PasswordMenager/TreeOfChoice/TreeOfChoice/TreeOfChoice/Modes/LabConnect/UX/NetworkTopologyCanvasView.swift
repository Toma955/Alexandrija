//
//  NetworkTopologyCanvasView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Glavni view za radnu površinu mrežne topologije
/// Koristi CanvasElement koji koordinira sve elemente prema OOP principima
struct NetworkTopologyCanvasView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @StateObject private var canvasElement = CanvasElement()
    @State private var showExportImport = false
    
    var body: some View {
        CanvasElementView(canvasElement: canvasElement)
            .environmentObject(localization)
            .sheet(isPresented: $showExportImport) {
                ExportImportView(
                    topology: canvasElement.topologyViewElement.topologyElement.topology,
                    isPresented: $showExportImport
                )
                .environmentObject(localization)
            }
            .onAppear {
                canvasElement.topologyViewElement.updateSimulation()
            }
    }
}
