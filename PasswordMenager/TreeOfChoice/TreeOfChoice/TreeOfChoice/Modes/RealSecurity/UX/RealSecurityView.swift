//
//  RealSecurityView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Real Security mod - treniranje Security agenta u stvarnim uvjetima
struct RealSecurityView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
            
            VStack(spacing: 0) {
                headerView
                mainContentView
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.text("mode.realSecurity.title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(localization.text("mode.realSecurity.description"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(Color.black.opacity(0.6))
    }
    
    private var mainContentView: some View {
        HStack(spacing: 0) {
            leftPanel.frame(width: 300)
            Divider().background(Color.white.opacity(0.2))
            monitoringArea.frame(maxWidth: .infinity)
            Divider().background(Color.white.opacity(0.2))
            rightPanel.frame(width: 300)
        }
    }
    
    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.text("realSecurity.controls"))
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.text("realSecurity.selectTree"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Button(action: {}) {
                    HStack {
                        Text(localization.text("realSecurity.noTreeSelected"))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "play.fill")
                    Text(localization.text("realSecurity.startMonitoring"))
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(accentOrange)
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.black.opacity(0.4))
    }
    
    private var monitoringArea: some View {
        VStack(spacing: 20) {
            AgentVisualizationView(name: "Security Agent", isActive: true)
            
            VStack(spacing: 8) {
                Text(localization.text("realSecurity.monitoringStatus"))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(localization.text("realSecurity.active"))
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color.black.opacity(0.2))
    }
    
    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.text("realSecurity.status"))
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                StatusIndicatorView(
                    label: localization.text("realSecurity.threatsDetected"),
                    value: "0",
                    color: .white
                )
                
                StatusIndicatorView(
                    label: localization.text("realSecurity.anomalies"),
                    value: "0",
                    color: .white
                )
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.black.opacity(0.4))
    }
}







