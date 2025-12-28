//
//  ClientControlPanelElement.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// Element koji predstavlja Client Control Panel - upravljanje kontrolama u Client A i Client B kvadratima
class ClientControlPanelElement: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published var isMinimized: Bool = false
    @Published var showLogs: Bool = false
    @Published var showUser: Bool = false
    @Published var showTopology: Bool = false
    @Published var showExclamation: Bool = false
    @Published var isHomeView: Bool = true // true = Client Home view, false = Client Business mode
    
    init() {
        // Initialize client control panel
    }
    
    func toggleExpanded() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isExpanded.toggle()
        }
    }
    
    // Provjeri je li neki view otvoren
    var hasOpenView: Bool {
        showUser || showTopology || showLogs || showExclamation
    }
    
    // Kada se view zatvori, provjeri treba li vratiti panel u collapsed stanje
    func checkAndCollapseIfNeeded() {
        if !hasOpenView && isExpanded {
            // Ako nema otvorenih view-ova, vrati panel u collapsed stanje
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if !self.hasOpenView {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        self.isExpanded = false
                    }
                }
            }
        }
    }
    
    // Zatvori sve view-ove
    func closeAllViews() {
        showUser = false
        showTopology = false
        showLogs = false
        showExclamation = false
    }
    
    func toggleMinimized() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isMinimized.toggle()
        }
    }
}

/// View wrapper za ClientControlPanelElement
struct ClientControlPanelView: View {
    @ObservedObject var clientControlPanel: ClientControlPanelElement
    @State private var isHovered: Bool = false
    let clientName: String // "Client A" ili "Client B"
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        VStack {
            Spacer()
            animatedOrangeButton
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Animated Orange Button
    
    private var animatedOrangeButton: some View {
        ZStack {
            // Background - mali obli kvadrat koji raste kada je expanded
            if !clientControlPanel.isExpanded {
                Button(action: {
                    isHovered = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        clientControlPanel.toggleExpanded()
                    }
                }) {
                    // Mali obli element kada je collapsed
                    Capsule()
                        .fill(accentOrange)
                        .frame(
                            width: isHovered ? 50 : 40,
                            height: isHovered ? 8 : 6
                        )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
            } else {
                // Kada je expanded, prikaži pozadinu - dinamička širina ovisno o modu
                let panelWidth: CGFloat = clientControlPanel.isHomeView ? 200 : 140 // Home view = 5 gumbova, Business = 3 gumba
                RoundedRectangle(cornerRadius: 20)
                    .fill(accentOrange)
                    .frame(width: panelWidth, height: 40)
            }
            
            // Kontrole unutar expanded kvadrata
            if clientControlPanel.isExpanded {
                expandedControls
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: clientControlPanel.isExpanded)
        .onContinuousHover { phase in
            if !clientControlPanel.isExpanded {
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
        .onChange(of: clientControlPanel.isExpanded) { newValue in
            if newValue {
                isHovered = false
            }
        }
    }
    
    // MARK: - Expanded Controls
    
    private var expandedControls: some View {
        // Uvjetno prikazuj gumbove ovisno o modu
        HStack(spacing: 12) {
            // Ako je Home view (true), prikaži User i Topology gumbove
            if clientControlPanel.isHomeView {
                // Button 1 - User icon (Korisnikova ikona)
                Button(action: {
                    // Zatvori sve ostale view-ove
                    clientControlPanel.closeAllViews()
                    // Otvori User view
                    clientControlPanel.showUser = true
                    // Osiguraj da je panel expanded kada se otvori view
                    if !clientControlPanel.isExpanded {
                        clientControlPanel.isExpanded = true
                    }
                }) {
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // Button 2 - Topology icon (Topologija ikona)
                Button(action: {
                    // Zatvori sve ostale view-ove
                    clientControlPanel.closeAllViews()
                    // Otvori Topology view
                    clientControlPanel.showTopology = true
                    // Osiguraj da je panel expanded kada se otvori view
                    if !clientControlPanel.isExpanded {
                        clientControlPanel.isExpanded = true
                    }
                }) {
                    Image(systemName: "network")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // Button 3 - Collapse (Strelica prema dolje) - uvijek vidljiv
            // Samo collapse panel, NE zatvaraj view-ove
            Button(action: {
                // Samo collapse panel, view-ovi ostaju otvoreni
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    clientControlPanel.isExpanded = false
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // Button 4 - Exclamation (Uskličnik) - uvijek vidljiv
            Button(action: {
                // Zatvori sve ostale view-ove
                clientControlPanel.closeAllViews()
                // Otvori Exclamation view
                clientControlPanel.showExclamation = true
                // Osiguraj da je panel expanded kada se otvori view
                if !clientControlPanel.isExpanded {
                    clientControlPanel.isExpanded = true
                }
            }) {
                Image(systemName: "exclamationmark")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // Button 5 - Logs (Logovi) - tekst "Log" umjesto ikone
            Button(action: {
                // Zatvori sve ostale view-ove
                clientControlPanel.closeAllViews()
                // Otvori Logs view
                clientControlPanel.showLogs = true
                // Osiguraj da je panel expanded kada se otvori view
                if !clientControlPanel.isExpanded {
                    clientControlPanel.isExpanded = true
                }
            }) {
                Text("Log")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 24)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

