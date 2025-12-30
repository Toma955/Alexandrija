//
//  MessageCryptoService.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation
import CryptoKit

enum MessageCryptoError: Error {
    case invalidBase64
    case invalidSealedBox
    case invalidUTF8
}

struct MessageCryptoService {
    
    /// Enkriptira plain tekst u jedan Base64 string (spremno za disk)
    static func encryptString(_ text: String, with key: SymmetricKey) throws -> String {
        let data = Data(text.utf8)
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw MessageCryptoError.invalidSealedBox
        }
        
        return combined.base64EncodedString()
    }
    
    /// Dekriptira Base64 string (koji je nastao encryptString) natrag u plain tekst
    static func decryptString(_ base64: String, with key: SymmetricKey) throws -> String {
        guard let combinedData = Data(base64Encoded: base64) else {
            throw MessageCryptoError.invalidBase64
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let text = String(data: decryptedData, encoding: .utf8) else {
            throw MessageCryptoError.invalidUTF8
        }
        
        return text
    }
}

