//
//  SettingsView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Settings view za aplikaciju
struct SettingsView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showAbout = false
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(localization.text("settings.title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(24)
            .background(Color.black.opacity(0.6))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Window settings
                    windowSettingsSection
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Language settings
                    languageSettingsSection
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // About and Exit buttons
                    aboutAndExitSection
                }
                .padding(24)
            }
        }
        .frame(width: 600, height: 500)
        .background(Color.black.opacity(0.95))
        .sheet(isPresented: $showAbout) {
            AboutView()
                .environmentObject(localization)
        }
    }
    
    // MARK: - Sections
    
    private var windowSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.text("settings.window"))
                .font(.headline)
                .foregroundColor(.white)
            
            // Fullscreen toggle
            Toggle(isOn: $appSettings.isFullscreen) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.text("settings.fullscreen"))
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text(localization.text("settings.fullscreenDescription"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .toggleStyle(.switch)
            .tint(accentOrange)
            .onChange(of: appSettings.isFullscreen) { newValue in
                toggleFullscreen(newValue)
            }
            
            if !appSettings.isFullscreen {
                // Window size controls
                VStack(alignment: .leading, spacing: 12) {
                    Text(localization.text("settings.windowSize"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localization.text("settings.width"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack {
                                Slider(value: $appSettings.windowWidth, in: 800...2560, step: 10)
                                Text("\(Int(appSettings.windowWidth))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 50)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localization.text("settings.height"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack {
                                Slider(value: $appSettings.windowHeight, in: 600...1440, step: 10)
                                Text("\(Int(appSettings.windowHeight))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 50)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private var languageSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.text("settings.language"))
                .font(.headline)
                .foregroundColor(.white)
            
            Picker("", selection: Binding(
                get: { 
                    localization.currentLanguage 
                },
                set: { newLanguage in
                    localization.loadLanguage(newLanguage)
                }
            )) {
                Text("Hrvatski").tag(SupportedLanguage.croatian)
                Text("English").tag(SupportedLanguage.english)
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var aboutAndExitSection: some View {
        HStack(spacing: 16) {
            // About button
            Button(action: {
                showAbout = true
            }) {
                HStack {
                    Image(systemName: "info.circle")
                    Text("About")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(accentOrange.opacity(0.8))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // Exit button
            Button(action: {
                exitApplication()
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("Exit")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.8))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Actions
    
    private func toggleFullscreen(_ isFullscreen: Bool) {
        #if os(macOS)
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                if isFullscreen && !window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                } else if !isFullscreen && window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
            }
        }
        #endif
    }
    
    private func exitApplication() {
        #if os(macOS)
        NSApplication.shared.terminate(nil)
        #else
        exit(0)
        #endif
    }
}

// MARK: - About View

struct AboutView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("About TreeOfChoice")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(24)
            .background(Color.black.opacity(0.6))
            
            // Content
            VStack(spacing: 20) {
                // App icon/logo placeholder
                Image(systemName: "tree")
                    .font(.system(size: 64))
                    .foregroundColor(accentOrange)
                
                // App name
                Text("TreeOfChoice")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                // Version
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Version \(version)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Decision Tree Management System")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("A powerful tool for creating, managing, and simulating decision trees for agent-based systems.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .padding(24)
        }
        .frame(width: 500, height: 400)
        .background(Color.black.opacity(0.95))
    }
}

