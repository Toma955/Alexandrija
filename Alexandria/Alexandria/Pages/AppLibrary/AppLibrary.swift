//
//  AppLibrary.swift
//  Alexandria
//
//  App Library – knjižnica aplikacija.
//

import SwiftUI

struct AppLibraryView: View {
    @Environment(\.dismiss) var dismiss
    private let accentColor = Color(hex: "ff5c00")

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("App Library")
                    .font(.title2.bold())
                    .foregroundColor(accentColor)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Text("Knjižnica aplikacija")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer()
        }
        .frame(width: 600, height: 400)
        .background(Color.black.opacity(0.9))
    }
}

#Preview {
    AppLibraryView()
}
