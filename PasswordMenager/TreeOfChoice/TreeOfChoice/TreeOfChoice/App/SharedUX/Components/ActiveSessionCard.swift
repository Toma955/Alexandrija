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
            
            // Botuni
            HStack(spacing: 8) {
                // Delete botun
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Delete session")
                
                // Open botun
                Button(action: onOpen) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(accentOrange)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Open session")
            }
        }
        .frame(width: 140, height: 160)
        .padding(12)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
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

