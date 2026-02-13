//
//  SettingsPage.swift
//  Alexandria
//
//  Stranica postavki.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("searchPanelPosition") private var searchPanelPositionRaw = SearchPanelPosition.both.rawValue
    @State private var islandTitle: String = ""
    
    private let accentColor = Color(hex: "ff5c00")
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Postavke")
                .font(.title2.bold())
                .foregroundColor(accentColor)
            
            // Natpis Islanda
            VStack(alignment: .leading, spacing: 8) {
                Text("Natpis Islanda")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Alexandria", text: $islandTitle)
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(.black)
                    .onChange(of: islandTitle) { _, newValue in
                        AppSettings.islandTitle = newValue
                    }
            }
            .padding()
            .frame(maxWidth: 400)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
            )
            
            // Search panel pozicija
            VStack(alignment: .leading, spacing: 8) {
                Text("Search panel")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Picker("Pozicija", selection: $searchPanelPositionRaw) {
                    ForEach(SearchPanelPosition.allCases, id: \.rawValue) { position in
                        Text(position.label).tag(position.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .frame(maxWidth: 400)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
            )
            
            Spacer()
            
            Button("Zatvori") {
                dismiss()
            }
            .foregroundColor(accentColor)
            .padding(.bottom, 20)
        }
        .padding(24)
        .frame(width: 420, height: 280)
        .background(Color.black.opacity(0.9))
        .onAppear { islandTitle = AppSettings.islandTitle }
    }
}
