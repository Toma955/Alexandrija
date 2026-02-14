//
//  AlexandriaTheme.swift
//  Alexandria
//
//  Varijable teme – boja naglaska, ispuna bara, boje teksta, font.
//  Sve se može prilagoditi (npr. za Google stil druge boje). UI za promjenu još nije implementiran.
//

import SwiftUI

/// Centralizirane varijable izgleda – jedna točka za prilagodbu teme (narančasta + krem ispuna → druge boje).
struct AlexandriaTheme {
    
    private static let accentHexKey = "themeAccentColorHex"
    private static let barFillHexKey = "themeBarFillColorHex"
    private static let primaryTextHexKey = "themePrimaryTextColorHex"
    private static let secondaryTextHexKey = "themeSecondaryTextColorHex"
    private static let fontNameKey = "themeFontName"
    private static let fontSizeKey = "themeFontSize"
    
    // MARK: - Hex vrijednosti (spremljene u UserDefaults; nil = koristi default)
    
    /// Boja naglaska (narančasta po defaultu).
    static var accentColorHex: String {
        get { UserDefaults.standard.string(forKey: accentHexKey) ?? "ff5c00" }
        set { UserDefaults.standard.set(newValue, forKey: accentHexKey) }
    }
    
    /// Boja ispune bara (Island, gornji bar – krem/bijela po defaultu).
    static var barFillColorHex: String {
        get { UserDefaults.standard.string(forKey: barFillHexKey) ?? "ffffff" }
        set { UserDefaults.standard.set(newValue, forKey: barFillHexKey) }
    }
    
    /// Boja glavnog teksta (slova). nil = sustavski default.
    static var primaryTextColorHex: String? {
        get { UserDefaults.standard.string(forKey: primaryTextHexKey) }
        set { UserDefaults.standard.set(newValue, forKey: primaryTextHexKey) }
    }
    
    /// Boja sekundarnog teksta (npr. podnaslovi). nil = sustavski default.
    static var secondaryTextColorHex: String? {
        get { UserDefaults.standard.string(forKey: secondaryTextHexKey) }
        set { UserDefaults.standard.set(newValue, forKey: secondaryTextHexKey) }
    }
    
    /// Ime fonta (npr. "SF Pro Text"). nil = sustavski font.
    static var fontName: String? {
        get { UserDefaults.standard.string(forKey: fontNameKey) }
        set { UserDefaults.standard.set(newValue, forKey: fontNameKey) }
    }
    
    /// Veličina fonta u bodovima. nil = sustavski default.
    static var fontSize: CGFloat? {
        get {
            let v = UserDefaults.standard.double(forKey: fontSizeKey)
            return v > 0 ? CGFloat(v) : nil
        }
        set {
            if let v = newValue {
                UserDefaults.standard.set(Double(v), forKey: fontSizeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: fontSizeKey)
            }
        }
    }
    
    // MARK: - Izračunate boje (Color) i fontovi
    
    /// Boja naglaska – za gumbe, ikone, obrube.
    static var accentColor: Color {
        Color(hex: accentColorHex)
    }
    
    /// Boja ispune gornjeg bara (tab bar, Island pozadina).
    static var barFillColor: Color {
        Color(hex: barFillColorHex)
    }
    
    /// Boja glavnog teksta. Ako nije postavljena, vraća primarnu (adapts light/dark).
    static var primaryTextColor: Color {
        if let hex = primaryTextColorHex { return Color(hex: hex) }
        return .primary
    }
    
    /// Boja sekundarnog teksta (manje naglašeni tekst).
    static var secondaryTextColor: Color {
        if let hex = secondaryTextColorHex { return Color(hex: hex) }
        return .secondary
    }
    
    /// Font za naslove (npr. Island, kartice). Prilagoden ako je postavljen theme font.
    static var titleFont: Font {
        if let name = fontName, let size = fontSize {
            return .custom(name, size: size).weight(.semibold)
        }
        return .headline
    }
    
    /// Font za tijelo teksta.
    static var bodyFont: Font {
        if let name = fontName, let size = fontSize {
            return .custom(name, size: max(11, size - 1))
        }
        return .body
    }
    
    /// Vraća font s opcionalnom veličinom (ako tema ima fontSize, koristi ga; inače default size).
    static func font(size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        if let name = fontName {
            let s = fontSize ?? size
            return .custom(name, size: s).weight(weight)
        }
        return .system(size: size, weight: weight)
    }
    
    /// Reset na default vrijednosti (narančasta, bijela ispuna, sustavski font).
    static func resetToDefaults() {
        accentColorHex = "ff5c00"
        barFillColorHex = "ffffff"
        primaryTextColorHex = nil
        secondaryTextColorHex = nil
        fontName = nil
        fontSize = nil
    }
}
