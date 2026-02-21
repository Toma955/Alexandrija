//
//  InterfaceLanguage.swift
//  Alexandria
//
//  Jezik sučelja – uvijek jedan označen (zadano Hrvatski).
//  Ugrađeni jezici + preuzeti s backenda (Market → Jezici).
//

import Foundation

/// Jedan jezik sučelja – locale kod (npr. hr, en) i prikazno ime.
struct InterfaceLanguage: Identifiable, Equatable {
    let localeCode: String
    let displayName: String

    var id: String { localeCode }

    /// Ugrađeni jezici – uvijek dostupni bez preuzimanja. Hrvatski je prvi (zadani). Sinkronizirano s backend katalogom (hr, en, de, fr, it, es).
    static let builtin: [InterfaceLanguage] = [
        InterfaceLanguage(localeCode: "hr", displayName: "Hrvatski"),
        InterfaceLanguage(localeCode: "en", displayName: "English"),
        InterfaceLanguage(localeCode: "de", displayName: "Deutsch"),
        InterfaceLanguage(localeCode: "fr", displayName: "Français"),
        InterfaceLanguage(localeCode: "it", displayName: "Italiano"),
        InterfaceLanguage(localeCode: "es", displayName: "Español"),
    ]

    /// Zadani jezik kad nema spremljenog ili je nevaljan (uvijek Hrvatski).
    static let defaultLocaleCode = "hr"

    /// Svi jezici koje korisnik može odabrati: ugrađeni + preuzeti s backenda.
    static func available() -> [InterfaceLanguage] {
        let fromBackend = BackendCatalogService.shared.installedInterfaceLanguages()
        let builtinCodes = Set(builtin.map(\.localeCode))
        let onlyInstalled = fromBackend.filter { !builtinCodes.contains($0.localeCode) }
        return builtin + onlyInstalled
    }

    /// Vrati valjani locale kod: spremljeni ako je u listi dostupnih, inače Hrvatski.
    static func validLocaleCode(stored: String?) -> String {
        let availableCodes = Set(available().map(\.localeCode))
        guard let s = stored?.trimmingCharacters(in: .whitespaces), !s.isEmpty,
              availableCodes.contains(s) else {
            return defaultLocaleCode
        }
        return s
    }
}
