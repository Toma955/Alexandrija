//
//  DownloadTracker.swift
//  Alexandria
//
//  Praćenje preuzetih datoteka za Dev Mode.
//

import Foundation
import SwiftUI

@MainActor
final class DownloadTracker: ObservableObject {
    static let shared = DownloadTracker()
    
    @Published private(set) var records: [DownloadRecord] = []
    
    private init() {}
    
    func add(url: String, filename: String, sizeBytes: Int64? = nil) {
        records.insert(DownloadRecord(url: url, filename: filename, date: Date(), sizeBytes: sizeBytes), at: 0)
    }
    
    func clear() {
        records.removeAll()
    }
}
