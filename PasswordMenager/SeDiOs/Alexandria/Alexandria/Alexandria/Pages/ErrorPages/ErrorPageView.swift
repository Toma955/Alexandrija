//
//  ErrorPageView.swift
//  Alexandria
//
//  Interne stranice za HTTP greške – 400, 401, 404, 500, 502, 503.
//

import SwiftUI

/// Interna stranica za HTTP greške – prikazuje se kad Eluminatium ne odgovori
struct ErrorPageView: View {
    let statusCode: Int
    let message: String?
    var onRetry: (() -> Void)?
    var onLocalMode: (() -> Void)?
    var onDevMode: (() -> Void)?

    private let accentColor = Color(hex: "ff5c00")

    private var title: String {
        switch statusCode {
        case 400: return "Loš zahtjev"
        case 401: return "Neovlašten"
        case 403: return "Zabranjeno"
        case 404: return "Nije pronađeno"
        case 408: return "Isteklo vrijeme"
        case 500: return "Greška poslužitelja"
        case 502: return "Loš gateway"
        case 503: return "Servis nedostupan"
        default: return "Greška \(statusCode)"
        }
    }

    private var description: String {
        switch statusCode {
        case 400: return "Zahtjev nije valjan. Provjeri URL ili parametre."
        case 401: return "Potrebna je autentifikacija. Prijavi se ili provjeri pristup."
        case 403: return "Pristup je zabranjen za ovaj resurs."
        case 404: return "Stranica ili resurs nije pronađen. Provjeri URL."
        case 408: return "Zahtjev je istekao. Pokušaj ponovo."
        case 500: return "Poslužitelj je doživio grešku. Pokušaj kasnije."
        case 502: return "Gateway ili proxy ne može dobiti odgovor od poslužitelja."
        case 503: return "Servis je privremeno nedostupan. Pokušaj kasnije."
        default:
            if statusCode >= 500 { return "Greška poslužitelja." }
            if statusCode >= 400 { return "Greška klijenta." }
            return "Neočekivana greška."
        }
    }

    private var icon: String {
        switch statusCode {
        case 400, 401, 403: return "exclamationmark.shield"
        case 404: return "magnifyingglass"
        case 408: return "clock.badge.exclamationmark"
        case 500, 502, 503: return "server.rack"
        default: return "exclamationmark.triangle"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("\(statusCode)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(accentColor.opacity(0.9))

            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(accentColor.opacity(0.7))

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)

                if let msg = message, !msg.isEmpty {
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                        .padding(.top, 4)
                }
            }

            HStack(spacing: 16) {
                if onRetry != nil {
                    Button("Pokušaj ponovo") {
                        onRetry?()
                    }
                    .foregroundColor(accentColor)
                }
                if onLocalMode != nil {
                    Button("Lokalni mod") {
                        onLocalMode?()
                    }
                    .foregroundColor(accentColor.opacity(0.8))
                }
                if onDevMode != nil {
                    Button("Dev Mode") {
                        onDevMode?()
                    }
                    .foregroundColor(accentColor.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
