//
//  ImportView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ImportView: View {
    @EnvironmentObject private var localization: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Uvezi")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("Funkcionalnost u izradi...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

