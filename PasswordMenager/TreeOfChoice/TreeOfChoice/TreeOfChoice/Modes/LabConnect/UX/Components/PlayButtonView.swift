//
//  PlayButtonView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct PlayButtonView: View {
    @ObservedObject var simulation: NetworkSimulation
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: simulation.isRunning ? "stop.fill" : "play.fill")
                    .font(.title2)
                Text(simulation.isRunning ? "Stop" : "Play")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(simulation.isRunning ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

