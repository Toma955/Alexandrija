//
//  ActiveSessionCard.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit

/// Kartica koja prikazuje jednu aktivnu sesiju
struct ActiveSessionCard: View {
    let session: SessionMetadata
    let onDelete: () -> Void
    let onOpen: () -> Void
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 12) {
            // Ikona
            if let icon = loadIcon(named: session.modeType.iconName) {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Naziv
            Text(session.name)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 36)
            
            // Delete botun na sredini
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Delete session")
            .highPriorityGesture(
                TapGesture().onEnded {
                    onDelete()
                }
            )
        }
        .frame(width: 140, height: 160)
        .padding(12)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onOpen()
        }
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private func loadIcon(named name: String) -> NSImage? {
        // Pokušaj učitati iz Shared/UX/Icons foldera
        if let imageURL = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Shared/UX/Icons") {
            if let image = NSImage(contentsOf: imageURL) {
                return image
            }
        }
        
        // Fallback: Pokušaj učitati direktno iz bundle-a
        if let imageURL = Bundle.main.url(forResource: name, withExtension: "png") {
            return NSImage(contentsOf: imageURL)
        }
        
        // Pokušaj učitati iz Assets.xcassets
        if let assetImage = NSImage(named: name) {
            return assetImage
        }
        
        return nil
    }
}

