//
//  BottomControlPanelElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit

/// Custom Shape za polukrug (gornji dio zaobljen, donji ravan)
/// Gornji dio je zaobljen kao polukrug, donji dio je ravan
struct SemicircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        // Radius je manji od width/2 i height kako bi se polukrug uklopio u okvir
        let radius = min(width / 2, height)
        
        // Počni od donjeg lijevog kuta
        path.move(to: CGPoint(x: 0, y: height))
        
        // Donja ravna linija (lijevo -> desno)
        path.addLine(to: CGPoint(x: width, y: height))
        
        // Desna vertikalna linija (dolje -> gore do početka polukruga)
        path.addLine(to: CGPoint(x: width, y: radius))
        
        // Gornji polukrug (desno -> lijevo) - centar je na sredini širine, na visini radius
        path.addArc(
            center: CGPoint(x: width / 2, y: radius),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        
        // Path se automatski zatvara jer smo se vratili na početnu točku
        path.closeSubpath()
        return path
    }
}

/// Element koji predstavlja Bottom Control Panel - upravljanje kontrolama na dnu LabConnect viewa
class BottomControlPanelElement: ObservableObject {
    @Published var isExpanded: Bool = false // Stanje animiranog botuna (collapsed/expanded)
    @Published var isGameMode: Bool = true // Game mode (true) ili Track mode (false)
    @Published var isEditMode: Bool = false {
        didSet {
            // Kada se aktivira Edit Mode, automatski expandiraj panel
            if isEditMode {
                // Postavi odmah bez animacije da se osigura da je vidljiv
                isExpanded = true
            }
        }
    }
    @Published var toggle1: Bool = false
    @Published var toggle2: Bool = false
    @Published var toggle3: Bool = false
    
    init() {
        // Initialize bottom control panel
    }
    
    func toggleExpanded() {
        // U Edit Mode-u, ne dozvoli collapse (osim ako se ne zatvara Edit Mode)
        if isEditMode {
            return
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isExpanded.toggle()
        }
    }
}

/// View wrapper za BottomControlPanelElement
struct BottomControlPanelView: View {
    @ObservedObject var bottomControlPanel: BottomControlPanelElement
    var canvasElement: CanvasElement? // Optional pristup topologiji za dodavanje komponenti
    @EnvironmentObject private var localization: LocalizationManager
    @State private var isHovered: Bool = false
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    init(bottomControlPanel: BottomControlPanelElement, canvasElement: CanvasElement? = nil) {
        self.bottomControlPanel = bottomControlPanel
        self.canvasElement = canvasElement
    }
    
    var body: some View {
        // Animirani narančasti botun na dnu koji se pretvara u veći kvadrat s kontrolama
        ZStack {
            // Mode view-ovi - iza control panela (uvijek vidljivi)
            // Prikaži odgovarajući view ovisno o isGameMode
            Group {
                if bottomControlPanel.isGameMode {
                    GameModeView(canvasElement: canvasElement)
                        .id("gameMode") // ID za pravilnu animaciju
                } else {
                    TrackModeView(isEditMode: $bottomControlPanel.isEditMode, canvasElement: canvasElement)
                        .id("trackMode") // ID za pravilnu animaciju
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(1) // Ispod control panela
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            // Control panel na dnu - 10px od dna ekrana
            VStack {
                Spacer()
                animatedOrangeButton
                    .offset(y: 15) // Pomakni prema dolje (u minus u odnosu na kvadrat)
            }
            .ignoresSafeArea(.all, edges: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(10) // Iznad mode view-ova
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: bottomControlPanel.isGameMode)
    }
    
    // MARK: - Animated Orange Button
    
    private var animatedOrangeButton: some View {
        ZStack {
            // Background - mali obli kvadrat koji raste u polukrug kada je expanded
            // Button se aktivira samo kada je collapsed - kada je expanded, ne smije se zatvoriti osim preko collapse botuna
            if !bottomControlPanel.isExpanded {
                Button(action: {
                    isHovered = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        bottomControlPanel.toggleExpanded()
                    }
                }) {
                    // Mali obli element kada je collapsed
                    Capsule()
                        .fill(accentOrange)
                        .frame(
                            width: isHovered ? 70 : 60,
                            height: isHovered ? 12 : 10
                        )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
            } else {
                // Kada je expanded, samo prikaži pozadinu bez button akcije
                RoundedRectangle(cornerRadius: 30) // Prilagođen corner radius
                    .fill(accentOrange)
                    .frame(width: 320, height: 60) // Smanjena visina da bude samo malo veći
            }
            
            // Kontrole unutar expanded kvadrata
            if bottomControlPanel.isExpanded {
                expandedControls
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: bottomControlPanel.isExpanded)
        .onContinuousHover { phase in
            if !bottomControlPanel.isExpanded {
                switch phase {
                case .active:
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovered = true
                    }
                case .ended:
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovered = false
                    }
                }
            } else {
                isHovered = false
            }
        }
        .onChange(of: bottomControlPanel.isExpanded) { newValue in
            // Reset hover kada se panel proširi
            if newValue {
                isHovered = false
            }
        }
    }
    
    // MARK: - Expanded Controls
    
    private var expandedControls: some View {
        // Sve u jednom redu: Toggle switch + 4 kvadratna botuna
        HStack(spacing: 16) { // Smanjen spacing jer je sve kompaktnije
            // Custom Toggle switch s 2 ikone unutra (bijele ikone)
            ZStack {
                // Pozadina toggle switcha - polukrug (capsule), maksimalno zaobljeni rubovi, malo veći
                Capsule()
                    .fill(accentOrange)
                    .frame(width: 42, height: 36) // Povećano da elegantno stane veća ikona
                
                // Ikone IZNAD crnog kruga - bijele i veće
                HStack(spacing: 8) { // Povećan spacing za razdvajanje
                    // Game mode ikona (lijevo) - udaljena i povećana
                    ZStack {
                        // Crni krug koji se pomiče - mora biti u centru ikone kada je game mode
                        if bottomControlPanel.isGameMode {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 38, height: 38) // Povećano s 34 na 38
                                .zIndex(0) // Ispod ikone
                        }
                        
                        // Gamepad ikona - bijela s maskom, povećana
                        if let nsImage = loadIcon(named: "gamepad") {
                            Color.white
                                .mask(
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 58, height: 58) // Povećano s 50 na 58
                                )
                                .frame(width: 58, height: 58)
                                .zIndex(1) // Iznad crnog kruga
                        } else {
                            Image(systemName: "gamecontroller.fill")
                                .font(.title) // Povećano s title2 na title
                                .foregroundColor(.white)
                                .zIndex(1)
                        }
                    }
                    .frame(width: 30, height: 40) // Povećano frame za veću ikonu
                    .offset(x: -20) // Pomaknuto 20px lijevo
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !bottomControlPanel.isGameMode {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                bottomControlPanel.isGameMode = true
                            }
                        }
                    }
                    
                    // Track mode ikona (desno)
                    ZStack {
                        // Crni krug koji se pomiče - mora biti u centru ikone kada je track mode
                        if !bottomControlPanel.isGameMode {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 38, height: 38) // Povećano s 34 na 38
                                .zIndex(0) // Ispod ikone
                        }
                        
                        // Tracks ikona - bijela s maskom
                        if let nsImage = loadIcon(named: "Tracks") {
                            Color.white
                                .mask(
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28) // Smanjeno s 38 na 28 da stane u krug
                                )
                                .frame(width: 28, height: 28)
                                .zIndex(1) // Iznad crnog kruga
                        } else {
                            Image(systemName: "map.fill")
                                .font(.caption2) // Smanjeno s caption na caption2
                                .foregroundColor(.white)
                                .zIndex(1)
                        }
                    }
                    .frame(width: 20, height: 30) // Smanjeno proporcionalno
                    .padding(.trailing, 4) // Razdvojeno malo desno
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if bottomControlPanel.isGameMode {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                bottomControlPanel.isGameMode = false
                            }
                        }
                    }
                }
            }
            
            // 4 Botuna - svi 30x30
            // Button 1 - Edit (crni krug, veća ikona)
            Button(action: {
                // Edit mode samo u Track mode-u
                if !bottomControlPanel.isGameMode {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        bottomControlPanel.isEditMode.toggle()
                    }
                }
            }) {
                Image(systemName: "pencil")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // Button 2 - Collapse (crni krug, veća ikona, premještena funkcija)
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    bottomControlPanel.toggleExpanded()
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // Button 3 - Play by step (crni krug, bijela ikona)
            Button(action: {
                // TODO: Implement Play by step action
            }) {
                Image(systemName: "play.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // Button 4 - One step (crni krug, bijela ikona)
            Button(action: {
                // TODO: Implement One step action
            }) {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12) // Povećan horizontalni padding
        .padding(.vertical, 8) // Povećan vertikalni padding za elegantniji izgled
    }
    
    // MARK: - Helper
    
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

