// App/SharedUX/Components/ModeCard.swift
import SwiftUI
import AppKit

struct ModeCard: View {
    let title: String
    let description: String
    let buttonTitle: String
    let iconName: String?
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // Ikona umjesto teksta - centrirana gore
            if let iconName = iconName, let icon = loadIcon(named: iconName) {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
            } else {
                // Fallback ako ikona ne postoji
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(height: 120)
            }

            Spacer()

            // Botun centriran dolje
            Text(buttonTitle)
                .font(.headline.bold())
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(accentColor.opacity(0.9))
                .cornerRadius(14)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    action()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .frame(height: 230)
        .background(
            Color.black.opacity(0.80)       // tamno "staklo"
        )
        .cornerRadius(20)
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
