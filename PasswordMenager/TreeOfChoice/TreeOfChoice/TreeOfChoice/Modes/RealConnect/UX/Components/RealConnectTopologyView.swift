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
    
    /// Početni layout - samo Client A, Client B i Server u horizontalnoj liniji (bez gatewaya i detalja)
    @ViewBuilder
    private func initialTriangleLayout(geometry: GeometryProxy) -> some View {
        let centerY = geometry.size.height / 2
        let padding: CGFloat = 40
        let nodeWidth: CGFloat = 120
        let clientRadius: CGFloat = 25
        let serverRadius: CGFloat = 30
        
        // Izračunaj pozicije centara
        let clientAX = padding + nodeWidth / 2
        let serverX = geometry.size.width / 2
        let clientBX = geometry.size.width - padding - nodeWidth / 2
        
        ZStack {
            // Client A lijevo
            topologyNode(
                label: "Client A",
                isConnected: false,
                geometry: geometry,
                showDetails: false
            )
            .frame(width: 120)
            .position(x: clientAX, y: centerY)
            
            // Server u sredini
            topologyNode(
                label: "Relay Server",
                isConnected: false,
                geometry: geometry,
                isServer: true,
                showDetails: false
            )
            .frame(width: 120)
            .position(x: serverX, y: centerY)
            
            // Client B desno
            topologyNode(
                label: "Client B",
                isConnected: false,
                geometry: geometry,
                showDetails: false
            )
            .frame(width: 120)
            .position(x: clientBX, y: centerY)
            
            // Crvene točke za spajanje linija (na vanjskom rubu kruga - 0° i 180°, malo iznad sredine)
            // Client A: desna strana (0° - vanjski rub, malo gore)
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: clientAX + clientRadius, y: centerY - clientRadius * 0.3)
            
            // Server: lijeva i desna strana (180° i 0° - vanjski rub, malo gore)
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: serverX - serverRadius, y: centerY - serverRadius * 0.3)
            
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: serverX + serverRadius, y: centerY - serverRadius * 0.3)
            
            // Client B: lijeva strana (180° - vanjski rub, malo gore)
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: clientBX - clientRadius, y: centerY - clientRadius * 0.3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Layout s gatewayima - prikazuje se nakon što se oba clienta spoje
    /// Client A, Server i Client B ostaju na istim pozicijama, gatewayi se dodaju između njih
    @ViewBuilder
    private func layoutWithGateways(geometry: GeometryProxy) -> some View {
        let centerY = geometry.size.height / 2
        let padding: CGFloat = 40
        let nodeWidth: CGFloat = 120
        let clientRadius: CGFloat = 25
        let gatewayRadius: CGFloat = 25
        let serverRadius: CGFloat = 30
        
        // Izračunaj pozicije centara - ISTE kao u initialTriangleLayout
        let clientAX = padding + nodeWidth / 2
        let serverX = geometry.size.width / 2
        let clientBX = geometry.size.width - padding - nodeWidth / 2
        
        // Gatewayi se stvaraju između elemenata (sredina između njih)
        let gatewayAX = (clientAX + serverX) / 2  // Sredina između Client A i Server
        let gatewayBX = (serverX + clientBX) / 2  // Sredina između Server i Client B
        
        ZStack {
            // Client A lijevo
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
            .position(x: clientAX, y: centerY)
            
            // Gateway A
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
            .position(x: gatewayAX, y: centerY)
            
            // Server u sredini
            topologyNode(
                label: "Relay Server",
                isConnected: roomSessionA.isSessionReady || roomSessionB.isSessionReady,
                geometry: geometry,
                isServer: true,
                serverIP: networkInfoA.serverIP,
                showDetails: true
            )
            .frame(width: 120)
            .position(x: serverX, y: centerY)
            
            // Gateway B
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
            .position(x: gatewayBX, y: centerY)
            
            // Client B desno
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
            .position(x: clientBX, y: centerY)
            
            // Crvene točke za spajanje linija (na vanjskom rubu kruga - 0° i 180°, malo iznad sredine)
            // Client A: desna strana (0° - vanjski rub, malo gore)
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: clientAX + clientRadius, y: centerY - clientRadius * 0.3)
            
            // Gateway A: lijeva i desna strana (180° i 0° - vanjski rub, malo gore)
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: gatewayAX - gatewayRadius, y: centerY - gatewayRadius * 0.3)
            
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: gatewayAX + gatewayRadius, y: centerY - gatewayRadius * 0.3)
            
            // Server: lijeva i desna strana (180° i 0° - vanjski rub, malo gore)
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: serverX - serverRadius, y: centerY - serverRadius * 0.3)
            
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: serverX + serverRadius, y: centerY - serverRadius * 0.3)
            
            // Gateway B: lijeva i desna strana (180° i 0° - vanjski rub, malo gore)
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: gatewayBX - gatewayRadius, y: centerY - gatewayRadius * 0.3)
            
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: gatewayBX + gatewayRadius, y: centerY - gatewayRadius * 0.3)
            
            // Client B: lijeva strana (180° - vanjski rub, malo gore)
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .position(x: clientBX - clientRadius, y: centerY - clientRadius * 0.3)
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
    
    /// Početne linije - horizontalna linija (Client A → Server ← Client B)
    @ViewBuilder
    private func drawInitialTriangleLines(geometry: GeometryProxy) -> some View {
        // Pozicije centara u horizontalnoj liniji
        let centerY = geometry.size.height / 2
        let padding: CGFloat = 40
        let nodeWidth: CGFloat = 120
        let spacing: CGFloat = 30
        
        // Izračunaj pozicije (sve u horizontalnoj liniji) - mora biti identično kao u layoutu
        let clientAX = padding + nodeWidth / 2
        let serverX = geometry.size.width / 2
        let clientBX = geometry.size.width - padding - nodeWidth / 2
        
        // Radijusi krugova
        let serverRadius: CGFloat = 30
        let clientRadius: CGFloat = 25
        
        // Linije idu od vanjskog ruba kruga do vanjskog ruba kruga (0° i 180°, malo iznad sredine)
        // Client A: desna strana (0° - vanjski rub, malo gore)
        let clientAConnectionX = clientAX + clientRadius
        let clientAConnectionY = centerY - clientRadius * 0.3
        // Server: lijeva strana (180° - vanjski rub, malo gore)
        let serverLeftConnectionX = serverX - serverRadius
        let serverLeftConnectionY = centerY - serverRadius * 0.3
        // Server: desna strana (0° - vanjski rub, malo gore)
        let serverRightConnectionX = serverX + serverRadius
        let serverRightConnectionY = centerY - serverRadius * 0.3
        // Client B: lijeva strana (180° - vanjski rub, malo gore)
        let clientBConnectionX = clientBX - clientRadius
        let clientBConnectionY = centerY - clientRadius * 0.3
        
        // Client A to Server (siva horizontalna linija - malo iznad sredine)
        Path { path in
            path.move(to: CGPoint(x: clientAConnectionX, y: clientAConnectionY))
            path.addLine(to: CGPoint(x: serverLeftConnectionX, y: serverLeftConnectionY))
        }
        .stroke(
            Color.gray.opacity(0.6),
            style: StrokeStyle(lineWidth: 2)
        )
        
        // Server to Client B (siva horizontalna linija - malo iznad sredine)
        Path { path in
            path.move(to: CGPoint(x: serverRightConnectionX, y: serverRightConnectionY))
            path.addLine(to: CGPoint(x: clientBConnectionX, y: clientBConnectionY))
        }
        .stroke(
            Color.gray.opacity(0.6),
            style: StrokeStyle(lineWidth: 2)
        )
    }
    
    /// Linije s gatewayima: Client A → Gateway A → Server ← Gateway B ← Client B (horizontalna linija)
    @ViewBuilder
    private func drawGatewayLines(geometry: GeometryProxy) -> some View {
        // Pozicije centara u horizontalnoj liniji - ISTE kao u layoutWithGateways
        let centerY = geometry.size.height / 2
        let padding: CGFloat = 40
        let nodeWidth: CGFloat = 120
        
        // Izračunaj pozicije - ISTE kao u layoutWithGateways
        let clientAX = padding + nodeWidth / 2
        let serverX = geometry.size.width / 2
        let clientBX = geometry.size.width - padding - nodeWidth / 2
        
        // Gatewayi se stvaraju između elemenata (sredina između njih)
        let gatewayAX = (clientAX + serverX) / 2  // Sredina između Client A i Server
        let gatewayBX = (serverX + clientBX) / 2  // Sredina između Server i Client B
        
        // Radijusi krugova
        let serverRadius: CGFloat = 30
        let gatewayRadius: CGFloat = 25
        let clientRadius: CGFloat = 25
        
        // Connection točke na vanjskom rubu kruga (0° i 180°, malo iznad sredine)
        // Client A: desna strana (0° - vanjski rub, malo gore)
        let clientAConnectionX = clientAX + clientRadius
        let clientAConnectionY = centerY - clientRadius * 0.3
        // Gateway A: lijeva i desna strana (180° i 0° - vanjski rub, malo gore)
        let gatewayALeftConnectionX = gatewayAX - gatewayRadius
        let gatewayALeftConnectionY = centerY - gatewayRadius * 0.3
        let gatewayARightConnectionX = gatewayAX + gatewayRadius
        let gatewayARightConnectionY = centerY - gatewayRadius * 0.3
        // Server: lijeva i desna strana (180° i 0° - vanjski rub, malo gore)
        let serverLeftConnectionX = serverX - serverRadius
        let serverLeftConnectionY = centerY - serverRadius * 0.3
        let serverRightConnectionX = serverX + serverRadius
        let serverRightConnectionY = centerY - serverRadius * 0.3
        // Gateway B: lijeva i desna strana (180° i 0° - vanjski rub, malo gore)
        let gatewayBLeftConnectionX = gatewayBX - gatewayRadius
        let gatewayBLeftConnectionY = centerY - gatewayRadius * 0.3
        let gatewayBRightConnectionX = gatewayBX + gatewayRadius
        let gatewayBRightConnectionY = centerY - gatewayRadius * 0.3
        // Client B: lijeva strana (180° - vanjski rub, malo gore)
        let clientBConnectionX = clientBX - clientRadius
        let clientBConnectionY = centerY - clientRadius * 0.3
        
        // Client A to Gateway A (siva horizontalna linija - malo iznad sredine)
        Path { path in
            path.move(to: CGPoint(x: clientAConnectionX, y: clientAConnectionY))
            path.addLine(to: CGPoint(x: gatewayALeftConnectionX, y: gatewayALeftConnectionY))
        }
        .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 2))
        
        // Gateway A to Server (siva horizontalna linija - malo iznad sredine)
        Path { path in
            path.move(to: CGPoint(x: gatewayARightConnectionX, y: gatewayARightConnectionY))
            path.addLine(to: CGPoint(x: serverLeftConnectionX, y: serverLeftConnectionY))
        }
        .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 2))
        
        // Server to Gateway B (siva horizontalna linija - malo iznad sredine)
        Path { path in
            path.move(to: CGPoint(x: serverRightConnectionX, y: serverRightConnectionY))
            path.addLine(to: CGPoint(x: gatewayBLeftConnectionX, y: gatewayBLeftConnectionY))
        }
        .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 2))
        
        // Gateway B to Client B (siva horizontalna linija - malo iznad sredine)
        Path { path in
            path.move(to: CGPoint(x: gatewayBRightConnectionX, y: gatewayBRightConnectionY))
            path.addLine(to: CGPoint(x: clientBConnectionX, y: clientBConnectionY))
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
        ZStack(alignment: .top) {
            // Node circle - fiksna pozicija na vrhu
            ZStack {
                let circleSize: CGFloat = isServer ? 60 : (isGateway ? 50 : (isSwitch ? 50 : 50))
                
                // Prozirna unutrašnjost za server, gateway i switch (siva boja)
                if isServer || isGateway || isSwitch {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: circleSize, height: circleSize)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.7), lineWidth: 2.5) // Sivi obrub - malo deblji i tamniji
                        )
                } else {
                    // Klijenti - normalna boja
                    Circle()
                        .fill(isConnected ? Color.blue.opacity(0.8) : Color.gray.opacity(0.5))
                        .frame(width: circleSize, height: circleSize)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.7), lineWidth: 2.5) // Sivi obrub - malo deblji i tamniji
                        )
                }
                
                // Ikone
                if isServer {
                    Image(systemName: "server.rack")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isConnected ? .green : .gray)
                } else if isGateway {
                    // Koristi Router.png ikonu
                    if let routerImage = loadRouterIcon() {
                        Image(nsImage: routerImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .colorMultiply(isConnected ? .green.opacity(0.9) : .gray.opacity(0.9))
                    } else {
                        Image(systemName: "router.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isConnected ? .green : .gray)
                    }
                } else if isSwitch {
                    Image(systemName: "network")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isConnected ? .green : .gray)
                } else {
                    Image(systemName: isConnected ? "laptopcomputer" : "laptopcomputer.slash")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isConnected ? .green : .white)
                }
            }
            .frame(width: 120, height: 60) // Fiksna visina za krug
            
            // Label i detalji ispod kruga
            VStack(spacing: 4) {
                Spacer()
                    .frame(height: 60) // Visina kruga
                
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
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                if showDetails && isGateway {
                    if !gateway.isEmpty && gateway != "Unknown" {
                        Text("Gateway: \(gateway)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    if !privateIP.isEmpty && privateIP != "Unknown" {
                        Text("Private: \(privateIP)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    if !publicIP.isEmpty && publicIP != "Unknown" {
                        Text("Public: \(publicIP)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    if !macAddress.isEmpty && macAddress != "Unknown" {
                        Text("MAC: \(macAddress)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                if showDetails && isSwitch {
                    if !privateIP.isEmpty && privateIP != "Unknown" {
                        Text("Private: \(privateIP)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    if !publicIP.isEmpty && publicIP != "Unknown" {
                        Text("Public: \(publicIP)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    if !macAddress.isEmpty && macAddress != "Unknown" {
                        Text("MAC: \(macAddress)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // IP adrese i port (za Client A i B)
                if showDetails && !isServer && !isSwitch && !isGateway {
                    if !privateIP.isEmpty && privateIP != "Unknown" {
                        Text("Private: \(privateIP)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    if !publicIP.isEmpty && publicIP != "Unknown" {
                        Text("Public: \(publicIP)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    if !port.isEmpty && port != "Unknown" {
                        Text("Port: \(port)")
                            .font(.system(size: 9))
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
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(width: 120, alignment: .top)
    }
    
    // MARK: - Helper Methods
    
    /// Učitava Router.png ikonu iz Shared/UX/Icons foldera
    private func loadRouterIcon() -> NSImage? {
        // Pokušaj učitati iz Shared/UX/Icons foldera
        if let imageURL = Bundle.main.url(forResource: "Router", withExtension: "png", subdirectory: "Shared/UX/Icons") {
            if let image = NSImage(contentsOf: imageURL) {
                return image
            }
        }
        
        // Fallback: Pokušaj učitati direktno iz bundle-a
        if let imageURL = Bundle.main.url(forResource: "Router", withExtension: "png") {
            return NSImage(contentsOf: imageURL)
        }
        
        // Pokušaj učitati iz Assets.xcassets
        if let assetImage = NSImage(named: "Router") {
            return assetImage
        }
        
        return nil
    }
}

