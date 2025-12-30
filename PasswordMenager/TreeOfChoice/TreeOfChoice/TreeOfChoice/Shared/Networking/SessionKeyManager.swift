//
//  SessionKeyManager.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation
import CryptoKit

/// Jednostavan manager za masterKey upravljanje
/// Za sada koristi demo key, kasnije se može proširiti s PIN-om i secret file-om
final class SessionKeyManager: ObservableObject {
    static let shared = SessionKeyManager()
    
    private var _masterKey: SymmetricKey?
    
    var masterKey: SymmetricKey? {
        return _masterKey
    }
    
    private init() {
        // Za sada generiraj demo key
        // Kasnije će se koristiti PIN + secret file kao u AMessages
        generateDemoKey()
    }
    
    /// Generira demo master key (za testiranje)
    private func generateDemoKey() {
        let demoData = Data("TreeOfChoice-Demo-Key-2025".utf8)
        let hashed = SHA256.hash(data: demoData)
        _masterKey = SymmetricKey(data: hashed)
        print("🔑 [SessionKeyManager] Demo master key generiran")
    }
    
    /// Postavi master key iz PIN-a i secret file-a (za buduću implementaciju)
    func setMasterKey(pin: String, secretFileURL: URL?) {
        // TODO: Implementirati kao u AMessages CryptoService
        // Za sada koristi demo key
        generateDemoKey()
    }
    
    /// Obriši master key (lock)
    func clearMasterKey() {
        _masterKey = nil
    }
}

