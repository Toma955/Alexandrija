//
//  RealConnectView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Real Connect mod - treniranje Connection agenta na stvarnim uvjetima
struct RealConnectView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    @State private var selectedMode: ConnectionMode? = nil
    
    enum ConnectionMode {
        case multiConnected
        case singleConnected
        case importMode
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
            
            if selectedMode == nil {
                // Početni izbornik
                modeSelectionView
            } else {
                // Odabrani mod (za sada prazan)
                selectedModeView
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
    }
    
    // MARK: - Mode Selection View
    
    private var modeSelectionView: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Spacer()
            
            // 3 botuna u obrnutom redoslijedu
            VStack(spacing: 24) {
                // Multi Connected (prvi)
                modeButton(
                    title: "Multi Connected",
                    icon: "network",
                    description: "Poveži se s više uređaja",
                    color: Color(red: 0.2, green: 0.85, blue: 0.45)
                ) {
                    selectedMode = .multiConnected
                }
                
                // Single Connected (drugi)
                modeButton(
                    title: "Single Connected",
                    icon: "link",
                    description: "Poveži se s jednim uređajem",
                    color: Color(red: 0.0, green: 0.6, blue: 1.0)
                ) {
                    selectedMode = .singleConnected
                }
                
                // Uvezi (treći)
                modeButton(
                    title: "Uvezi",
                    icon: "square.and.arrow.down",
                    description: "Uvezi postojeću konfiguraciju",
                    color: accentOrange
                ) {
                    selectedMode = .importMode
                }
            }
            .padding(.horizontal, 120)
            
            Spacer()
        }
    }
    
    private func modeButton(
        title: String,
        icon: String,
        description: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Ikona
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(color)
                }
                
                // Tekst
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Strelica
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.text("mode.realConnect.title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(localization.text("mode.realConnect.description"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            if selectedMode != nil {
                Button(action: {
                    selectedMode = nil
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.6))
    }
    
    // MARK: - Selected Mode View
    
    private var selectedModeView: some View {
        VStack(spacing: 0) {
            headerView
            
            // Prikaži odgovarajući view ovisno o odabranom modu
            Group {
                switch selectedMode {
                case .multiConnected:
                    MultiConnectedView()
                case .singleConnected:
                    SingleConnectedView()
                case .importMode:
                    ImportView()
                case .none:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
