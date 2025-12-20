//
//  AppSettings.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Centralized app settings storage
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @AppStorage("isFullscreen") var isFullscreen: Bool = false
    @AppStorage("windowWidth") var windowWidth: Double = 1400
    @AppStorage("windowHeight") var windowHeight: Double = 900
    
    private init() {}
    
    #if os(macOS)
    func setupFullscreen() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                if !window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
            }
        }
    }
    
    func setupWindowed() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                if window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                } else {
                    window.setContentSize(NSSize(width: self.windowWidth, height: self.windowHeight))
                    window.center()
                }
            }
        }
    }
    #endif
}

