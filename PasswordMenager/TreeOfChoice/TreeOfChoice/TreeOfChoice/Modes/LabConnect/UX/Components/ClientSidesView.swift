//
//  ClientSidesView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ClientSidesView: View {
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: 0) {
            // Side A (left) - wider
            VStack(spacing: 8) {
                Text("Client A")
                    .font(.headline.bold())
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                
                Spacer()
            }
            .frame(width: 110)
            .frame(maxHeight: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
            .contentShape(Rectangle())
            
            // Middle area for topology - takes remaining space
            Spacer()
            
            // Side B (right) - wider
            VStack(spacing: 8) {
                Text("Client B")
                    .font(.headline.bold())
                    .foregroundColor(.green)
                    .padding(.top, 8)
                
                Spacer()
            }
            .frame(width: 110)
            .frame(maxHeight: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
            .contentShape(Rectangle())
        }
    }
}

