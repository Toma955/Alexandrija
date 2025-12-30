//
//  GameModeElementView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za prikaz jednog elementa u Game Mode-u (kvadrat s crnom pozadinom, narančastim rubovima, ikonom i nazivom)
struct GameModeElementView: View {
    let component: NetworkComponent
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                // Botun za "više"
                Button(action: {
                    // TODO: Implement action za "više"
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accentOrange)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            .padding(.trailing, 8)
            
            Spacer()
            
            // Ikona elementa
            iconView
                .frame(width: 40, height: 40)
            
            // Naziv elementa
            Text(component.name)
                .font(.caption)
                .foregroundColor(accentOrange)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 120)
            
            Spacer()
        }
        .frame(width: 150)
        .frame(maxHeight: .infinity) // Širi i proteže se prema gore i dolje
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.15))
        )
    }
    
    @ViewBuilder
    private var iconView: some View {
        // Provjeri ima li custom ikonu
        if ComponentIconHelper.hasCustomIcon(for: component.componentType),
           let customIconName = ComponentIconHelper.customIconName(for: component.componentType),
           let customImage = ComponentIconHelper.loadCustomIcon(named: customIconName) {
            // Custom icon
            Image(nsImage: customImage)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(accentOrange)
        } else {
            // SF Symbol icon
            Image(systemName: ComponentIconHelper.icon(for: component.componentType))
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(accentOrange)
        }
    }
}

