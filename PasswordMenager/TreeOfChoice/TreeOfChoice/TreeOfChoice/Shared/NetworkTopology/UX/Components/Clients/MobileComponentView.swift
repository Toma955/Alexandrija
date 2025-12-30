//
//  MobileComponentView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// UX komponenta za Mobile uređaj
struct MobileComponentView: View {
    @ObservedObject var component: NetworkComponent
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "iphone")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(component.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(8)
        .frame(width: 80, height: 80)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 2)
        )
    }
    
    private var borderColor: Color {
        if component.isClientA == true {
            return .blue
        } else if component.isClientB == true {
            return .green
        }
        return Color.white.opacity(0.3)
    }
}
















