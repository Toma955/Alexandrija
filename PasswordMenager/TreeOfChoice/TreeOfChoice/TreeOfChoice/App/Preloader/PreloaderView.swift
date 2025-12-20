// App/Preloader/PreloaderView.swift
import SwiftUI

struct PreloaderView: View {
    @EnvironmentObject private var preloaderViewModel: PreloaderViewModel
    @EnvironmentObject private var localization: LocalizationManager

    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0) // #FF5C00

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            // ISTA NARANČASTA POZADINA
            accentOrange

            VStack(spacing: 24) {
                Text(localization.text("preloader.title"))
                    .font(.largeTitle.bold())
                    .foregroundColor(.black)

                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)

                Button(action: {
                    onFinished()
                }) {
                    Text(localization.text("preloader.button"))
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(999)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.black)
            }
            .padding(32)
            .background(Color.black.opacity(0.2))
            .cornerRadius(24)
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}
