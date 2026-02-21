//
//  AppEnvironment.swift
//  Alexandria
//

import SwiftUI

private struct AppInstallServiceKey: EnvironmentKey {
    static let defaultValue: AppInstallServiceProtocol = AppInstallService.shared
}

private struct ConsoleStoreKey: EnvironmentKey {
    static let defaultValue: ConsoleStore = ConsoleStore.shared
}

extension EnvironmentValues {
    var appInstallService: AppInstallServiceProtocol {
        get { self[AppInstallServiceKey.self] }
        set { self[AppInstallServiceKey.self] = newValue }
    }

    var consoleStore: ConsoleStore {
        get { self[ConsoleStoreKey.self] }
        set { self[ConsoleStoreKey.self] = newValue }
    }
}
