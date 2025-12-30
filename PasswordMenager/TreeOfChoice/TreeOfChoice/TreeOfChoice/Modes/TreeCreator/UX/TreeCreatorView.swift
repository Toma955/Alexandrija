//
//  TreeCreatorView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Tree Creator mod - kreiranje i uređivanje binarnih stabala odluke
struct TreeCreatorView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @State private var showCreateTreeDialog = false
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        ZStack {
            // Pozadina
            Color.black.opacity(0.95)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content
                mainContentView
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .overlay {
            if showCreateTreeDialog {
                CreateTreeDialog(isPresented: $showCreateTreeDialog)
                    .environmentObject(localization)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.text("treeCreator.title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(localization.text("treeCreator.homeDescription"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(24)
        .background(Color.black.opacity(0.6))
    }
    
    private var mainContentView: some View {
        ZStack {
            // Veliki plus botun u centru
            Button(action: {
                showCreateTreeDialog = true
            }) {
                ZStack {
                    Circle()
                        .fill(accentOrange)
                        .frame(width: 120, height: 120)
                        .shadow(color: accentOrange.opacity(0.5), radius: 20, x: 0, y: 0)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(showCreateTreeDialog ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showCreateTreeDialog)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

