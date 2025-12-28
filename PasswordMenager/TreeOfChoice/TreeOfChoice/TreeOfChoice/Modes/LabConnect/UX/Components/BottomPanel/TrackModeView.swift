//
//  TrackModeView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Track mode - prikazuje track mode specifičan sadržaj
struct TrackModeView: View {
    @EnvironmentObject private var localization: LocalizationManager
    
    var body: some View {
        ZStack {
            // Pozadina
            Color.black.opacity(0.95)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 1.0, green: 0.36, blue: 0.0), lineWidth: 2)
                )
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "map.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.0))
                    
                    Text("Track Mode")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Content
                VStack(spacing: 12) {
                    Text("Track mode content will be displayed here.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    
                    // Placeholder za track mode funkcionalnosti
                    HStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.0))
                            Text("Track Location")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack(spacing: 8) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 40))
                                .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.0))
                            Text("History")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.0))
                            Text("Analytics")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
            }
        }
    }
}

