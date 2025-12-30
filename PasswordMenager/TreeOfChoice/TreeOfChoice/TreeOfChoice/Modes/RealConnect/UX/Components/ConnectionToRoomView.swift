//
//  ConnectionToRoomView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ConnectionToRoomView: View {
    @StateObject private var manager = ConnectionToRoomManager()
    @FocusState private var focusedIndex: Int?
    
    /// Naslov (ovisno o jeziku, npr. "Spoji se na sobu")
    let title: String
    
    /// Tekst gumba (npr. "Poveži se")
    let buttonTitle: String
    
    /// Ako je true → prikaži gumb.
    /// Ako je false → kad je kod kompletan (16 znakova), automatski pozovi onConnect.
    let showsConnectButton: Bool
    
    /// Je li server javio da je spojen (npr. ping OK)
    let isServerConnected: Bool
    
    /// Poruka za korisnika (npr. greška ili hint), može biti nil.
    let message: String?
    
    /// Callback kad je uneseno svih 16 znakova
    var onConnect: (String) -> Void
    
    /// Callback za gumb Zatvori
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.white)
                
                if let message {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.75))
                }
            }
            
            HStack(spacing: 6) {
                ForEach(0..<16, id: \.self) { index in
                    digitField(at: index)
                }
            }
            
            // Gumbi dolje
            if showsConnectButton {
                HStack(spacing: 12) {
                    connectButton
                    cancelButton
                }
            } else {
                HStack {
                    Spacer()
                    cancelButton
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            focusedIndex = 0
        }
    }
    
    // MARK: - Kućice
    
    private func digitField(at index: Int) -> some View {
        let hasValue = !manager.digits[index].isEmpty
        let isFocused = focusedIndex == index
        
        let borderColor: Color = {
            if isFocused { return .orange }
            if hasValue { return .green }
            return Color.white.opacity(0.35)
        }()
        
        return ZStack {
            // nevidljivi TextField koji prima input
            TextField(
                "",
                text: Binding(
                    get: { manager.digits[index] },
                    set: { newValue in
                        handleChange(newValue, at: index)
                    }
                )
            )
            .focused($focusedIndex, equals: index)
            .textFieldStyle(.plain)
            .frame(width: 24, height: 30)
            .opacity(0.01)
            
            // vidljivi sadržaj – centriran
            Text(manager.digits[index].isEmpty ? " " : manager.digits[index])
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.white)
                .frame(width: 24, height: 30, alignment: .center)
        }
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                )
        )
        .onTapGesture {
            focusedIndex = index
        }
    }
    
    // MARK: - Gumbi
    
    private var connectButton: some View {
        let activeColor: Color = isServerConnected ? .green : .orange
        
        return Button {
            guard manager.isComplete else { return }
            onConnect(manager.code)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        manager.isComplete
                        ? activeColor.opacity(0.9)
                        : Color.white.opacity(0.25)
                    )
            )
            .foregroundColor(Color.white)
        }
        .buttonStyle(.plain)
        .disabled(!manager.isComplete)
    }
    
    private var cancelButton: some View {
        Button {
            onCancel()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                Text("Zatvori")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.18))
            )
            .foregroundColor(Color.white.opacity(0.9))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Logika inputa
    
    private func handleChange(_ newValue: String, at index: Int) {
        let oldDigits = manager.digits
        let wasComplete = manager.isComplete
        
        manager.updateDigit(newValue, at: index)
        
        // Ako je user zalijepio više znakova → manager.applyPaste(...)
        if newValue.count > 1 {
            if let nextEmpty = manager.digits.firstIndex(where: { $0.isEmpty }) {
                focusedIndex = nextEmpty
            } else {
                focusedIndex = nil
            }
        } else {
            // Normalan unos: 1 znak → skoči na sljedeću kućicu
            if manager.digits[index].count == 1 && manager.digits[index] != oldDigits[index] {
                let next = index + 1
                focusedIndex = next < 16 ? next : nil
            }
        }
        
        // AUTO-CONNECT: kad prvi put postane kompletan kod (16 znakova) i nema gumba
        let isNowComplete = manager.isComplete
        if !showsConnectButton && isNowComplete && !wasComplete {
            onConnect(manager.code)
        }
    }
}

