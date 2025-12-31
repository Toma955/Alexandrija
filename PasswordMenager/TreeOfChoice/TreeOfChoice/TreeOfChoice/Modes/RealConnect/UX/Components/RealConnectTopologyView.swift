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
    
    @State private var impulseProgress: CGFloat = 0
    @State private var impulseDirection: ImpulseDirection = .none
    @State private var lastMessageCountA: Int = 0
    @State private var lastMessageCountB: Int = 0
    
    enum ImpulseDirection {
        case none
        case aToB
        case bToA
    }
    
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
        .onChange(of: roomSessionA.messages.count) { newCount in
            if newCount > lastMessageCountA && roomSessionA.isSessionReady {
                lastMessageCountA = newCount
                startImpulse(direction: .aToB)
            }
        }
        .onChange(of: roomSessionB.messages.count) { newCount in
            if newCount > lastMessageCountB && roomSessionB.isSessionReady {
                lastMessageCountB = newCount
                startImpulse(direction: .bToA)
            }
        }
        .onAppear {
            lastMessageCountA = roomSessionA.messages.count
            lastMessageCountB = roomSessionB.messages.count
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
    
    @State private var connectionPoints: [String: CGPoint] = [:]
    
    private var topologyVisualization: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.clear
                
                // Connection lines (koriste stvarne pozicije točaka)
                connectionLines(geometry: geometry)
                
                // Nodes - fiksne pozicije, gatewayi se dodaju između
                unifiedLayout(geometry: geometry)
            }
            .coordinateSpace(name: "topology")
            .onPreferenceChange(ConnectionPointKey.self) { points in
                connectionPoints = points
            }
        }
        .padding(16)
    }
    
    /// Unified layout - fiksne pozicije za Client A, Server i Client B, gatewayi se dodaju između
    @ViewBuilder
    private func unifiedLayout(geometry: GeometryProxy) -> some View {
        // Fiksna Y pozicija - spuštena za 100 piksela
        let nodeY = geometry.size.height * 0.35 + 100
        let padding: CGFloat = 40
        let nodeWidth: CGFloat = 120
        let spacing: CGFloat = 30
        
        // Fiksne X pozicije za glavne nodeove (ne mijenjaju se)
        let clientAX = padding + nodeWidth / 2
        let serverX = geometry.size.width / 2
        let clientBX = geometry.size.width - padding - nodeWidth / 2
        
        // Gateway pozicije - izračunaj na osnovu stvarnih pozicija točaka (sredina između točaka)
        let clientARightPoint = connectionPoints["clientA-right"] ?? CGPoint(x: clientAX + 25, y: nodeY)
        let serverLeftPoint = connectionPoints["server-left"] ?? CGPoint(x: serverX - 25, y: nodeY)
        let serverRightPoint = connectionPoints["server-right"] ?? CGPoint(x: serverX + 25, y: nodeY)
        let clientBLeftPoint = connectionPoints["clientB-left"] ?? CGPoint(x: clientBX - 25, y: nodeY)
        
        // Gateway A je na sredini između Client A desne točke i Server lijeve točke
        let gatewayAX = (clientARightPoint.x + serverLeftPoint.x) / 2
        // Gateway B je na sredini između Server desne točke i Client B lijeve točke
        let gatewayBX = (serverRightPoint.x + clientBLeftPoint.x) / 2
        
        ZStack {
            // Client A lijevo - UVIJEK na istoj poziciji
            TopologyNodeView(
                nodeID: "clientA",
                label: "Client A",
                isConnected: roomSessionA.isSessionReady,
                isServer: false,
                isGateway: false,
                isSwitch: false,
                roomCode: clientACode,
                messageCount: roomSessionA.messages.count,
                privateIP: networkInfoA.privateIP,
                publicIP: networkInfoA.publicIP,
                port: networkInfoA.port,
                gateway: gatewayA,
                macAddress: "",
                serverIP: "",
                showDetails: bothClientsConnected
            )
            .frame(width: 120)
            .position(x: clientAX, y: nodeY)
            .id("clientA")
            .transaction { $0.animation = nil }
            
            // Gateway A - pojavljuje se samo kada su spojeni
            if bothClientsConnected {
                TopologyNodeView(
                    nodeID: "gatewayA",
                label: "Gateway A",
                isConnected: true,
                    isServer: false,
                isGateway: true,
                    isSwitch: false,
                    roomCode: "",
                    messageCount: 0,
                privateIP: networkInfoA.privateIP,
                publicIP: networkInfoA.publicIP,
                    port: "",
                    gateway: gatewayA,
                macAddress: networkInfoA.macAddress,
                    serverIP: "",
                showDetails: true
            )
            .frame(width: 120)
                .position(x: gatewayAX, y: nodeY)
                .zIndex(10)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .animation(.easeInOut(duration: 0.3), value: bothClientsConnected)
            }
            
            // Server u sredini - UVIJEK na istoj poziciji
            TopologyNodeView(
                nodeID: "server",
                label: "Relay Server",
                isConnected: roomSessionA.isSessionReady || roomSessionB.isSessionReady,
                isServer: true,
                isGateway: false,
                isSwitch: false,
                roomCode: "",
                messageCount: 0,
                privateIP: "",
                publicIP: "",
                port: "",
                gateway: "",
                macAddress: "",
                serverIP: networkInfoA.serverIP,
                showDetails: bothClientsConnected
            )
            .frame(width: 120)
            .position(x: serverX, y: nodeY)
            .id("server")
            .transaction { $0.animation = nil }
            
            // Gateway B - pojavljuje se samo kada su spojeni
            if bothClientsConnected {
                TopologyNodeView(
                    nodeID: "gatewayB",
                label: "Gateway B",
                isConnected: true,
                    isServer: false,
                isGateway: true,
                    isSwitch: false,
                    roomCode: "",
                    messageCount: 0,
                privateIP: networkInfoB.privateIP,
                publicIP: networkInfoB.publicIP,
                    port: "",
                    gateway: gatewayB,
                macAddress: networkInfoB.macAddress,
                    serverIP: "",
                showDetails: true
            )
            .frame(width: 120)
                .position(x: gatewayBX, y: nodeY)
                .zIndex(10)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .animation(.easeInOut(duration: 0.3), value: bothClientsConnected)
            }
            
            // Client B desno - UVIJEK na istoj poziciji
            TopologyNodeView(
                nodeID: "clientB",
                label: "Client B",
                isConnected: roomSessionB.isSessionReady,
                isServer: false,
                isGateway: false,
                isSwitch: false,
                roomCode: clientBCode,
                messageCount: roomSessionB.messages.count,
                privateIP: networkInfoB.privateIP,
                publicIP: networkInfoB.publicIP,
                port: networkInfoB.port,
                gateway: gatewayB,
                macAddress: "",
                serverIP: "",
                showDetails: bothClientsConnected
            )
            .frame(width: 120)
            .position(x: clientBX, y: nodeY)
            .id("clientB")
            .transaction { $0.animation = nil }
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
    
    /// Pokreni animaciju impulsa
    private func startImpulse(direction: ImpulseDirection) {
        impulseDirection = direction
        impulseProgress = 0
        
        withAnimation(.linear(duration: 1.5)) {
            impulseProgress = 1.0
        } completion: {
            impulseDirection = .none
            impulseProgress = 0
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
    
    struct ConnectionPointKey: PreferenceKey {
        static var defaultValue: [String: CGPoint] = [:]
        static func reduce(value: inout [String: CGPoint], nextValue: () -> [String: CGPoint]) {
            value.merge(nextValue(), uniquingKeysWith: { $1 })
        }
    }
    
    struct ConnectionPointAnchorKey: PreferenceKey {
        static var defaultValue: [String: Anchor<CGPoint>] = [:]
        static func reduce(value: inout [String: Anchor<CGPoint>], nextValue: () -> [String: Anchor<CGPoint>]) {
            value.merge(nextValue(), uniquingKeysWith: { $1 })
        }
    }
    
    enum ConnectionSide {
        case left
        case right
    }
    
    @ViewBuilder
    private func connectionLines(geometry: GeometryProxy) -> some View {
        // Koristi stvarne pozicije točaka iz PreferenceKey
        let clientARightPoint = connectionPoints["clientA-right"] ?? CGPoint.zero
        let serverLeftPoint = connectionPoints["server-left"] ?? CGPoint.zero
        let serverRightPoint = connectionPoints["server-right"] ?? CGPoint.zero
        let clientBLeftPoint = connectionPoints["clientB-left"] ?? CGPoint.zero
        
        ZStack {
            if bothClientsConnected {
                let gatewayALeftPoint = connectionPoints["gatewayA-left"] ?? CGPoint.zero
                let gatewayARightPoint = connectionPoints["gatewayA-right"] ?? CGPoint.zero
                let gatewayBLeftPoint = connectionPoints["gatewayB-left"] ?? CGPoint.zero
                let gatewayBRightPoint = connectionPoints["gatewayB-right"] ?? CGPoint.zero
                
                let lineColor: Color = .green
                
                if clientARightPoint != .zero && gatewayALeftPoint != .zero {
                    Path { path in
                        path.move(to: clientARightPoint)
                        path.addLine(to: gatewayALeftPoint)
                    }
                    .stroke(lineColor.opacity(0.6), style: StrokeStyle(lineWidth: 3))
                }
                
                if gatewayARightPoint != .zero && serverLeftPoint != .zero {
                    Path { path in
                        path.move(to: gatewayARightPoint)
                        path.addLine(to: serverLeftPoint)
                    }
                    .stroke(lineColor.opacity(0.6), style: StrokeStyle(lineWidth: 3))
                }
                
                if serverRightPoint != .zero && gatewayBLeftPoint != .zero {
                    Path { path in
                        path.move(to: serverRightPoint)
                        path.addLine(to: gatewayBLeftPoint)
                    }
                    .stroke(lineColor.opacity(0.6), style: StrokeStyle(lineWidth: 3))
                }
                
                if gatewayBRightPoint != .zero && clientBLeftPoint != .zero {
        Path { path in
                        path.move(to: gatewayBRightPoint)
                        path.addLine(to: clientBLeftPoint)
                    }
                    .stroke(lineColor.opacity(0.6), style: StrokeStyle(lineWidth: 3))
                }
                
                // Impuls A → B
                if impulseDirection == .aToB && impulseProgress > 0 {
                    impulseView(
                        from: clientARightPoint,
                        via: [gatewayALeftPoint, gatewayARightPoint, serverLeftPoint, serverRightPoint, gatewayBLeftPoint, gatewayBRightPoint],
                        to: clientBLeftPoint,
                        progress: impulseProgress
                    )
                }
                
                // Impuls B → A
                if impulseDirection == .bToA && impulseProgress > 0 {
                    impulseView(
                        from: clientBLeftPoint,
                        via: [gatewayBRightPoint, gatewayBLeftPoint, serverRightPoint, serverLeftPoint, gatewayARightPoint, gatewayALeftPoint],
                        to: clientARightPoint,
                        progress: impulseProgress
                    )
                }
            } else {
                let lineColorA: Color = roomSessionA.isSessionReady ? .green : .gray
                let lineColorB: Color = roomSessionB.isSessionReady ? .green : .gray
                
                if clientARightPoint != .zero && serverLeftPoint != .zero && roomSessionA.isSessionReady {
                    Path { path in
                        path.move(to: clientARightPoint)
                        path.addLine(to: serverLeftPoint)
                    }
                    .stroke(lineColorA.opacity(0.6), style: StrokeStyle(lineWidth: 3))
                }
                
                if serverRightPoint != .zero && clientBLeftPoint != .zero && roomSessionB.isSessionReady {
        Path { path in
                        path.move(to: serverRightPoint)
                        path.addLine(to: clientBLeftPoint)
                    }
                    .stroke(lineColorB.opacity(0.6), style: StrokeStyle(lineWidth: 3))
                }
                
                // Impuls A → B (bez gatewaya)
                if impulseDirection == .aToB && impulseProgress > 0 && clientARightPoint != .zero && serverLeftPoint != .zero && serverRightPoint != .zero && clientBLeftPoint != .zero {
                    impulseView(
                        from: clientARightPoint,
                        via: [serverLeftPoint, serverRightPoint],
                        to: clientBLeftPoint,
                        progress: impulseProgress
                    )
                }
                
                // Impuls B → A (bez gatewaya)
                if impulseDirection == .bToA && impulseProgress > 0 && clientARightPoint != .zero && serverLeftPoint != .zero && serverRightPoint != .zero && clientBLeftPoint != .zero {
                    impulseView(
                        from: clientBLeftPoint,
                        via: [serverRightPoint, serverLeftPoint],
                        to: clientARightPoint,
                        progress: impulseProgress
                    )
                }
            }
        }
    }
    
    /// View za animirani impuls koji putuje po linijama
    @ViewBuilder
    private func impulseView(from: CGPoint, via: [CGPoint], to: CGPoint, progress: CGFloat) -> some View {
        let allPoints = [from] + via.filter { $0 != .zero } + [to]
        guard allPoints.count >= 2 else { return AnyView(EmptyView()) }
        
        let totalDistance = calculateTotalDistance(points: allPoints)
        let currentDistance = totalDistance * progress
        
        let (currentPoint, _) = pointAtDistance(points: allPoints, distance: currentDistance)
        
        return AnyView(
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .shadow(color: .green, radius: 4)
                .position(currentPoint)
        )
    }
    
    /// Izračunaj ukupnu udaljenost kroz sve točke
    private func calculateTotalDistance(points: [CGPoint]) -> CGFloat {
        guard points.count >= 2 else { return 0 }
        var total: CGFloat = 0
        for i in 0..<points.count - 1 {
            let dx = points[i + 1].x - points[i].x
            let dy = points[i + 1].y - points[i].y
            total += sqrt(dx * dx + dy * dy)
        }
        return total
    }
    
    /// Pronađi točku na određenoj udaljenosti kroz točke
    private func pointAtDistance(points: [CGPoint], distance: CGFloat) -> (CGPoint, Int) {
        guard points.count >= 2 else { return (points.first ?? .zero, 0) }
        
        var accumulated: CGFloat = 0
        for i in 0..<points.count - 1 {
            let dx = points[i + 1].x - points[i].x
            let dy = points[i + 1].y - points[i].y
            let segmentLength = sqrt(dx * dx + dy * dy)
            
            if accumulated + segmentLength >= distance {
                let t = (distance - accumulated) / segmentLength
                let x = points[i].x + t * dx
                let y = points[i].y + t * dy
                return (CGPoint(x: x, y: y), i)
            }
            
            accumulated += segmentLength
        }
        
        return (points.last ?? .zero, points.count - 1)
    }
    
    // MARK: - Topology Node View (Parent Element)
    
    /// Parent element koji sadrži: krug, naziv, ikonu i točke
    struct TopologyNodeView: View {
        let nodeID: String
        let label: String
        let isConnected: Bool
        let isServer: Bool
        let isGateway: Bool
        let isSwitch: Bool
        let roomCode: String
        let messageCount: Int
        let privateIP: String
        let publicIP: String
        let port: String
        let gateway: String
        let macAddress: String
        let serverIP: String
        let showDetails: Bool
        
        // Fiksne dimenzije za sve nodeove
        private let circleSize: CGFloat = 50 // Svi nodeovi iste veličine
        private let circleRadius: CGFloat = 25
        private let topSectionHeight: CGFloat = 90
        
        var body: some View {
            GeometryReader { geometry in
            // Glavni node (circle + label + status) - FIKSNE POZICIJE - NIKAD SE NE MIJENJA
        VStack(spacing: 6) {
                // Node circle s točkama
            ZStack {
                    // Krug
                let borderColor: Color = isConnected ? .green : .gray
                let fillColor: Color = {
                    if isServer || isGateway || isSwitch {
                        return Color.clear
                    } else {
                        // Svi klijenti siva pozadina
                        return Color.gray.opacity(0.5)
                    }
                }()
                
                if isServer || isGateway || isSwitch {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: circleSize, height: circleSize)
                        .overlay(
                            Circle()
                                .stroke(borderColor.opacity(0.7), lineWidth: 2.5)
                        )
                } else {
                    Circle()
                        .fill(fillColor)
                        .frame(width: circleSize, height: circleSize)
                        .overlay(
                            Circle()
                                .stroke(borderColor.opacity(0.7), lineWidth: 2.5)
                        )
                }
                
                    // Ikona - zelena kada je spojeno, siva kada nije
                let iconColor: Color = isConnected ? .green : .gray
                
                if isServer {
                    Image(systemName: "server.rack")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(iconColor)
                } else if isGateway {
                    if let routerImage = loadRouterIcon() {
                        Image(nsImage: routerImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .overlay(
                                Rectangle()
                                    .fill(iconColor)
                                    .blendMode(.sourceAtop)
                            )
                    } else {
                        Image(systemName: "router.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                } else if isSwitch {
                    Image(systemName: "network")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                } else {
                    Image(systemName: isConnected ? "laptopcomputer" : "laptopcomputer.slash")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                }
                    
                    // Točke - nevidljive ali se koriste za connection lines
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                        .offset(x: -circleRadius, y: 0)
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                        .offset(x: circleRadius, y: 0)
                }
                .frame(width: circleSize, height: circleSize)
                .background(
                    GeometryReader { circleGeometry in
                        Color.clear
                            .preference(
                                key: ConnectionPointKey.self,
                                value: [
                                    "\(nodeID)-left": CGPoint(
                                        x: circleGeometry.frame(in: .named("topology")).midX - circleRadius,
                                        y: circleGeometry.frame(in: .named("topology")).midY
                                    ),
                                    "\(nodeID)-right": CGPoint(
                                        x: circleGeometry.frame(in: .named("topology")).midX + circleRadius,
                                        y: circleGeometry.frame(in: .named("topology")).midY
                                    )
                                ]
                            )
                    }
                )
            
            // Label
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.9))
                    .frame(height: 16)
            
                // Status text - UVIJEK zauzima prostor (fiksna visina)
                Text(isConnected ? "Connected" : "Disconnected")
                    .font(.caption2)
                    .foregroundColor(isConnected ? .green.opacity(0.8) : .red.opacity(0.8))
                    .opacity(showDetails ? 1.0 : 0.0)
                    .frame(height: 14)
            }
            .frame(height: topSectionHeight, alignment: .top)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .top) {
                // Informacije ispod nodea (ne mijenjaju poziciju gornjeg dijela)
                VStack(spacing: 2) {
                    // IP adrese i MAC (za server)
            if showDetails && isServer && !serverIP.isEmpty && serverIP != "Unknown" {
                Text("IP: \(serverIP)")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.7))
            }
            
                    // IP adrese i MAC (za gateway)
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
            
                    // IP adrese i MAC (za switch)
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
                .offset(y: topSectionHeight)
                .allowsHitTesting(false)
            }
            .frame(height: topSectionHeight, alignment: .top)
            }
        }
        
        // Helper za učitavanje Router ikone
    private func loadRouterIcon() -> NSImage? {
        if let imageURL = Bundle.main.url(forResource: "Router", withExtension: "png", subdirectory: "Shared/UX/Icons") {
            if let image = NSImage(contentsOf: imageURL) {
                return image
            }
        }
        if let imageURL = Bundle.main.url(forResource: "Router", withExtension: "png") {
            return NSImage(contentsOf: imageURL)
        }
        if let assetImage = NSImage(named: "Router") {
            return assetImage
        }
        return nil
        }
    }
}

