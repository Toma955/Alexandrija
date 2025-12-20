//
//  ComponentIconHelper.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ComponentIconHelper {
    static func icon(for type: NetworkComponent.ComponentType) -> String {
        switch type {
        case .mobile: return "iphone"
        case .desktop: return "desktopcomputer"
        case .tablet: return "ipad"
        case .laptop: return "laptopcomputer"
        case .server: return "server.rack"
        case .router: return "antenna.radiowaves.left.and.right"
        case .routerWifi: return "wifi.router"
        case .switchDevice: return "switch.2"
        case .modem: return "antenna.radiowaves.left.and.right"
        case .accessPoint: return "wifi"
        case .loadBalancer: return "scalemass"
        case .firewall: return "shield"
        case .vpnGateway: return "lock.shield"
        case .proxy: return "arrow.triangle.branch"
        case .ids: return "eye.trianglebadge.exclamationmark"
        case .cloud: return "cloud"
        case .edgeNode: return "circle.hexagongrid"
        case .cdnNode: return "globe"
        case .iotDevice: return "sensor.tag.radiowaves.forward"
        case .sensor: return "sensor"
        case .smartTV: return "tv"
        case .smartSpeaker: return "speaker.wave.2"
        case .securityCamera: return "camera"
        case .dnsServer: return "network"
        case .dhcpServer: return "network"
        case .mailServer: return "envelope"
        case .webServer: return "server.rack"
        case .databaseServer: return "externaldrive"
        case .fileServer: return "folder"
        case .nas: return "externaldrive.fill"
        case .printer: return "printer"
        case .signalTower: return "antenna.radiowaves.left.and.right"
        case .cellTower: return "antenna.radiowaves.left.and.right"
        case .isp: return "network"
        case .satelliteGateway: return "antenna.radiowaves.left.and.right.circle.fill"
        case .userArea: return "person.3.fill"
        case .businessArea: return "building.2.fill"
        case .businessPrivateArea: return "building.2.crop.circle.fill"
        case .nilterniusArea: return "lock.shield.fill"
        case .nilternius: return "lock.shield"
        case .nilterniusServer: return "server.rack"
        case .businessServer: return "server.rack"
        case .user: return "person.fill"
        }
    }
}

