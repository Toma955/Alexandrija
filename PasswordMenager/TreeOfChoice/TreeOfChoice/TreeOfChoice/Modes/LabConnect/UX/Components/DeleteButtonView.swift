//
//  DeleteButtonView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct DeleteButtonView: View {
    @Binding var isDraggingOver: Bool
    let isDragging: Bool
    
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "trash.fill")
                    .font(.title)
                    .foregroundColor(.white)
            )
            .scaleEffect(isDraggingOver ? 1.2 : 1.0)
            .opacity(isDragging ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
            .animation(.easeInOut(duration: 0.2), value: isDraggingOver)
    }
}

