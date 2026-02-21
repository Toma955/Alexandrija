//
//  VaultConfig.swift
//  Alexandria
//
//  Priprema: Konfiguracija i orkestracija Vaulta (sparse bundle + Secure Enclave + mount flags + exclusion).
//  NIGDJE SE NE UKLJUČUJE – samo priprema za buduću uporabu.
//
//  Entitlements (za produkciju): u App Sandbox ograničiti com.apple.security.files.user-selected.read-write
//  na tu specifičnu Vault putanju; za remount s MNT_NOEXEC može biti potreban temporary exception ili helper.
//

import Foundation

// MARK: - Vault path i konstantni mount point

enum VaultConfig {
    /// Root mapa za vault sparse bundle (npr. Application Support/Alexandria/Vault)
    static func vaultBundleParentDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Alexandria", isDirectory: true)
            .appendingPathComponent("Vault", isDirectory: true)
    }

    /// Pun put do .sparsebundle datoteke
    static func vaultBundleURL() -> URL {
        vaultBundleParentDirectory().appendingPathComponent("Vault.sparsebundle", isDirectory: false)
    }

    /// Ime volumena pri montiranju (-nobrowse ga skriva iz Findera)
    static let volumeName = "AlexandriaVault"
}

// MARK: - Vault orchestrator (stub – ne poziva se nigdje)

/// Jedan mjesto za buduću orkestraciju: kreiranje vaulta, montiranje s SE ključem, remount noexec, exclusion.
enum VaultOrchestrator {

    /// Stub: kada se uključi, redoslijed bi bio:
    /// 1. Provjera Secure Enclave dostupnosti
    /// 2. Generiranje ili učitavanje SE ključa iz Keychaina
    /// 3. Kreiranje sparse bundle (ako ne postoji) s passphrase, passphrase seal s SE ključem i pohrana
    /// 4. Attach sparse bundle s -nobrowse, passphrase iz unseal
    /// 5. Remount s MNT_NOEXEC / MNT_NOSUID
    /// 6. Primjena excludeFromTimeMachine i excludeFromSpotlightIndexing na mount point i na .sparsebundle datoteku
    /// 7. Pri zatvaranju appa: detach volumena (passphrase se ne drži u memoriji)
    static func prepareVaultIfNeeded() {
        // Namjerno prazno – priprema, ne uključeno
    }

    static func unlockVault() {
        // Namjerno prazno
    }

    static func lockVault() {
        // Namjerno prazno
    }
}
