//
//  InitialSetupView.swift
//  Alexandria
//
//  Pri prvom pokretanju / instalaciji – osnovne postavke (tema, što otvoriti).
//

import SwiftUI

private let kHasCompletedInitialSetupKey = "hasCompletedInitialSetup"

/// Javno za čitanje: je li korisnik već prošao početne postavke (da se ne prikaže ponovno).
var hasCompletedInitialSetup: Bool {
    get { UserDefaults.standard.bool(forKey: kHasCompletedInitialSetupKey) }
    set { UserDefaults.standard.set(newValue, forKey: kHasCompletedInitialSetupKey) }
}

struct InitialSetupView: View {
    var onComplete: () -> Void

    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue
    @State private var onOpenActionRaw = AppSettings.onOpenAction.rawValue

    private var accentColor: Color { AlexandriaTheme.accentColor }

    var body: some View {
        ZStack {
            AppBackgroundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    header
                    osnovnePostavkeCard
                    nastaviButton
                }
                .padding(40)
                .frame(maxWidth: 600, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dobrodošli u Alexandria")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Text("Odaberi osnovne postavke. Kasnije ih možeš promijeniti u Postavkama.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var osnovnePostavkeCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Osnovne postavke")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(accentColor)

            // Tema
            VStack(alignment: .leading, spacing: 8) {
                Text("Izgled")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                Picker("", selection: $appThemeRaw) {
                    ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                        Label(theme.label, systemImage: theme.icon)
                            .tag(theme.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // Što otvoriti pri pokretanju
            VStack(alignment: .leading, spacing: 8) {
                Text("Pri pokretanju aplikacije")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                Picker("", selection: $onOpenActionRaw) {
                    ForEach(OnOpenAction.allCases, id: \.rawValue) { action in
                        Text(action.label).tag(action.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var nastaviButton: some View {
        Button(action: {
            if let action = OnOpenAction(rawValue: onOpenActionRaw) {
                AppSettings.onOpenAction = action
            }
            hasCompletedInitialSetup = true
            ThemeRegistry.applyCurrentThemeColors()
            onComplete()
        }) {
            Text("Nastavi")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InitialSetupView(onComplete: {})
        .frame(width: 600, height: 500)
}
