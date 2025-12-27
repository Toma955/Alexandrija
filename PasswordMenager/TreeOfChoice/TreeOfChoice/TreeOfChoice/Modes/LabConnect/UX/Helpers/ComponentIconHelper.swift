//
//  ComponentIconHelper.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit
import Foundation

struct ComponentIconHelper {
    /// Vraća ikonu za komponentu, uzimajući u obzir selectedDeviceType za User Area i Gateway za ostale Area elemente
    static func icon(for component: NetworkComponent) -> String {
        // Za User Area, ako postoji selectedDeviceType, koristi ikonu tog device type-a
        if component.componentType == .userArea, let deviceType = component.selectedDeviceType {
            return icon(for: deviceType)
        }
        
        // Za ostale Area elemente (Business Area, Business Private Area, Nilternius Area), koristi Gateway ikonu
        if component.componentType == .businessArea || 
           component.componentType == .businessPrivateArea || 
           component.componentType == .nilterniusArea {
            return "antenna.radiowaves.left.and.right" // Gateway ikona
        }
        
        // Inače koristi standardnu ikonu za tip komponente
        return icon(for: component.componentType)
    }
    
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
        case .cellTower: return "dish.antenna"
        case .isp: return "antenna.radiowaves.left.and.right"
        case .satelliteGateway: return "antenna.radiowaves.left.and.right"
        case .userArea: return "person.3.fill"
        case .businessArea: return "building.2.fill"
        case .businessPrivateArea: return "building.2.crop.circle.fill"
        case .nilterniusArea: return "lock.shield.fill"
        case .nilternius: return "lock.shield"
        case .nilterniusServer: return "server.rack"
        case .businessServer: return "server.rack"
        case .user: return "satellite"
        }
    }
    
    /// Vraća ime custom ikone ako postoji, inače nil (koristi se SF Symbol)
    static func customIconName(for type: NetworkComponent.ComponentType) -> String? {
        switch type {
        case .switchDevice: return "Switch"
        case .router: return "Router"
        case .user: return "satellite"
        case .cellTower: return "LTE-antena"
        case .satelliteGateway: return "satellite-rooter"
        case .isp: return "Stalete-Hub"
        case .nas: return "Nas"
        case .loadBalancer: return "Load Balancer"
        case .userArea: return "Home"
        case .dnsServer: return "Dns"
        case .accessPoint: return "WAP"
        default: return nil
        }
    }
    
    /// Provjerava da li komponenta ima custom ikonu
    static func hasCustomIcon(for type: NetworkComponent.ComponentType) -> Bool {
        return customIconName(for: type) != nil
    }
    
    /// Učitava custom ikonu iz Assets.xcassets ili Bundle-a
    static func loadCustomIcon(named name: String) -> NSImage? {
        // Prvo pokušaj učitati iz Assets.xcassets (NSImage automatski traži u asset catalogu)
        if let assetImage = NSImage(named: name) {
            return assetImage
        }
        
        // Fallback: Pokušaj učitati iz Shared/UX/Icons foldera
        if let imageURL = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Shared/UX/Icons") {
            if let image = NSImage(contentsOf: imageURL) {
                return image
            }
        }
        
        // Fallback: Pokušaj učitati direktno iz bundle-a (ako su ikone dodane kao resource)
        if let imageURL = Bundle.main.url(forResource: name, withExtension: "png") {
            return NSImage(contentsOf: imageURL)
        }
        
        return nil
    }
}

