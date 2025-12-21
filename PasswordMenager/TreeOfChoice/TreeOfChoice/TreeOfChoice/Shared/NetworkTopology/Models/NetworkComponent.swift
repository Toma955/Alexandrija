//
//  NetworkComponent.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation
import SwiftUI
import AppKit

/// Model za mrežnu komponentu
class NetworkComponent: Identifiable, ObservableObject, Codable {
    let id: UUID
    var componentType: ComponentType
    var position: CGPoint
    var name: String
    var isClientA: Bool?
    var isClientB: Bool?
    @Published var customColorRed: Double? // Custom boja RGB komponente za User komponentu
    @Published var customColorGreen: Double?
    @Published var customColorBlue: Double?
    var areaWidth: CGFloat? // Širina area kvadrata za area komponente
    var areaHeight: CGFloat? // Visina area kvadrata za area komponente
    
    var customColor: Color? {
        get {
            guard let r = customColorRed, let g = customColorGreen, let b = customColorBlue else {
                return nil
            }
            return Color(red: r, green: g, blue: b)
        }
        set {
            if let color = newValue {
                // Convert Color to RGB (simplified - assumes sRGB)
                let uiColor = NSColor(color)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                customColorRed = Double(r)
                customColorGreen = Double(g)
                customColorBlue = Double(b)
            } else {
                customColorRed = nil
                customColorGreen = nil
                customColorBlue = nil
            }
        }
    }
    
    enum ComponentType: String, Codable, CaseIterable {
        // Clients
        case mobile = "mobile"
        case desktop = "desktop"
        case tablet = "tablet"
        case laptop = "laptop"
        case user = "user"
        
        // Infrastructure
        case server = "server"
        case router = "router"
        case routerWifi = "routerWifi"
        case switchDevice = "switch"
        case modem = "modem"
        case accessPoint = "accessPoint"
        case loadBalancer = "loadBalancer"
        
        // Security
        case firewall = "firewall"
        case vpnGateway = "vpnGateway"
        case proxy = "proxy"
        case ids = "ids"
        
        // Cloud/Edge
        case cloud = "cloud"
        case edgeNode = "edgeNode"
        case cdnNode = "cdnNode"
        
        // IoT
        case iotDevice = "iotDevice"
        case sensor = "sensor"
        case smartTV = "smartTV"
        case smartSpeaker = "smartSpeaker"
        case securityCamera = "securityCamera"
        
        // Specialized
        case dnsServer = "dnsServer"
        case dhcpServer = "dhcpServer"
        case mailServer = "mailServer"
        case webServer = "webServer"
        case databaseServer = "databaseServer"
        case fileServer = "fileServer"
        case nas = "nas"
        case printer = "printer"
        case signalTower = "signalTower"
        case cellTower = "cellTower"
        case isp = "isp"
        case satelliteGateway = "satelliteGateway"
        
        // Area components (like User Area - can have custom colors)
        case userArea = "userArea"
        case businessArea = "businessArea"
        case businessPrivateArea = "businessPrivateArea"
        case nilterniusArea = "nilterniusArea"
        
        // Nilternius specific
        case nilternius = "nilternius"
        case nilterniusServer = "nilterniusServer"
        case businessServer = "businessServer"
        
        var displayName: String {
            switch self {
            case .mobile: return "Mobile"
            case .desktop: return "Desktop"
            case .tablet: return "Tablet"
            case .laptop: return "Laptop"
            case .user: return "User Area"
            case .server: return "Server"
            case .router: return "Router"
            case .routerWifi: return "Router (Wi-Fi)"
            case .switchDevice: return "Switch"
            case .modem: return "Modem"
            case .accessPoint: return "Access Point"
            case .loadBalancer: return "Load Balancer"
            case .firewall: return "Firewall"
            case .vpnGateway: return "VPN Gateway"
            case .proxy: return "Proxy"
            case .ids: return "IDS/IPS"
            case .cloud: return "Cloud Area"
            case .edgeNode: return "Edge Node"
            case .cdnNode: return "CDN Node"
            case .iotDevice: return "IoT Device"
            case .sensor: return "Sensor"
            case .smartTV: return "Smart TV"
            case .smartSpeaker: return "Smart Speaker"
            case .securityCamera: return "Security Camera"
            case .dnsServer: return "DNS Server"
            case .dhcpServer: return "DHCP Server"
            case .mailServer: return "Mail Server"
            case .webServer: return "Web Server"
            case .databaseServer: return "Database Server"
            case .fileServer: return "File Server"
            case .nas: return "NAS Area"
            case .printer: return "Printer"
            case .signalTower: return "Signal Tower"
            case .cellTower: return "Cell Tower"
            case .isp: return "ISP"
            case .satelliteGateway: return "Satellite Gateway"
            case .userArea: return "User Area"
            case .businessArea: return "Business Area"
            case .businessPrivateArea: return "Business Private Area"
            case .nilterniusArea: return "Nilternius Area"
            case .nilternius: return "Nilternius"
            case .nilterniusServer: return "Nilternius Server"
            case .businessServer: return "Business Server"
            }
        }
        
        var category: ComponentCategory {
            switch self {
            case .mobile, .desktop, .tablet, .laptop, .user:
                return .client
            case .server, .router, .routerWifi, .switchDevice, .modem, .accessPoint, .loadBalancer:
                return .infrastructure
            case .firewall, .vpnGateway, .proxy, .ids:
                return .security
            case .cloud, .edgeNode, .cdnNode:
                return .cloudEdge
            case .iotDevice, .sensor, .smartTV, .smartSpeaker, .securityCamera:
                return .iot
            case .dnsServer, .dhcpServer, .mailServer, .webServer, .databaseServer, .fileServer, .nas, .printer, .isp, .satelliteGateway:
                return .specialized
            case .signalTower, .cellTower:
                return .wireless
            case .userArea, .businessArea, .businessPrivateArea, .nilterniusArea:
                return .area
            case .nilternius, .nilterniusServer, .businessServer:
                return .nilternius
            }
        }
        
        var canBeClient: Bool {
            category == .client
        }
        
        /// Provjerava da li komponenta podržava custom boju (kao User Area)
        var supportsCustomColor: Bool {
            switch self {
            case .user, .userArea, .businessArea, .businessPrivateArea, .nilterniusArea:
                return true
            default:
                return false
            }
        }
    }
    
    enum ComponentCategory: String, Codable {
        case client = "client"
        case infrastructure = "infrastructure"
        case security = "security"
        case cloudEdge = "cloudEdge"
        case iot = "iot"
        case specialized = "specialized"
        case wireless = "wireless"
        case area = "area"
        case nilternius = "nilternius"
    }
    
    init(id: UUID = UUID(), componentType: ComponentType, position: CGPoint, name: String, isClientA: Bool? = nil, isClientB: Bool? = nil) {
        self.id = id
        self.componentType = componentType
        self.position = position
        self.name = name
        self.isClientA = isClientA
        self.isClientB = isClientB
        self.customColorRed = nil
        self.customColorGreen = nil
        self.customColorBlue = nil
        self.areaWidth = nil
        self.areaHeight = nil
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, componentType, position, name, isClientA, isClientB, customColorRed, customColorGreen, customColorBlue, areaWidth, areaHeight
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        componentType = try container.decode(ComponentType.self, forKey: .componentType)
        let positionDict = try container.decode([String: CGFloat].self, forKey: .position)
        position = CGPoint(x: positionDict["x"] ?? 0, y: positionDict["y"] ?? 0)
        name = try container.decode(String.self, forKey: .name)
        isClientA = try container.decodeIfPresent(Bool.self, forKey: .isClientA)
        isClientB = try container.decodeIfPresent(Bool.self, forKey: .isClientB)
        customColorRed = try container.decodeIfPresent(Double.self, forKey: .customColorRed)
        customColorGreen = try container.decodeIfPresent(Double.self, forKey: .customColorGreen)
        customColorBlue = try container.decodeIfPresent(Double.self, forKey: .customColorBlue)
        areaWidth = try container.decodeIfPresent(CGFloat.self, forKey: .areaWidth)
        areaHeight = try container.decodeIfPresent(CGFloat.self, forKey: .areaHeight)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(componentType, forKey: .componentType)
        try container.encode(["x": position.x, "y": position.y], forKey: .position)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(isClientA, forKey: .isClientA)
        try container.encodeIfPresent(isClientB, forKey: .isClientB)
        try container.encodeIfPresent(customColorRed, forKey: .customColorRed)
        try container.encodeIfPresent(customColorGreen, forKey: .customColorGreen)
        try container.encodeIfPresent(customColorBlue, forKey: .customColorBlue)
        try container.encodeIfPresent(areaWidth, forKey: .areaWidth)
        try container.encodeIfPresent(areaHeight, forKey: .areaHeight)
    }
}

/// Model za mrežnu konekciju između komponenti
struct NetworkConnection: Identifiable, Codable {
    let id: UUID
    let fromComponentId: UUID
    let toComponentId: UUID
    var connectionType: ConnectionType
    var fromConnectionPoint: ConnectionPoint? // Pin s kojeg počinje konekcija
    var toConnectionPoint: ConnectionPoint? // Pin na koji završava konekcija
    var controlPoint: CGPoint? // Kontrolna točka za krivulje (2 linije ili parabola)
    var curveType: CurveType? // Tip krivulje
    
    enum ConnectionType: String, Codable {
        case wired = "wired"
        case wireless = "wireless"
        case fiber = "fiber"
        case vpn = "vpn"
    }
    
    enum CurveType: String, Codable {
        case twoLines = "twoLines" // 2 linije sa središtem u kontrolnoj točki
        case parabola = "parabola" // Parabola
    }
    
    init(id: UUID = UUID(), fromComponentId: UUID, toComponentId: UUID, connectionType: ConnectionType = .wired, fromConnectionPoint: ConnectionPoint? = nil, toConnectionPoint: ConnectionPoint? = nil, controlPoint: CGPoint? = nil, curveType: CurveType? = nil) {
        self.id = id
        self.fromComponentId = fromComponentId
        self.toComponentId = toComponentId
        self.connectionType = connectionType
        self.fromConnectionPoint = fromConnectionPoint
        self.toConnectionPoint = toConnectionPoint
        self.controlPoint = controlPoint
        self.curveType = curveType
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, fromComponentId, toComponentId, connectionType, fromConnectionPoint, toConnectionPoint, controlPoint, curveType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        fromComponentId = try container.decode(UUID.self, forKey: .fromComponentId)
        toComponentId = try container.decode(UUID.self, forKey: .toComponentId)
        connectionType = try container.decode(ConnectionType.self, forKey: .connectionType)
        fromConnectionPoint = try container.decodeIfPresent(ConnectionPoint.self, forKey: .fromConnectionPoint)
        toConnectionPoint = try container.decodeIfPresent(ConnectionPoint.self, forKey: .toConnectionPoint)
        curveType = try container.decodeIfPresent(CurveType.self, forKey: .curveType)
        
        // Decode controlPoint as dictionary
        if let controlPointDict = try? container.decode([String: CGFloat].self, forKey: .controlPoint) {
            controlPoint = CGPoint(x: controlPointDict["x"] ?? 0, y: controlPointDict["y"] ?? 0)
        } else {
            controlPoint = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fromComponentId, forKey: .fromComponentId)
        try container.encode(toComponentId, forKey: .toComponentId)
        try container.encode(connectionType, forKey: .connectionType)
        try container.encodeIfPresent(fromConnectionPoint, forKey: .fromConnectionPoint)
        try container.encodeIfPresent(toConnectionPoint, forKey: .toConnectionPoint)
        try container.encodeIfPresent(curveType, forKey: .curveType)
        
        // Encode controlPoint as dictionary
        if let control = controlPoint {
            try container.encode(["x": control.x, "y": control.y], forKey: .controlPoint)
        }
    }
}


