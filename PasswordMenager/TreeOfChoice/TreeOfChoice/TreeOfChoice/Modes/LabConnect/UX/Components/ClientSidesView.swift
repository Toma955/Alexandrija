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
    
    private let marginFromDivider: CGFloat = 5 // 5px od bijele vertikalne linije
    private let marginFromBottomLine: CGFloat = 0 // 0px - donja linija oblika je točno na donjoj horizontalnoj liniji
    private let dividerX: CGFloat = 300 // Pozicija bijele vertikalne linije
    private let heightExtension: CGFloat = 110 // Produžena visina za 110px (100 + 10px gore)
    
    // Širina kvadrata: 5px od vertikalne linije, širina panela je 300px
    // Lijevi kvadrat: desni rub na 300 - 5 = 295px, lijevi rub na 295 - squareWidth
    // Desni kvadrat: lijevi rub na 5px od desne bijele linije (od lijevog ruba panela)
    private var squareWidth: CGFloat {
        dividerX - marginFromDivider - marginFromDivider // 300 - 5 - 5 = 290px (ako želimo maksimalnu širinu)
        // Ili fiksna širina 285px
        // Za sada koristimo 285px kao prije
        return 285
    }
    
    // Visina kvadrata: širina + 110px
    private var squareHeight: CGFloat {
        squareWidth + heightExtension // 285 + 110 = 395px
    }
    
    var body: some View {
        Group {
            if lineYPosition > 0 {
                // Izračunaj Y poziciju: donji rub kvadrata točno na donjoj horizontalnoj liniji
                // Centar pomaknut gore za polovinu dodatne visine (2.5px) da kvadrat raste prema gore
                let adjustedY = lineYPosition - geometry.frame(in: .global).minY
                let y = adjustedY - marginFromBottomLine - (squareHeight / 2) // Linija - polovica visine = centar kvadrata
                
                VStack {
                    Text(isLeftSide ? "Client A" : "Client B")
                        .font(.headline.bold())
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .frame(width: squareWidth, height: squareHeight) // 285x385px
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 2)
                )
                .position(
                    x: isLeftSide ? 
                        // Lijevi kvadrat: desni rub na 300 - 5 = 295px, centar na 295 - (squareWidth / 2)
                        (dividerX - marginFromDivider - (squareWidth / 2)) : // 300 - 5 - 142.5 = 152.5px
                        // Desni kvadrat: lijevi rub na 5px od desne bijele linije (od lijevog ruba panela)
                        // Panel je 300px širok, bijela linija je na 0px od lijevog ruba panela (ili 300px od lijeve strane ekrana)
                        // Lijevi rub kvadrata: 5px od lijevog ruba panela, centar na 5 + (squareWidth / 2)
                        (marginFromDivider + (squareWidth / 2)), // 5 + 142.5 = 147.5px
                    y: y
                )
            }
        }
    }
}

