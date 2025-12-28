//
//  TrackModeView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Track mode - prikazuje track mode specifičan sadržaj
/// U Edit mode-u se prikazuje kao prozor iznad control panela
struct TrackModeView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isEditMode: Bool
    
    init(isEditMode: Binding<Bool> = .constant(false)) {
        self._isEditMode = isEditMode
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar - narančasti kvadrat s close, upload i save
            topBar
            
            // Main content - dva kvadrata s paddingom
            HStack(spacing: 12) {
                // Mali kvadrat od vrha do dna (lijevo)
                leftPanel
                
                // Veliki kvadrat koji zauzima većinu ekrana (desno)
                rightPanel
            }
            .padding(12) // Padding od ruba
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Narančasti zaobljeni kvadrat s crvenim krugom i X
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isEditMode = false
                }
            }) {
                ZStack {
                    // Narančasti zaobljeni kvadrat
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 1.0, green: 0.36, blue: 0.0))
                        .frame(width: 32, height: 32)
                    
                    // Crveni krug s X
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Upload button
            Button(action: {
                // TODO: Implement Upload action
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                    Text("Upload")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 1.0, green: 0.36, blue: 0.0))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            // Save button
            Button(action: {
                // TODO: Implement Save action
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.caption)
                    Text("Save")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 1.0, green: 0.36, blue: 0.0))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Left Panel (mali kvadrat)
    
    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Prazan prostor na vrhu (za alignment s timeline-om)
            Rectangle()
                .fill(Color.clear)
                .frame(height: 40) // Ista visina kao timeline header
            
            // Scrollable content area s track poljima
            ScrollView {
                VStack(spacing: 0) {
                    // Vertikalno raspoređena horizontalna polja (tracks)
                    ForEach(0..<20) { index in
                        LeftTrackFieldView(index: index)
                            .frame(height: 50) // Visina svakog track polja
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        )
        .frame(width: 200) // Fiksna širina za mali kvadrat
    }
    
    // MARK: - Right Panel (veliki kvadrat)
    
    private var rightPanel: some View {
        VStack(spacing: 0) {
            // Timeline na vrhu s brojevima
            timelineHeader
            
            // Scrollable content area s track poljima (vertikalno i horizontalno)
            ZStack {
                ScrollView {
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Vertikalno raspoređena horizontalna polja (tracks)
                            ForEach(0..<20) { index in
                                TrackFieldView(index: index)
                                    .frame(height: 50) // Visina svakog track polja
                                    .frame(minWidth: 2000) // Minimalna širina za horizontalni scroll
                            }
                        }
                    }
                }
                
                // Crvena linija na poziciji 0 kroz track polja
                HStack {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                    
                    Spacer()
                }
                .padding(.leading, 8) // Padding odgovara padding-u u timeline headeru
            }
            
            // Horizontalni slider na dnu
            horizontalSlider
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity) // Zauzima preostali prostor
    }
    
    // MARK: - Horizontal Slider
    
    private var horizontalSlider: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.3))
            
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 0) {
                    // Prazan prostor - slider je na maksimumu jer je prazan
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 2000) // Širina koja odgovara track poljima
                }
            }
            .frame(height: 20) // Visina slidera
        }
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Timeline Header
    
    private var timelineHeader: some View {
        VStack(spacing: 0) {
            // Horizontalna linija s brojevima
            ZStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // Brojevi na timeline-u (kao u audio editoru) - prošireno do 200
                        ForEach(0..<200) { index in
                            VStack(spacing: 0) {
                                // Glavni marker (svaki 10. broj)
                                if index % 10 == 0 {
                                    Text("\(index)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 60)
                                        .padding(.top, 4)
                                } else if index % 5 == 0 {
                                    // Srednji marker (svaki 5. broj)
                                    Text("\(index)")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(width: 30)
                                        .padding(.top, 4)
                                }
                                
                                // Vertikalna linija
                                Rectangle()
                                    .fill(index % 10 == 0 ? Color.white.opacity(0.6) : 
                                          index % 5 == 0 ? Color.white.opacity(0.4) : 
                                          Color.white.opacity(0.2))
                                    .frame(width: index % 10 == 0 ? 2 : 
                                           index % 5 == 0 ? 1 : 0.5)
                                    .frame(height: index % 10 == 0 ? 20 : 
                                           index % 5 == 0 ? 15 : 10)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                
                // Crvena linija na poziciji 0
                HStack {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                    
                    Spacer()
                }
                .padding(.leading, 8) // Padding odgovara padding-u u HStack-u
            }
            .frame(height: 40) // Visina timeline headera
            
            // Horizontalna linija ispod brojeva
            Divider()
                .background(Color.white.opacity(0.3))
        }
        .background(Color.black.opacity(0.4))
    }
}

// MARK: - Track Field View

/// View za pojedino track polje u desnom panelu - horizontalno polje sa sivo-crnom bojom
struct TrackFieldView: View {
    let index: Int
    
    // Naizmjenično bojanje: parni index = crno, neparni = sivo
    private var isDark: Bool {
        index % 2 == 0
    }
    
    var body: some View {
        // Glavno track polje - naizmjenično crno/sivo
        Rectangle()
            .fill(
                isDark ? 
                // Crno
                LinearGradient(
                    colors: [
                        Color(white: 0.05), // Crno
                        Color(white: 0.02)  // Tamnije crno
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                // Sivo
                LinearGradient(
                    colors: [
                        Color(white: 0.15), // Sivo-crna
                        Color(white: 0.12)  // Tamnija sivo-crna
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 50)
            .overlay(
                // Gornja linija za razdvajanje trackova
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            )
    }
}

/// View za pojedino track polje u lijevom panelu - samo horizontalno polje sa sivo-crnom bojom
struct LeftTrackFieldView: View {
    let index: Int
    
    // Naizmjenično bojanje: parni index = crno, neparni = sivo
    private var isDark: Bool {
        index % 2 == 0
    }
    
    var body: some View {
        // Glavno track polje - naizmjenično crno/sivo, bez brojeva
        Rectangle()
            .fill(
                isDark ? 
                // Crno
                LinearGradient(
                    colors: [
                        Color(white: 0.05), // Crno
                        Color(white: 0.02)  // Tamnije crno
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                // Sivo
                LinearGradient(
                    colors: [
                        Color(white: 0.15), // Sivo-crna
                        Color(white: 0.12)  // Tamnija sivo-crna
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 50)
            .overlay(
                // Gornja linija za razdvajanje trackova
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            )
    }
}

