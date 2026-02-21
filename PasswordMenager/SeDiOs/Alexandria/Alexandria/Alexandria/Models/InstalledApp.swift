//
//  InstalledApp.swift
//  Alexandria
//
//  Model instalirane aplikacije – folder s .swift ili LLVM IR (.ll / .bc) datotekama.
//

import Foundation

/// Format izvora aplikacije – Swift ili LLVM IR
enum AppSourceFormat: String, Codable, Equatable {
    case swift   // .swift, .alexandria – izvornik se može otvoriti u Dev Tools i spremiti
    case llvmIR  // .ll, .bc – po defaultu izvor se ne smije otvoriti ni spremiti, osim ako aplikacija ne odredi
    
    /// Određuje format prema ekstenziji entry point datoteke
    static func from(entryPoint: String) -> AppSourceFormat {
        let ext = (entryPoint as NSString).pathExtension.lowercased()
        return (ext == "ll" || ext == "bc") ? .llvmIR : .swift
    }
}

/// Instalirana Alexandria aplikacija (Swift ili LLVM IR)
struct InstalledApp: Identifiable, Equatable {
    let id: UUID
    let name: String
    let folderURL: URL
    /// Relativna staza do glavne datoteke (npr. index.swift ili main.ll)
    let entryPoint: String
    let installedAt: Date
    /// Swift ili LLVM IR – određeno prema ekstenziji entry pointa
    let sourceFormat: AppSourceFormat
    /// Smije li se u Dev Tools otvoriti i spremati izvorni kod? Za Swift default true; za LLVM IR default false, osim ako aplikacija ne odredi.
    let allowsSourceInspection: Bool
    /// ID u katalogu servera (npr. "youtube") – za usporedbu hasha
    let catalogId: String?
    /// Hash zipa pri instalaciji – ako se podudara s serverom, ne treba ponovno preuzimanje
    let zipHash: String?
    /// Ako postoji, prikaži pravi web (Google, YouTube, itd.) u WKWebView umjesto DSL-a
    let webURL: String?
    
    /// Pun URL do entry point datoteke
    var entryURL: URL {
        folderURL.appendingPathComponent(entryPoint)
    }
    
    /// Je li izvor vidljiv u Dev Tools i spremanje dozvoljeno (Swift + dozvola, ili IR s eksplicitnom dozvolom)
    var canViewOrSaveSource: Bool {
        allowsSourceInspection
    }
}
