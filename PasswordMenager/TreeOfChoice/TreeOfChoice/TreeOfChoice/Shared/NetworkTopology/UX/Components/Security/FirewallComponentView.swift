//
//  FirewallComponentView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// UX komponenta za Firewall
struct FirewallComponentView: View {
    @ObservedObject var component: NetworkComponent
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "shield")
                .font(.title2)
                .foregroundColor(.red)
            
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
                .stroke(Color.red.opacity(0.5), lineWidth: 2)
        )
    }
}








