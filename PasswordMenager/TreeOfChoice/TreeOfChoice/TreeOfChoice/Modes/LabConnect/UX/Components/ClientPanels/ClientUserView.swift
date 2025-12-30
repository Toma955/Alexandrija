//
//  ClientUserView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit

/// View za User komponentu u Client panelu
struct ClientUserView: View {
    @Binding var isPresented: Bool
    let clientName: String // "Client A" ili "Client B"
    @State private var fieldValues: [String] = Array(repeating: "", count: 16)
    @FocusState private var focusedField: Int?
    @State private var isConnecting: Bool = false
    
    private var allFieldsFilled: Bool {
        fieldValues.allSatisfy { !$0.isEmpty }
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 16) {
                headerView
                Divider()
                    .background(Color.white.opacity(0.3))
                gridView
                Spacer()
                    .frame(maxHeight: 20)
                buttonsView
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.95))
            .cornerRadius(12)
            .blur(radius: isConnecting ? 3 : 0)
            .disabled(isConnecting)
            
            // Waiting overlay s animacijom
            if isConnecting {
                waitingOverlay
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text("\(clientName) - User")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var gridView: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(0..<16, id: \.self) { index in
                    fieldView(for: index)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)
    }
    
    private func fieldView(for index: Int) -> some View {
        TextField("", text: Binding(
            get: { fieldValues[index] },
            set: { newValue in
                // Ako je uneseno više znakova (paste), rasporedi ih kroz polja
                if newValue.count > 1 {
                    distributeCharacters(from: newValue, startingAt: index)
                } else {
                    // Ograniči na 1 znak
                    let limitedValue = String(newValue.prefix(1))
                    fieldValues[index] = limitedValue
                    
                    // Ako je unesen znak, prebaci fokus na sljedeće polje
                    if !limitedValue.isEmpty && index < 15 {
                        DispatchQueue.main.async {
                            focusedField = index + 1
                        }
                    }
                }
            }
        ))
        .textFieldStyle(.plain)
        .font(.caption)
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .autocorrectionDisabled()
        .frame(height: 50)
        .background(fieldBackground)
        .focused($focusedField, equals: index)
    }
    
    private func distributeCharacters(from text: String, startingAt startIndex: Int) {
        let characters = Array(text)
        let remainingFields = 16 - startIndex
        let charactersToDistribute = min(characters.count, remainingFields)
        
        // Rasporedi znakove kroz polja od startIndex do kraja
        for i in 0..<charactersToDistribute {
            let fieldIndex = startIndex + i
            if fieldIndex < 16 {
                fieldValues[fieldIndex] = String(characters[i])
            }
        }
        
        // Ako ima više znakova nego polja, fokusiraj zadnje polje
        // Ako ima manje znakova, fokusiraj prvo prazno polje nakon distribucije
        DispatchQueue.main.async {
            if charactersToDistribute < remainingFields {
                // Ima još praznih polja, fokusiraj prvo prazno
                let nextEmptyIndex = startIndex + charactersToDistribute
                if nextEmptyIndex < 16 {
                    focusedField = nextEmptyIndex
                } else {
                    focusedField = nil
                }
            } else {
                // Sva polja su popunjena ili je došlo do kraja
                focusedField = nil
            }
        }
    }
    
    private var buttonsView: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 12) {
                // Insert & Copy button - obli kvadrat fill
                Button(action: {
                    insertRandomAndCopy()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                        Text("Insert & Copy")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 1.0, green: 0.36, blue: 0.0))
                    )
                }
                .buttonStyle(.plain)
                
                // Connect button - onemogućen dok nisu sva polja popunjena ili dok se spaja
                Button(action: {
                    connect()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text("Connect")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((allFieldsFilled && !isConnecting) ? Color(red: 1.0, green: 0.36, blue: 0.0) : Color.gray.opacity(0.5))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!allFieldsFilled || isConnecting)
            }
            
            Spacer()
        }
        .padding(.top, 4)
    }
    
    // MARK: - Actions
    
    private func insertRandomAndCopy() {
        // Generiraj random slova (A-Z) za svih 16 polja
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var randomValues: [String] = []
        
        for _ in 0..<16 {
            let randomIndex = Int.random(in: 0..<letters.count)
            let randomLetter = String(letters[letters.index(letters.startIndex, offsetBy: randomIndex)])
            randomValues.append(randomLetter)
        }
        
        // Popuni polja
        fieldValues = randomValues
        
        // Kopiraj u clipboard
        let combinedText = randomValues.joined()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(combinedText, forType: .string)
        
        // Ukloni fokus s polja
        focusedField = nil
    }
    
    private func copyToClipboard() {
        let combinedText = fieldValues.joined()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(combinedText, forType: .string)
    }
    
    private func connect() {
        guard allFieldsFilled && !isConnecting else { return }
        
        isConnecting = true
        
        // Simuliraj konekciju (zamijeni s pravom logikom)
        Task {
            // Simuliraj čekanje konekcije (2-5 sekundi)
            let delay = Double.random(in: 2...5)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            await MainActor.run {
                isConnecting = false
                // TODO: Implement actual connection logic here
                print("Connect completed with values: \(fieldValues.joined())")
            }
        }
    }
    
    private var waitingOverlay: some View {
        ZStack {
            // Tamna pozadina
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Waiting content
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    .tint(Color(red: 1.0, green: 0.36, blue: 0.0))
                
                Text("Waiting...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Connecting...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 1.0, green: 0.36, blue: 0.0), lineWidth: 2)
                    )
            )
        }
    }
    
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}

