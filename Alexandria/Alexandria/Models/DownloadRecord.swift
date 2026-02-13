//
//  DownloadRecord.swift
//  Alexandria
//
//  Zapis preuzete datoteke za Dev Mode.
//

import Foundation

struct DownloadRecord: Identifiable {
    let id = UUID()
    let url: String
    let filename: String
    let date: Date
    let sizeBytes: Int64?
}
