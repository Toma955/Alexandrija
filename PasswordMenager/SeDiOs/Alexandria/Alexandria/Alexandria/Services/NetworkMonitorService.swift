//
//  NetworkMonitorService.swift
//  Alexandria
//
//  Praćenje mrežne konekcije – NWPathMonitor.
//

import Foundation
import Network
import SwiftUI

/// Status mrežne konekcije
enum NetworkStatus {
    case connected
    case disconnected
    case unknown
}

/// Servis za praćenje interneta – zeleni globus kad je spojeno
final class NetworkMonitorService: ObservableObject {
    static let shared = NetworkMonitorService()
    
    @Published private(set) var status: NetworkStatus = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.alexandria.networkmonitor")
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.status = path.status == .satisfied ? .connected : .disconnected
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
