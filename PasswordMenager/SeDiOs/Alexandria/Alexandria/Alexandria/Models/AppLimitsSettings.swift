//
//  AppLimitsSettings.swift
//  Alexandria
//
//  Ograničenja i posebne dozvole – veličina zipa, main datoteke, dubina parsera.
//  Proširivo za buduće: Neural Engine, RAM, pristup memoriji.
//

import Foundation

/// Minimalna i maksimalna dopuštena dubina parsera (min za stabilnost, max za razumnu granicu)
private let parserMaxDepthMin = 10
private let parserMaxDepthMax = 2000

// MARK: - Ključevi UserDefaults

private enum Keys {
    static let maxZipSizeBytes = "appLimitsMaxZipSizeBytes"
    static let maxMainFileSizeBytes = "appLimitsMaxMainFileSizeBytes"
    static let allowExceedSizeLimits = "appLimitsAllowExceedSizeLimits"
    static let parserMaxDepth = "appLimitsParserMaxDepth"
    // Proširivo za buduće: neuralEngineAllowed, maxRAMBytes, itd.
}

// MARK: - App Limits Settings

enum AppLimitsSettings {

    /// Maksimalna veličina zipa u bajtovima. nil = bez limita.
    static var maxZipSizeBytes: Int? {
        get {
            let v = UserDefaults.standard.object(forKey: Keys.maxZipSizeBytes) as? Int
            return v.map { $0 > 0 ? $0 : nil } ?? nil
        }
        set {
            if let v = newValue, v > 0 {
                UserDefaults.standard.set(v, forKey: Keys.maxZipSizeBytes)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.maxZipSizeBytes)
            }
        }
    }

    /// Maksimalna veličina main datoteke (entry point) u bajtovima. nil = bez limita.
    static var maxMainFileSizeBytes: Int? {
        get {
            let v = UserDefaults.standard.object(forKey: Keys.maxMainFileSizeBytes) as? Int
            return v.map { $0 > 0 ? $0 : nil } ?? nil
        }
        set {
            if let v = newValue, v > 0 {
                UserDefaults.standard.set(v, forKey: Keys.maxMainFileSizeBytes)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.maxMainFileSizeBytes)
            }
        }
    }

    /// Posebna dozvola: dopusti prekoračenje limita veličine (zip / main datoteka). Korisnik mora eksplicitno uključiti.
    static var allowExceedSizeLimits: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.allowExceedSizeLimits) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.allowExceedSizeLimits) }
    }

    /// Maksimalna dubina ugniježđenja u Alexandria parseru (npr. VStack u VStack…). Raspon: parserMaxDepthMin ... parserMaxDepthMax.
    static var parserMaxDepth: Int {
        get {
            let v = UserDefaults.standard.object(forKey: Keys.parserMaxDepth) as? Int
            guard let n = v else { return 100 }
            return min(max(n, parserMaxDepthMin), parserMaxDepthMax)
        }
        set {
            let clamped = min(max(newValue, parserMaxDepthMin), parserMaxDepthMax)
            UserDefaults.standard.set(clamped, forKey: Keys.parserMaxDepth)
        }
    }

    /// Je li zip prekoračen (treba posebna dozvola ili odbij)?
    static func isZipSizeAllowed(bytes: Int) -> Bool {
        guard let maxBytes = maxZipSizeBytes else { return true }
        if bytes <= maxBytes { return true }
        return allowExceedSizeLimits
    }

    /// Je li veličina main datoteke dopuštena?
    static func isMainFileSizeAllowed(bytes: Int) -> Bool {
        guard let maxBytes = maxMainFileSizeBytes else { return true }
        if bytes <= maxBytes { return true }
        return allowExceedSizeLimits
    }

    /// Vraća efektivnu max dubinu za parser (unutar dozvoljenog raspona).
    static var effectiveParserMaxDepth: Int {
        parserMaxDepth
    }

    /// Reset na razumne default vrijednosti (bez limita veličine, dubina 100).
    static func resetToDefaults() {
        maxZipSizeBytes = nil
        maxMainFileSizeBytes = nil
        allowExceedSizeLimits = false
        UserDefaults.standard.set(100, forKey: Keys.parserMaxDepth)
    }
}
