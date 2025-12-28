//
//  ClientUserView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za User komponentu u Client panelu
struct ClientUserView: View {
    @Binding var isPresented: Bool
    let clientName: String // "Client A" ili "Client B"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("\(clientName) - User")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                    // Provjeri treba li vratiti panel u collapsed stanje
                    // Ovo će se pozvati kroz binding, ali možemo dodati delay
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
                    Text("User Information")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("User component details for \(clientName)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    // TODO: Add user-specific content here
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

