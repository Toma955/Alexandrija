//
//  VaultSparseBundle.swift
//  Alexandria
//
//  Priprema: Kriptirani Sparse Bundle (sistemska izolacija).
//  Virtualni disk koji raste s podacima, AES-256, montiran s -nobrowse.
//  Opcijski MNT_NOEXEC / MNT_NOSUID za no-exec i sandboxing na razini kernela.
//  NIGDJE SE NE UKLJUČUJE – samo priprema za buduću uporabu.
//

import Foundation

// MARK: - Konfiguracija vaulta

struct VaultSparseBundleConfig {
    /// Pun put do .sparsebundle (npr. Application Support/.../Vault.sparsebundle)
    var bundlePath: String
    /// Ime volumena kad je montiran
    var volumeName: String = "AlexandriaVault"
    /// Početna veličina (npr. "100m", "1g") – sparse raste po potrebi
    var size: String = "100m"
    /// Mount point (npr. privremeni dir koji nije u /Volumes da bude -nobrowse ekvivalent)
    var mountPoint: String?
}

// MARK: - Encrypted Sparse Bundle Manager (priprema)

enum VaultSparseBundleManager {

    /// Kreira novi kriptirani sparse bundle (AES-256). Lozinka se predaje preko stdin pipea – nikad u argumentima.
    static func createEncryptedSparseBundle(config: VaultSparseBundleConfig, passphrase: Data) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = [
            "create",
            "-encryption", "AES-256",
            "-volname", config.volumeName,
            "-size", config.size,
            "-type", "SPARSEBUNDLE",
            "-stdinpass",
            config.bundlePath
        ]
        let pipe = Pipe()
        process.standardInput = pipe
        process.standardError = Pipe()
        try process.run()
        let passphraseWithNewline = passphrase + [0x0a]
        pipe.fileHandleForWriting.write(passphraseWithNewline)
        pipe.fileHandleForWriting.closeFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw VaultSparseBundleError.hdiutilCreateFailed(exitCode: Int(process.terminationStatus))
        }
    }

    /// Montira sparse bundle. -nobrowse = ne prikazuje se u Finderu. Lozinka preko stdin.
    /// volumeName: ime volumena (npr. iz config.volumeName) da se vrati putanja /Volumes/volumeName.
    static func attachSparseBundle(bundlePath: String, passphrase: Data, volumeName: String, nobrowse: Bool = true) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        var args = ["attach", bundlePath, "-stdinpass"]
        if nobrowse { args.append("-nobrowse") }
        process.arguments = args
        let pipe = Pipe()
        process.standardInput = pipe
        let errPipe = Pipe()
        process.standardError = errPipe
        try process.run()
        pipe.fileHandleForWriting.write(passphrase + [0x0a])
        pipe.fileHandleForWriting.closeFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errData, encoding: .utf8) ?? ""
            throw VaultSparseBundleError.hdiutilAttachFailed(exitCode: Int(process.terminationStatus), message: errStr)
        }
        return "/Volumes/\(volumeName)"
    }

    /// Odmontira volumen.
    static func detach(volumePath: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["detach", volumePath, "-force"]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw VaultSparseBundleError.hdiutilDetachFailed(exitCode: Int(process.terminationStatus))
        }
    }

    /// Remount postojećeg volumena s MNT_NOEXEC i MNT_NOSUID – kernel odbija izvršavati kod s tog diska.
    /// Na macOS se može koristiti mount -u -o noexec,nosuid &lt;path&gt; ili mount(2) s MNT_UPDATE.
    /// Zahtijeva odgovarajuće entitlements; u sandboxu može biti ograničeno.
    static func remountWithNoExecNoSuid(mountPointPath: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/mount")
        process.arguments = ["-u", "-o", "noexec,nosuid", mountPointPath]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw VaultSparseBundleError.remountFailed(exitCode: Int(process.terminationStatus))
        }
    }
}

// MARK: - Greške

enum VaultSparseBundleError: LocalizedError {
    case hdiutilCreateFailed(exitCode: Int)
    case hdiutilAttachFailed(exitCode: Int, message: String)
    case hdiutilDetachFailed(exitCode: Int)
    case remountFailed(exitCode: Int)

    var errorDescription: String? {
        switch self {
        case .hdiutilCreateFailed(let c): return "hdiutil create nije uspio (exit \(c))."
        case .hdiutilAttachFailed(let c, let m): return "hdiutil attach nije uspio (exit \(c)): \(m)"
        case .hdiutilDetachFailed(let c): return "hdiutil detach nije uspio (exit \(c))."
        case .remountFailed(let c): return "Remount s MNT_NOEXEC/MNT_NOSUID nije uspio (exit \(c))."
        }
    }
}
