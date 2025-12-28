//
//  ClientTopologyView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Topology komponentu u Client panelu
struct ClientTopologyView: View {
    @Binding var isPresented: Bool
    let clientName: String // "Client A" ili "Client B"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("\(clientName) - Topology")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Topology Information")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Network topology details for \(clientName)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    // TODO: Add topology-specific content here
                }
                .padding()
            }
            
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.95))
        .cornerRadius(12)
    }
}

