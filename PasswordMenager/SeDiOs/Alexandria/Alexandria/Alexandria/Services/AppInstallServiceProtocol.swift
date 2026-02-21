//
//  AppInstallServiceProtocol.swift
//  Alexandria
//

import Foundation

/// Apstrakcija servisa za instalaciju i učitavanje appova – omogućuje DI i testiranje.
protocol AppInstallServiceProtocol: AnyObject {
    func loadSource(for app: InstalledApp) throws -> String
    func findInstalledApp(catalogId: String, name: String, zipHash: String?) -> InstalledApp?
}
