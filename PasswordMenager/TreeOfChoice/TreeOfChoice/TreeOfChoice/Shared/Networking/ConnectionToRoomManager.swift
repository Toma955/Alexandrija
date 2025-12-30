//
//  ConnectionToRoomManager.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

final class ConnectionToRoomManager: ObservableObject {
    /// Svaka kućica je jedan string, max 1 znak
    @Published var digits: [String] = Array(repeating: "", count: 16)
    
    /// Spojen kod (za connect)
    var code: String {
        digits.joined()
    }
    
    /// Je li korisnik unio svih 16 znakova
    var isComplete: Bool {
        code.count == 16
    }
    
    /// Kad korisnik nešto upiše ili zalijepi u jednu kućicu
    func updateDigit(_ newValue: String, at index: Int) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // ništa → obriši samo tu kućicu
        guard !trimmed.isEmpty else {
            digits[index] = ""
            return
        }
        
        // više od 1 znaka → tretiramo kao PASTE cijelog ID-a
        if trimmed.count > 1 {
            applyPaste(trimmed)
            return
        }
        
        // normalan slučaj: 1 znak
        digits[index] = String(trimmed.prefix(1))
    }
    
    /// PASTE: razbij string na znakove i rasporedi po kućicama
    func applyPaste(_ string: String) {
        let cleaned = string.replacingOccurrences(of: " ", with: "")
        let chars = Array(cleaned.prefix(16))
        
        for i in 0..<16 {
            if i < chars.count {
                digits[i] = String(chars[i])
            } else {
                digits[i] = ""
            }
        }
    }
    
    /// Reset (npr. kad user promijeni room)
    func reset() {
        digits = Array(repeating: "", count: 16)
    }
}

