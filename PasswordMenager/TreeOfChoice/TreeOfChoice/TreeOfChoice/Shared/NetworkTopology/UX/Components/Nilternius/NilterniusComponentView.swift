//
//  NilterniusComponentView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// UX komponenta za Nilternius server/gateway
struct NilterniusComponentView: View {
    @ObservedObject var component: NetworkComponent
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "lock.shield.fill")
                .font(.title2)
                .foregroundColor(accentOrange)
            
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
                .stroke(accentOrange, lineWidth: 2)
        )
    }
}









