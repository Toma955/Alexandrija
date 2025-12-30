//
//  ClientSidesView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ClientSidesView: View {
    let geometry: GeometryProxy
    let lineYPosition: CGFloat // Pozicija horizontalne linije ispod topologije
    let isLeftSide: Bool // true za lijevu stranu, false za desnu
    
    @StateObject private var clientControlPanel = ClientControlPanelElement()
    
    private let marginFromDivider: CGFloat = 10 // 10px od bijele vertikalne linije
    private let marginFromEdge: CGFloat = 5 // 5px od ruba ekrana
    private let marginFromBottomLine: CGFloat = 10 // 10px od donje horizontalne linije (pomaknuto prema dolje za 10px)
    private let dividerX: CGFloat = 300 // Pozicija bijele vertikalne linije
    private let heightExtension: CGFloat = 100 // Produžena visina za 100px (60 + 20 + 10 + 10)
    
    // Širina kvadrata: između 5px od ruba i 10px od linije = 300 - 5 - 10 = 285px
    private var squareWidth: CGFloat {
        dividerX - marginFromEdge - marginFromDivider // 300 - 5 - 10 = 285px
    }
    
    // Visina kvadrata: širina + 80px
    private var squareHeight: CGFloat {
        squareWidth + heightExtension // 285 + 80 = 365px
    }
    
    var body: some View {
        Group {
            if lineYPosition > 0 {
                // Izračunaj Y poziciju: donji rub kvadrata 110px od donje horizontalne linije
                let adjustedY = lineYPosition - geometry.frame(in: .global).minY
                let y = adjustedY - marginFromBottomLine - (squareHeight / 2) // Linija - 110px - polovica visine = centar kvadrata
                
                ZStack {
                    // Background okvir
                    VStack {
                        Text(isLeftSide ? "Client A" : "Client B")
                            .font(.headline.bold())
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    .frame(width: squareWidth, height: squareHeight) // 285x345px
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .zIndex(1) // Background je najniži
                    
                    // View-ovi unutar cijelog okvira - iza control panela
                    if clientControlPanel.showUser {
                        ClientUserView(isPresented: $clientControlPanel.showUser, clientName: isLeftSide ? "Client A" : "Client B")
                            .frame(width: squareWidth, height: squareHeight)
                            .zIndex(5) // Ispod control panela
                    }
                    
                    if clientControlPanel.showTopology {
                        ClientTopologyView(isPresented: $clientControlPanel.showTopology, clientName: isLeftSide ? "Client A" : "Client B")
                            .frame(width: squareWidth, height: squareHeight)
                            .zIndex(5) // Ispod control panela
                    }
                    
                    if clientControlPanel.showLogs {
                        ClientLogsView(isPresented: $clientControlPanel.showLogs, clientName: isLeftSide ? "Client A" : "Client B")
                            .frame(width: squareWidth, height: squareHeight)
                            .zIndex(5) // Ispod control panela
                    }
                    
                    if clientControlPanel.showExclamation {
                        ClientExclamationView(isPresented: $clientControlPanel.showExclamation, clientName: isLeftSide ? "Client A" : "Client B")
                            .frame(width: squareWidth, height: squareHeight)
                            .zIndex(5) // Ispod control panela
                    }
                    
                    // Client Control Panel na dnu kvadrata - IZNAD view-ova
                    VStack {
                        Spacer()
                        ClientControlPanelView(
                            clientControlPanel: clientControlPanel,
                            clientName: isLeftSide ? "Client A" : "Client B"
                        )
                        .frame(height: 60) // Visina za panel
                        .offset(y: 30) // Spusti za 30 piksela dolje
                    }
                    .frame(width: squareWidth, height: squareHeight)
                    .zIndex(20) // Iznad view-ova
                }
                .position(
                    x: isLeftSide ? 
                        (marginFromEdge + (squareWidth / 2)) : // 5 + 142.5 = 147.5px (lijevo)
                        (marginFromDivider + (squareWidth / 2)), // 10 + 142.5 = 152.5px (desno)
                    y: y
                )
            }
        }
    }
}

