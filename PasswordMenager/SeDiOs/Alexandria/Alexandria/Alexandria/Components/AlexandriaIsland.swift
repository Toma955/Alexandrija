//
//  AlexandriaIsland.swift
//  Alexandria
//
//  Crni obli kvadrat s narančastim obrubom – sve unutra.
//

import SwiftUI

struct AlexandriaIsland: View {
    @AppStorage("islandTitle") private var islandTitle: String = "Alexandria"
    @State private var isExpandedPhase1 = false
    @State private var showSettings = false
    @State private var showAppLibrary = false

    private let accentColor = Color(hex: "ff5c00")
    var onOpenSearch: (() -> Void)?
    var onOpenNewTab: (() -> Void)?

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .overlay(alignment: .top) {
                AlexandriaIslandContent(
                    islandTitle: islandTitle,
                    isExpandedPhase1: $isExpandedPhase1,
                    accentColor: accentColor,
                    onOpenSettings: { showSettings = true },
                    onOpenAppLibrary: { showAppLibrary = true },
                    onOpenSearch: onOpenSearch,
                    onOpenNewTab: onOpenNewTab
                )
            }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showAppLibrary) {
            AppLibraryView()
        }
    }
}

// MARK: - Island Content (s hover i expand logikom)
struct AlexandriaIslandContent: View {
    let islandTitle: String
    @Binding var isExpandedPhase1: Bool
    let accentColor: Color
    var onOpenSettings: (() -> Void)?
    var onOpenAppLibrary: (() -> Void)?
    var onOpenSearch: (() -> Void)?
    var onOpenNewTab: (() -> Void)?
    
    private var isExpanded: Bool { isExpandedPhase1 }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(isExpanded ? 24 : 8)
        .frame(width: isExpanded ? 520 : 180, height: isExpanded ? nil : 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(accentColor, lineWidth: 2)
                )
        )
        .contentShape(Rectangle())
        .padding(.horizontal, 80)
        .padding(.vertical, 1)
        .onHover { hovering in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpandedPhase1 = hovering
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(spacing: isExpanded ? 16 : 0) {
            // Natpis – uvijek u sredini Islanda, ne miče se
            Text(islandTitle)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(accentColor)
                .frame(height: 22)
                .frame(maxWidth: .infinity)
            
            if isExpandedPhase1 {
                phase1Buttons
            }
        }
    }
    
    private var phase1Buttons: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .overlay(
                HStack(spacing: 8) {
                    IslandPhase1Button(icon: "gearshape.fill", label: "Postavke", accentColor: accentColor, action: onOpenSettings)
                    IslandPhase1Button(icon: "square.grid.2x2", label: "Aplikacije", accentColor: accentColor, action: onOpenAppLibrary)
                    IslandPhase1Button(icon: "plus.circle.fill", label: "Novi tab", accentColor: accentColor, action: onOpenNewTab)
                    IslandPhase1Button(icon: "star.fill", label: "Omiljeno", accentColor: accentColor)
                    IslandPhase1Button(icon: "magnifyingglass", label: "Pretraživanje", accentColor: accentColor, action: onOpenSearch)
                }
            )
    }
}

// MARK: - Island Phase 1 Button (manje ikone)
struct IslandPhase1Button: View {
    let icon: String
    let label: String
    let accentColor: Color
    var action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(accentColor)
            .frame(minWidth: 44)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Island Bottom Button
struct IslandBottomButton: View {
    let icon: String
    let label: String
    let accentColor: Color
    var action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}
