//
//  VaultSecureEnclaveKey.swift
//  Alexandria
//
//  Priprema: Hardverska zaštita ključeva (Secure Enclave).
//  Privatni ključ se generira na Apple silikonu (M1/M2/M3) i ne napušta sigurnosni čip.
//  Tim ključem se otključava pristup vaultu samo dok je aplikacija aktivna.
//  NIGDJE SE NE UKLJUČUJE – samo priprema za buduću uporabu.
//

import Foundation
import CryptoKit

#if canImport(Security)
import Security
#endif

// MARK: - Secure Enclave Key Manager (priprema)

/// Upravljanje ključem u Secure Enclave – P256, samo na podržanim uređajima.
/// Lozinka za dešifriranje vaulta NE smije biti u kodu; ovdje se koristi SE ključ za seal/unseal.
enum VaultSecureEnclaveKey {

    private static let keychainService = "com.alexandria.vault.sekey"
    private static let keychainAccount = "vault-secure-enclave-key"

    /// Je li Secure Enclave dostupan (Apple Silicon / T2)? Na iOS postoji isAvailable; na macOS uzimamo da je dostupan od 10.15+ (T2/M1+).
    static var isSecureEnclaveAvailable: Bool {
        if #available(macOS 10.15, *) {
            #if os(iOS)
            return SecureEnclave.P256.Signing.PrivateKey.isAvailable
            #else
            return true
            #endif
        }
        return false
    }

    /// Generira novi privatni ključ u Secure Enclave. Vraća dataRepresentation za perzistenciju u Keychain – ključ sam nikad ne napušta čip.
    @available(macOS 10.15, *)
    static func generateNewKey() throws -> Data {
        let privateKey = try SecureEnclave.P256.Signing.PrivateKey()
        return privateKey.dataRepresentation
    }

    /// Učitava postojeći SE ključ iz Keychaina (dataRepresentation). Deserializacija radi samo na istom uređaju i u istom app ID-u.
    @available(macOS 10.15, *)
    static func loadKeyFromKeychain() throws -> SecureEnclave.P256.Signing.PrivateKey {
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw VaultSecureEnclaveError.keyNotFoundInKeychain
        }
        return try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: data)
        #else
        throw VaultSecureEnclaveError.keychainUnavailable
        #endif
    }

    /// Sprema dataRepresentation ključa u Keychain (ne spremamo sam ključ – samo referencu koju samo ovaj čip može koristiti).
    @available(macOS 10.15, *)
    static func saveKeyToKeychain(_ dataRepresentation: Data) throws {
        #if canImport(Security)
        try? deleteKeyFromKeychain()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: dataRepresentation,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw VaultSecureEnclaveError.keychainAddFailed(status)
        }
        #else
        throw VaultSecureEnclaveError.keychainUnavailable
        #endif
    }

    /// Briše SE ključ iz Keychaina (samo referenca – sam ključ je u čipu).
    static func deleteKeyFromKeychain() throws {
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
        #endif
    }

    /// Seal (šifriraj) passphrase koristeći SE ključ. Ključ nikad ne napušta čip; deriviramo simetrični ključ za AES-GCM.
    @available(macOS 10.15, *)
    static func sealPassphrase(_ passphrase: Data, with privateKey: SecureEnclave.P256.Signing.PrivateKey) throws -> Data {
        let symKey = symmetricKeyFromSEKey(privateKey)
        let sealed = try AES.GCM.seal(passphrase, using: symKey)
        guard let combined = sealed.combined else { throw VaultSecureEnclaveError.sealFailed }
        return combined
    }

    /// Unseal (dešifriraj) – samo s istim SE ključem na istom uređaju.
    @available(macOS 10.15, *)
    static func unsealPassphrase(_ sealed: Data, with privateKey: SecureEnclave.P256.Signing.PrivateKey) throws -> Data {
        let symKey = symmetricKeyFromSEKey(privateKey)
        let box = try AES.GCM.SealedBox(combined: sealed)
        return try AES.GCM.open(box, using: symKey)
    }

    /// Derivira simetrični ključ iz device-bound SE ključa (KDF). Samo ovaj uređaj može reproducirati isti ključ.
    @available(macOS 10.15, *)
    private static func symmetricKeyFromSEKey(_ privateKey: SecureEnclave.P256.Signing.PrivateKey) -> SymmetricKey {
        var hasher = SHA256()
        hasher.update(data: privateKey.dataRepresentation)
        hasher.update(data: Data("alexandria.vault.seal".utf8))
        let digest = hasher.finalize()
        return SymmetricKey(data: Data(digest))
    }
}

// MARK: - Greške

enum VaultSecureEnclaveError: LocalizedError {
    case keyNotFoundInKeychain
    case keychainUnavailable
    case keychainAddFailed(OSStatus)
    case sealFailed

    var errorDescription: String? {
        switch self {
        case .keyNotFoundInKeychain: return "Secure Enclave ključ nije pronađen u Keychainu."
        case .keychainUnavailable: return "Keychain nije dostupan."
        case .keychainAddFailed(let s): return "Spremanje u Keychain nije uspjelo (OSStatus \(s))."
        case .sealFailed: return "Seal (šifriranje) nije uspjelo."
        }
    }
}
