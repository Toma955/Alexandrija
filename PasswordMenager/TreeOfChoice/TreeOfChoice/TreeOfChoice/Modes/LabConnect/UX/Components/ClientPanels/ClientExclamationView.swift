//
//  ClientExclamationView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Exclamation/Alert komponentu u Client panelu
struct ClientExclamationView: View {
    @Binding var isPresented: Bool
    let clientName: String // "Client A" ili "Client B"
    @State private var alerts: [AlertEntry] = []
    
    struct AlertEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let title: String
        let message: String
        let severity: AlertSeverity
        
        enum AlertSeverity {
            case low, medium, high, critical
            
            var color: Color {
                switch self {
                case .low: return .green
                case .medium: return .yellow
                case .high: return .orange
                case .critical: return .red
                }
            }
            
            var icon: String {
                switch self {
                case .low: return "info.circle.fill"
                case .medium: return "exclamationmark.triangle.fill"
                case .high: return "exclamationmark.octagon.fill"
                case .critical: return "exclamationmark.triangle.fill"
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("\(clientName) - Alerts")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Alerts list
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if alerts.isEmpty {
                        Text("No alerts")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        ForEach(alerts) { alert in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: alert.severity.icon)
                                    .font(.title3)
                                    .foregroundColor(alert.severity.color)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(alert.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(alert.message)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text(alert.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.95))
        .cornerRadius(12)
        .onAppear {
            loadAlerts()
        }
    }
    
    private func loadAlerts() {
        // TODO: Load actual alerts for the client
        // For now, add sample alerts
        alerts = [
            AlertEntry(timestamp: Date(), title: "Connection Warning", message: "High latency detected", severity: .medium),
            AlertEntry(timestamp: Date().addingTimeInterval(-30), title: "Network Status", message: "All systems operational", severity: .low),
        ]
    }
}

