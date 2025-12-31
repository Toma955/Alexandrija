//
//  RealConnectTopologyView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

/// View za vizualizaciju mrežne topologije u RealConnect modu
struct RealConnectTopologyView: View {
    @ObservedObject var roomSessionA: RoomSessionManager
    @ObservedObject var roomSessionB: RoomSessionManager
    let serverAddress: String
    let clientACode: String
    let clientBCode: String
    
    @StateObject private var networkInfoA = NetworkInfoManager.shared // Za Client A
    @StateObject private var networkInfoB = NetworkInfoManager.shared // Za Client B
    
    @State private var gatewayA: String = "192.168.1.1" // Gateway za Client A (default)
    @State private var gatewayB: String = "192.168.1.2" // Gateway za Client B (različit od Client A)
    
    /// Provjeri jesu li oba clienta spojena (za prikaz gatewaya i detalja)
    private var bothClientsConnected: Bool {
        roomSessionA.isSessionReady && roomSessionB.isSessionReady
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            topologyHeader
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Topology visualization (uvijek prikazuj trokut)
            topologyVisualization
            
            // Footer info
            if roomSessionA.isSessionReady || roomSessionB.isSessionReady {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                topologyFooter
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .onAppear {
            networkInfoA.setServerIP(from: serverAddress)
            networkInfoB.setServerIP(from: serverAddress)
            // Ne inicijaliziraj mrežne informacije odmah - samo postavi default gateway IP-ove
            // Gateway IP-ovi će se ažurirati tek nakon spajanja
        }
        .onChange(of: serverAddress) { newAddress in
            networkInfoA.setServerIP(from: newAddress)
            networkInfoB.setServerIP(from: newAddress)
        }
        .onChange(of: roomSessionA.isSessionReady) { isReady in
            if isReady && roomSessionB.isSessionReady {
                // Kada su oba clienta spojena, osvježi mrežne informacije
                refreshNetworkInfoAfterConnection()
            }
        }
        .onChange(of: roomSessionB.isSessionReady) { isReady in
            if isReady && roomSessionA.isSessionReady {
                // Kada su oba clienta spojena, osvježi mrežne informacije
                refreshNetworkInfoAfterConnection()
            }
        }
    }
    
    // MARK: - Header
    
    private var topologyHeader: some View {
        HStack {
            Text("Network Topology")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            // Server status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(serverStatusColor)
                    .frame(width: 8, height: 8)
                Text(serverAddress.isEmpty ? "Default Server" : serverAddress)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Visualization
    
    private var topologyVisualization: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.clear
                
                // Connection lines (različite ovisno o tome jesu li spojeni)
                connectionLines(geometry: geometry)
                
                // Nodes - različiti layout ovisno o tome jesu li spojeni
                if bothClientsConnected {
                    // Layout s gatewayima (nakon spajanja)
                    layoutWithGateways(geometry: geometry)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    // Početni trokutni layout (samo Client A, Client B, Server)
                    initialTriangleLayout(geometry: geometry)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
        .padding(16)
        .animation(.easeInOut(duration: 0.5), value: bothClientsConnected)
    }
    
    /// Početni trokutni layout - samo Client A, Client B i Server (bez gatewaya i detalja)
    @ViewBuilder
    private func initialTriangleLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Server gore u sredini
            HStack {
                Spacer()
                topologyNode(
                    label: "Relay Server",
                    isConnected: false,
                    geometry: geometry,
                    isServer: true,
                    showDetails: false
                )
                .frame(width: 120)
                Spacer()
            }
            .frame(height: geometry.size.height * 0.4)
            
            Spacer()
            
            // Client A i B dolje (rašireni)
            HStack(spacing: 0) {
                // Client A lijevo (rašireno)
                HStack {
                    Spacer()
                    topologyNode(
                        label: "Client A",
                        isConnected: false,
                        geometry: geometry,
                        showDetails: false
                    )
                    .frame(width: 120)
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.35)
                
                Spacer()
                
                // Client B desno (rašireno)
                HStack {
                    Spacer()
                    topologyNode(
                        label: "Client B",
                        isConnected: false,
                        geometry: geometry,
                        showDetails: false
                    )
                    .frame(width: 120)
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.35)
            }
            .frame(height: geometry.size.height * 0.4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Layout s gatewayima - prikazuje se nakon što se oba clienta spoje
    @ViewBuilder
    private func layoutWithGateways(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Server gore u sredini
            HStack {
                Spacer()
                topologyNode(
                    label: "Relay Server",
                    isConnected: roomSessionA.isSessionReady || roomSessionB.isSessionReady,
                    geometry: geometry,
                    isServer: true,
                    serverIP: networkInfoA.serverIP,
                    showDetails: true
                )
                .frame(width: 120)
                Spacer()
            }
            .frame(height: geometry.size.height * 0.25)
            
            Spacer()
            
            // Gateway A i Gateway B u sredini
            HStack(spacing: 0) {
                // Gateway A lijevo (između Client A i Server)
                HStack {
                    Spacer()
                    topologyNode(
                        label: "Gateway A",
                        isConnected: true,
                        geometry: geometry,
                        isGateway: true,
                        privateIP: networkInfoA.privateIP,
                        publicIP: networkInfoA.publicIP,
                        macAddress: networkInfoA.macAddress,
                        gateway: gatewayA,
                        showDetails: true
                    )
                    .frame(width: 120)
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.35)
                
                Spacer()
                
                // Gateway B desno (između Client B i Server)
                HStack {
                    Spacer()
                    topologyNode(
                        label: "Gateway B",
                        isConnected: true,
                        geometry: geometry,
                        isGateway: true,
                        privateIP: networkInfoB.privateIP,
                        publicIP: networkInfoB.publicIP,
                        macAddress: networkInfoB.macAddress,
                        gateway: gatewayB,
                        showDetails: true
                    )
                    .frame(width: 120)
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.35)
            }
            .frame(height: geometry.size.height * 0.25)
            
            Spacer()
            
            // Client A i B dolje (rašireni)
            HStack(spacing: 0) {
                // Client A lijevo (rašireno)
                HStack {
                    Spacer()
                    topologyNode(
                        label: "Client A",
                        isConnected: roomSessionA.isSessionReady,
                        geometry: geometry,
                        roomCode: clientACode,
                        messageCount: roomSessionA.messages.count,
                        privateIP: networkInfoA.privateIP,
                        publicIP: networkInfoA.publicIP,
                        port: networkInfoA.port,
                        gateway: gatewayA,
                        showDetails: true
                    )
                    .frame(width: 120)
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.35)
                
                Spacer()
                
                // Client B desno (rašireno)
                HStack {
                    Spacer()
                    topologyNode(
                        label: "Client B",
                        isConnected: roomSessionB.isSessionReady,
                        geometry: geometry,
                        roomCode: clientBCode,
                        messageCount: roomSessionB.messages.count,
                        privateIP: networkInfoB.privateIP,
                        publicIP: networkInfoB.publicIP,
                        port: networkInfoB.port,
                        gateway: gatewayB,
                        showDetails: true
                    )
                    .frame(width: 120)
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.35)
            }
            .frame(height: geometry.size.height * 0.4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Footer
    
    private var topologyFooter: some View {
        HStack(spacing: 16) {
            if roomSessionA.isSessionReady && !clientACode.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                        .foregroundColor(.green.opacity(0.8))
                    Text("Room: \(clientACode)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            if roomSessionA.isSessionReady || roomSessionB.isSessionReady {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.orange.opacity(0.8))
                    Text("E2E Encrypted")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            if roomSessionB.isSessionReady && !clientBCode.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                        .foregroundColor(.green.opacity(0.8))
                    Text("Room: \(clientBCode)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Properties
    
    private var serverStatusColor: Color {
        if roomSessionA.isSessionReady || roomSessionB.isSessionReady {
            return .green
        } else {
            return .gray
        }
    }
    
    /// Inicijaliziraj mrežne informacije odmah pri pokretanju
    private func initializeNetworkInfo() {
        // Provjeri mrežne informacije za Client A
        networkInfoA.refreshNetworkInfo()
        
        // Za Client B, koristi iste mrežne informacije ali simuliraj različit gateway
        networkInfoB.refreshNetworkInfo()
        
        // Postavi gatewaye - Client A i B moraju imati različite gatewaye
        gatewayA = networkInfoA.gatewayIP
        
        // Za Client B, simuliraj različit gateway (uvijek različit)
        if !gatewayA.isEmpty && gatewayA != "Unknown" {
            let gatewayParts = gatewayA.components(separatedBy: ".")
            if gatewayParts.count == 4, let lastOctet = Int(gatewayParts[3]) {
                // Promijeni zadnji oktet za različit gateway
                let newLastOctet = (lastOctet + 1) % 255
                if newLastOctet == 0 {
                    gatewayB = "\(gatewayParts[0]).\(gatewayParts[1]).\(gatewayParts[2]).2"
                } else {
                    gatewayB = "\(gatewayParts[0]).\(gatewayParts[1]).\(gatewayParts[2]).\(newLastOctet)"
                }
            } else {
                gatewayB = "192.168.1.2" // Fallback
            }
        } else {
            // Default različiti gatewayi
            gatewayA = "192.168.1.1"
            gatewayB = "192.168.1.2"
        }
    }
    
    /// Osvježi mrežne informacije nakon što su se oba clienta spojila
    private func refreshNetworkInfoAfterConnection() {
        // Osvježi informacije kada su oba clienta spojena
        networkInfoA.refreshNetworkInfo()
        networkInfoB.refreshNetworkInfo()
        
        // Ažuriraj gatewaye (osiguraj da su različiti)
        if networkInfoA.gatewayIP != "Unknown" {
            gatewayA = networkInfoA.gatewayIP
            // Za Client B, osiguraj različit gateway
            let gatewayParts = gatewayA.components(separatedBy: ".")
            if gatewayParts.count == 4, let lastOctet = Int(gatewayParts[3]) {
                let newLastOctet = (lastOctet + 1) % 255
                if newLastOctet == 0 {
                    gatewayB = "\(gatewayParts[0]).\(gatewayParts[1]).\(gatewayParts[2]).2"
                } else {
                    gatewayB = "\(gatewayParts[0]).\(gatewayParts[1]).\(gatewayParts[2]).\(newLastOctet)"
                }
            }
        }
    }
    
    
    // MARK: - Connection Lines
    
    @ViewBuilder
    private func connectionLines(geometry: GeometryProxy) -> some View {
        if bothClientsConnected {
            // Layout s gatewayima: Client A → Gateway A → Server ← Gateway B ← Client B
            drawGatewayLines(geometry: geometry)
        } else {
            // Početni trokutni layout: Client A → Server ← Client B (bez gatewaya)
            drawInitialTriangleLines(geometry: geometry)
        }
    }
    
    /// Početne linije - samo trokut (Client A → Server ← Client B)
    @ViewBuilder
    private func drawInitialTriangleLines(geometry: GeometryProxy) -> some View {
        // Pozicije centara u trokutnom layoutu
        let serverX = geometry.size.width / 2
        let serverY = geometry.size.height * 0.2 // Server gore
        let clientAY = geometry.size.height * 0.8 // Client A dolje lijevo
        let clientBY = geometry.size.height * 0.8 // Client B dolje desno
        
        // Rašireni clienti - više razdvojeni
        let clientAX = geometry.size.width * 0.15 // Client A lijevo (rašireno)
        let clientBX = geometry.size.width * 0.85 // Client B desno (rašireno)
        
        // Radijusi krugova
        let serverRadius: CGFloat = 30 // Server circle radius (60/2)
        let clientRadius: CGFloat = 25 // Client circle radius (50/2)
        
        // Faktor za "malo manje od pola" - linija završava na ~40% radijusa servera
        let serverConnectionFactor: CGFloat = 0.4 // 40% radijusa umjesto 100%
        
        // Izračunaj točke na rubovima krugova
        // Client A to Server
        let clientAToServerAngle = atan2(serverY - clientAY, serverX - clientAX)
        // Počinje na rubu Client A kruga
        let clientAStartX = clientAX + cos(clientAToServerAngle) * clientRadius
        let clientAStartY = clientAY + sin(clientAToServerAngle) * clientRadius
        // Završava malo prije ruba Server kruga (40% radijusa)
        let serverEndX = serverX - cos(clientAToServerAngle) * serverRadius * serverConnectionFactor
        let serverEndY = serverY - sin(clientAToServerAngle) * serverRadius * serverConnectionFactor
        
        // Server to Client B
        let serverToClientBAngle = atan2(clientBY - serverY, clientBX - serverX)
        // Počinje malo prije ruba Server kruga (40% radijusa)
        let serverStartX = serverX + cos(serverToClientBAngle) * serverRadius * serverConnectionFactor
        let serverStartY = serverY + sin(serverToClientBAngle) * serverRadius * serverConnectionFactor
        // Završava na rubu Client B kruga
        let clientBEndX = clientBX - cos(serverToClientBAngle) * clientRadius
        let clientBEndY = clientBY - sin(serverToClientBAngle) * clientRadius
        
        // Client A to Server (siva linija od ruba Client A do malo prije ruba Server)
        Path { path in
            path.move(to: CGPoint(x: clientAStartX, y: clientAStartY))
            path.addLine(to: CGPoint(x: serverEndX, y: serverEndY))
        }
        .stroke(
            Color.gray.opacity(0.6),
            style: StrokeStyle(lineWidth: 2)
        )
        
        // Server to Client B (siva linija od malo prije ruba Server do ruba Client B)
        Path { path in
            path.move(to: CGPoint(x: serverStartX, y: serverStartY))
            path.addLine(to: CGPoint(x: clientBEndX, y: clientBEndY))
        }
        .stroke(
            Color.gray.opacity(0.6),
            style: StrokeStyle(lineWidth: 2)
        )
    }
    
    /// Linije s gatewayima: Client A → Gateway A → Server ← Gateway B ← Client B
    @ViewBuilder
    private func drawGatewayLines(geometry: GeometryProxy) -> some View {
        // Pozicije centara
        let serverX = geometry.size.width / 2
        let serverY = geometry.size.height * 0.125 // Server gore (25% visine)
        let gatewayAY = geometry.size.height * 0.5 // Gateway A u sredini (50% visine)
        let gatewayBY = geometry.size.height * 0.5 // Gateway B u sredini (50% visine)
        let clientAY = geometry.size.height * 0.8 // Client A dolje lijevo
        let clientBY = geometry.size.height * 0.8 // Client B dolje desno
        
        // Rašireni clienti i gatewayi
        let clientAX = geometry.size.width * 0.15 // Client A lijevo
        let gatewayAX = geometry.size.width * 0.15 // Gateway A lijevo
        let gatewayBX = geometry.size.width * 0.85 // Gateway B desno
        let clientBX = geometry.size.width * 0.85 // Client B desno
        
        // Radijusi krugova
        let serverRadius: CGFloat = 30
        let gatewayRadius: CGFloat = 25
        let clientRadius: CGFloat = 25
        
        // Faktor za "malo manje od pola"
        let connectionFactor: CGFloat = 0.4
        
        // Client A to Gateway A
        let clientAToGatewayAAngle = atan2(gatewayAY - clientAY, gatewayAX - clientAX)
        let clientAStartX = clientAX + cos(clientAToGatewayAAngle) * clientRadius
        let clientAStartY = clientAY + sin(clientAToGatewayAAngle) * clientRadius
        let gatewayAEndX = gatewayAX - cos(clientAToGatewayAAngle) * gatewayRadius * connectionFactor
        let gatewayAEndY = gatewayAY - sin(clientAToGatewayAAngle) * gatewayRadius * connectionFactor
        
        // Gateway A to Server
        let gatewayAToServerAngle = atan2(serverY - gatewayAY, serverX - gatewayAX)
        let gatewayAStartX = gatewayAX + cos(gatewayAToServerAngle) * gatewayRadius * connectionFactor
        let gatewayAStartY = gatewayAY + sin(gatewayAToServerAngle) * gatewayRadius * connectionFactor
        let serverEndAX = serverX - cos(gatewayAToServerAngle) * serverRadius * connectionFactor
        let serverEndAY = serverY - sin(gatewayAToServerAngle) * serverRadius * connectionFactor
        
        // Server to Gateway B
        let serverToGatewayBAngle = atan2(gatewayBY - serverY, gatewayBX - serverX)
        let serverStartBX = serverX + cos(serverToGatewayBAngle) * serverRadius * connectionFactor
        let serverStartBY = serverY + sin(serverToGatewayBAngle) * serverRadius * connectionFactor
        let gatewayBEndX = gatewayBX - cos(serverToGatewayBAngle) * gatewayRadius * connectionFactor
        let gatewayBEndY = gatewayBY - sin(serverToGatewayBAngle) * gatewayRadius * connectionFactor
        
        // Gateway B to Client B
        let gatewayBToClientBAngle = atan2(clientBY - gatewayBY, clientBX - gatewayBX)
        let gatewayBStartX = gatewayBX + cos(gatewayBToClientBAngle) * gatewayRadius * connectionFactor
        let gatewayBStartY = gatewayBY + sin(gatewayBToClientBAngle) * gatewayRadius * connectionFactor
        let clientBEndX = clientBX - cos(gatewayBToClientBAngle) * clientRadius
        let clientBEndY = clientBY - sin(gatewayBToClientBAngle) * clientRadius
        
        // Client A to Gateway A (siva linija)
        Path { path in
            path.move(to: CGPoint(x: clientAStartX, y: clientAStartY))
            path.addLine(to: CGPoint(x: gatewayAEndX, y: gatewayAEndY))
        }
        .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 2))
        
        // Gateway A to Server (siva linija)
        Path { path in
            path.move(to: CGPoint(x: gatewayAStartX, y: gatewayAStartY))
            path.addLine(to: CGPoint(x: serverEndAX, y: serverEndAY))
        }
        .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 2))
        
        // Server to Gateway B (siva linija)
        Path { path in
            path.move(to: CGPoint(x: serverStartBX, y: serverStartBY))
            path.addLine(to: CGPoint(x: gatewayBEndX, y: gatewayBEndY))
        }
        .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 2))
        
        // Gateway B to Client B (siva linija)
        Path { path in
            path.move(to: CGPoint(x: gatewayBStartX, y: gatewayBStartY))
            path.addLine(to: CGPoint(x: clientBEndX, y: clientBEndY))
        }
        .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 2))
    }
    
    // MARK: - Topology Node
    
    @ViewBuilder
    private func topologyNode(
        label: String,
        isConnected: Bool,
        geometry: GeometryProxy,
        isServer: Bool = false,
        isSwitch: Bool = false,
        isGateway: Bool = false,
        roomCode: String = "",
        messageCount: Int = 0,
        privateIP: String = "",
        publicIP: String = "",
        macAddress: String = "",
        serverIP: String = "",
        port: String = "",
        gateway: String = "",
        showDetails: Bool = true
    ) -> some View {
        VStack(spacing: 6) {
            // Node circle
            ZStack {
                Circle()
                    .fill(isConnected ? (isServer ? Color.orange.opacity(0.8) : (isGateway ? Color.green.opacity(0.8) : (isSwitch ? Color.purple.opacity(0.8) : Color.blue.opacity(0.8)))) : Color.gray.opacity(0.5))
                    .frame(width: isServer ? 60 : (isGateway ? 50 : (isSwitch ? 50 : 50)), height: isServer ? 60 : (isGateway ? 50 : (isSwitch ? 50 : 50)))
                
                if isServer {
                    Image(systemName: "server.rack")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                } else if isGateway {
                    Image(systemName: "router.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                } else if isSwitch {
                    Image(systemName: "network")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: isConnected ? "laptopcomputer" : "laptopcomputer.slash")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Connection status indicator
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.3), lineWidth: 2)
                    )
                    .offset(x: isServer ? 20 : 18, y: isServer ? -20 : -18)
            }
            
            // Label
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.9))
            
            // Status text
            if showDetails {
                Text(isConnected ? "Connected" : "Disconnected")
                    .font(.caption2)
                    .foregroundColor(isConnected ? .green.opacity(0.8) : .red.opacity(0.8))
            }
            
            // IP adrese i MAC (za server i switch)
            if showDetails && isServer && !serverIP.isEmpty && serverIP != "Unknown" {
                Text("IP: \(serverIP)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if showDetails && isGateway {
                if !gateway.isEmpty && gateway != "Unknown" {
                    Text("Gateway: \(gateway)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                if !privateIP.isEmpty && privateIP != "Unknown" {
                    Text("Private: \(privateIP)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                if !publicIP.isEmpty && publicIP != "Unknown" {
                    Text("Public: \(publicIP)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                if !macAddress.isEmpty && macAddress != "Unknown" {
                    Text("MAC: \(macAddress)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            if showDetails && isSwitch {
                if !privateIP.isEmpty && privateIP != "Unknown" {
                    Text("Private: \(privateIP)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                if !publicIP.isEmpty && publicIP != "Unknown" {
                    Text("Public: \(publicIP)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                if !macAddress.isEmpty && macAddress != "Unknown" {
                    Text("MAC: \(macAddress)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // IP adrese i port (za Client A i B)
            if showDetails && !isServer && !isSwitch && !isGateway {
                if !privateIP.isEmpty && privateIP != "Unknown" {
                    Text("Private: \(privateIP)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                if !publicIP.isEmpty && publicIP != "Unknown" {
                    Text("Public: \(publicIP)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                if !port.isEmpty && port != "Unknown" {
                    Text("Port: \(port)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Message count (only for clients)
            if showDetails && !isServer && !isSwitch && !isGateway && isConnected && messageCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(messageCount)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

