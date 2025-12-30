//
//  MultiConnectSettingsView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct MultiConnectSettingsView: View {
    @Binding var isPresented: Bool
    @Binding var serverAddress: String
    @State private var tempServerAddress: String = ""
    @State private var isPinging = false
    @State private var pingResult: PingResult? = nil
    
    enum PingResult {
        case success(String)
        case failure(String)
        
        var color: Color {
            switch self {
            case .success: return .green
            case .failure: return .red
            }
        }
        
        var message: String {
            switch self {
            case .success(let msg): return "✓ \(msg)"
            case .failure(let msg): return "✗ \(msg)"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Network Settings")
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
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.horizontal, 20)
            
            // Server Address
            VStack(alignment: .leading, spacing: 12) {
                Text("Server Address")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    TextField("https://amessagesserver.onrender.com", text: $tempServerAddress)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.1))
                        )
                        .foregroundColor(.white)
                        .font(.system(size: 13, design: .monospaced))
                    
                    // Ping botun
                    Button(action: {
                        pingServer()
                    }) {
                        HStack(spacing: 6) {
                            if isPinging {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: "network")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            
                            Text("Ping")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.36, blue: 0.0).opacity(0.8))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isPinging || tempServerAddress.isEmpty)
                }
                
                // Ping result
                if let result = pingResult {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(result.color)
                            .frame(width: 8, height: 8)
                        
                        Text(result.message)
                            .font(.caption)
                            .foregroundColor(result.color)
                    }
                    .padding(.leading, 4)
                }
                
                Text("Enter the server address for WebSocket connections")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Supports: https://domain.com, wss://domain.com, or IP address (e.g. 74.220.51.0:443)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Save button
            HStack {
                Spacer()
                
                Button(action: {
                    serverAddress = tempServerAddress
                    isPresented = false
                }) {
                    Text("Save")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.36, blue: 0.0))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(width: 500, height: 300)
        .background(Color.black.opacity(0.95))
        .cornerRadius(16)
        .onAppear {
            tempServerAddress = serverAddress
        }
    }
    
    private func pingServer() {
        guard !tempServerAddress.isEmpty else { return }
        
        isPinging = true
        pingResult = nil
        
        let urlString = tempServerAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: urlString) else {
            pingResult = .failure("Invalid URL format")
            isPinging = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isPinging = false
                
                if let error = error {
                    pingResult = .failure(error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        pingResult = .success("Server is alive (Status: \(httpResponse.statusCode))")
                    } else {
                        pingResult = .failure("Server returned status \(httpResponse.statusCode)")
                    }
                } else {
                    pingResult = .failure("Invalid response")
                }
            }
        }
        
        task.resume()
    }
}

