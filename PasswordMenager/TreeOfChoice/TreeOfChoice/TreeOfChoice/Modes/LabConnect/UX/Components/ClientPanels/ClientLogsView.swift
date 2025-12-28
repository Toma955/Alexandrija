//
//  ClientLogsView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za Logs komponentu u Client panelu
struct ClientLogsView: View {
    @Binding var isPresented: Bool
    let clientName: String // "Client A" ili "Client B"
    @State private var logs: [LogEntry] = []
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let level: LogLevel
        
        enum LogLevel {
            case info, warning, error
            
            var color: Color {
                switch self {
                case .info: return .blue
                case .warning: return .orange
                case .error: return .red
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("\(clientName) - Logs")
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
            
            // Logs list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if logs.isEmpty {
                        Text("No logs available")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        ForEach(logs) { log in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(log.level.color)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.message)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(log.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
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
            loadLogs()
        }
    }
    
    private func loadLogs() {
        // TODO: Load actual logs for the client
        // For now, add sample logs
        logs = [
            LogEntry(timestamp: Date(), message: "Client connected", level: .info),
            LogEntry(timestamp: Date().addingTimeInterval(-10), message: "Network topology updated", level: .info),
            LogEntry(timestamp: Date().addingTimeInterval(-20), message: "Warning: High latency detected", level: .warning),
        ]
    }
}

