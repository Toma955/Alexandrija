//
//  IconElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Element koji predstavlja ikonu komponente
/// Odgovoran za prikaz ikone i njezine interakcije
class IconElement: ObservableObject {
    @Published var componentType: NetworkComponent.ComponentType
    @Published var isSelected: Bool = false
    @Published var isDragging: Bool = false
    
    let id = UUID()
    
    init(componentType: NetworkComponent.ComponentType) {
        self.componentType = componentType
    }
    
    func select() {
        isSelected = true
    }
    
    func deselect() {
        isSelected = false
    }
    
    func startDragging() {
        isDragging = true
    }
    
    func stopDragging() {
        isDragging = false
    }
}

/// View wrapper za IconElement
struct IconElementView: View {
    @ObservedObject var iconElement: IconElement
    let onTap: () -> Void
    let onDragStart: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: ComponentIconHelper.icon(for: iconElement.componentType))
                .font(.title2)
                .foregroundColor(ComponentColorHelper.color(for: iconElement.componentType))
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconElement.isSelected ? Color.blue.opacity(0.3) : Color.clear)
                )
            
            Text(iconElement.componentType.displayName)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(iconElement.isDragging ? Color.white.opacity(0.1) : Color.black.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(iconElement.isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { _ in
                    if !iconElement.isDragging {
                        iconElement.startDragging()
                        onDragStart()
                    }
                }
                .onEnded { _ in
                    iconElement.stopDragging()
                }
        )
    }
}


