//
//  ConnectionRules.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Pravila za konekcije između mrežnih komponenti
/// Definira koje komponente se mogu spajati s kojima
struct ConnectionRules {
    
    /// Pravilo za konekciju između dvije komponente
    struct Rule {
        let fromType: NetworkComponent.ComponentType
        let toType: NetworkComponent.ComponentType
        let allowed: Bool
        let reason: String? // Razlog zašto je dozvoljeno/zabranjeno
        
        init(_ fromType: NetworkComponent.ComponentType, 
             _ toType: NetworkComponent.ComponentType, 
             allowed: Bool = true, 
             reason: String? = nil) {
            self.fromType = fromType
            self.toType = toType
            self.allowed = allowed
            self.reason = reason
        }
    }
    
    /// Lista svih pravila konekcija
    static let rules: [Rule] = [
        // ========== CLIENT KOMPONENTE ==========
        // Mobile - može se spajati s wireless infrastrukturom
        Rule(.mobile, .routerWifi, allowed: true),
        Rule(.mobile, .accessPoint, allowed: true),
        Rule(.mobile, .satelliteGateway, allowed: true),
        Rule(.mobile, .signalTower, allowed: true),
        
        // Desktop - može se spajati s wired infrastrukturom
        Rule(.desktop, .router, allowed: true),
        Rule(.desktop, .switchDevice, allowed: true),
        Rule(.desktop, .modem, allowed: true),
        Rule(.desktop, .routerWifi, allowed: true), // Može i wireless ako ima adapter
        
        // Tablet - može se spajati s wireless infrastrukturom
        Rule(.tablet, .routerWifi, allowed: true),
        Rule(.tablet, .accessPoint, allowed: true),
        Rule(.tablet, .satelliteGateway, allowed: true),
        Rule(.tablet, .signalTower, allowed: true),
        
        // Laptop - može se spajati s wired i wireless infrastrukturom
        Rule(.laptop, .router, allowed: true),
        Rule(.laptop, .routerWifi, allowed: true),
        Rule(.laptop, .switchDevice, allowed: true),
        Rule(.laptop, .accessPoint, allowed: true),
        Rule(.laptop, .modem, allowed: true),
        Rule(.laptop, .satelliteGateway, allowed: true),
        
        // User (Satellite) - može se spajati SAMO s Sat Gateway i Satellite Earth Station (ISP)
        Rule(.user, .satelliteGateway, allowed: true),
        Rule(.user, .isp, allowed: true),
        // Zabranjeno spajanje s bilo čim drugim
        
        // ========== INFRASTRUCTURE KOMPONENTE ==========
        // Router - centralna infrastrukturna komponenta
        Rule(.router, .server, allowed: true),
        Rule(.router, .switchDevice, allowed: true),
        Rule(.router, .modem, allowed: true),
        Rule(.router, .firewall, allowed: true),
        Rule(.router, .loadBalancer, allowed: true),
        Rule(.router, .router, allowed: true), // Router-router konekcije (WAN)
        Rule(.router, .isp, allowed: true), // Router-ISP konekcije
        Rule(.router, .vpnGateway, allowed: true),
        Rule(.router, .proxy, allowed: true),
        Rule(.router, .dnsServer, allowed: true),
        Rule(.router, .dhcpServer, allowed: true),
        Rule(.router, .satelliteGateway, allowed: true),
        Rule(.router, .edgeNode, allowed: true),
        Rule(.router, .cdnNode, allowed: true),
        Rule(.router, .cellTower, allowed: true),
        
        // Router WiFi - router s wireless funkcionalnostima
        Rule(.routerWifi, .server, allowed: true),
        Rule(.routerWifi, .switchDevice, allowed: true),
        Rule(.routerWifi, .modem, allowed: true),
        Rule(.routerWifi, .firewall, allowed: true),
        Rule(.routerWifi, .accessPoint, allowed: true),
        Rule(.routerWifi, .routerWifi, allowed: true),
        Rule(.routerWifi, .router, allowed: true),
        Rule(.routerWifi, .isp, allowed: true),
        
        // Switch - lokalna mrežna infrastruktura
        Rule(.switchDevice, .server, allowed: true),
        Rule(.switchDevice, .router, allowed: true),
        Rule(.switchDevice, .switchDevice, allowed: true), // Switch-switch konekcije
        Rule(.switchDevice, .firewall, allowed: true),
        Rule(.switchDevice, .loadBalancer, allowed: true),
        Rule(.switchDevice, .cellTower, allowed: true),
        Rule(.switchDevice, .routerWifi, allowed: true),
        Rule(.switchDevice, .accessPoint, allowed: true),
        Rule(.switchDevice, .printer, allowed: true),
        Rule(.switchDevice, .nas, allowed: true),
        Rule(.switchDevice, .fileServer, allowed: true),
        Rule(.switchDevice, .databaseServer, allowed: true),
        Rule(.switchDevice, .dnsServer, allowed: true),
        Rule(.switchDevice, .dhcpServer, allowed: true),
        Rule(.switchDevice, .ids, allowed: true),
        Rule(.switchDevice, .iotDevice, allowed: true),
        
        // Server - glavni server
        Rule(.server, .router, allowed: true),
        Rule(.server, .switchDevice, allowed: true),
        Rule(.server, .firewall, allowed: true),
        Rule(.server, .loadBalancer, allowed: true),
        Rule(.server, .databaseServer, allowed: true),
        Rule(.server, .webServer, allowed: true),
        Rule(.server, .fileServer, allowed: true),
        Rule(.server, .mailServer, allowed: true),
        Rule(.server, .nas, allowed: true),
        Rule(.server, .vpnGateway, allowed: true),
        Rule(.server, .proxy, allowed: true),
        Rule(.server, .edgeNode, allowed: true),
        Rule(.server, .businessServer, allowed: true),
        Rule(.server, .nilterniusServer, allowed: true),
        
        // Modem - spaja lokalnu mrežu s internetom
        Rule(.modem, .router, allowed: true),
        Rule(.modem, .routerWifi, allowed: true),
        Rule(.modem, .isp, allowed: true),
        Rule(.modem, .satelliteGateway, allowed: true),
        
        // Access Point - wireless pristupna točka
        Rule(.accessPoint, .router, allowed: true),
        Rule(.accessPoint, .routerWifi, allowed: true),
        Rule(.accessPoint, .switchDevice, allowed: true),
        Rule(.accessPoint, .accessPoint, allowed: true), // Mesh mreže
        
        // Load Balancer - distribuira opterećenje
        Rule(.loadBalancer, .server, allowed: true),
        Rule(.loadBalancer, .router, allowed: true),
        Rule(.loadBalancer, .switchDevice, allowed: true),
        Rule(.loadBalancer, .webServer, allowed: true),
        Rule(.loadBalancer, .firewall, allowed: true),
        
        // ========== SECURITY KOMPONENTE ==========
        // Firewall - zaštita mreže
        Rule(.firewall, .router, allowed: true),
        Rule(.firewall, .switchDevice, allowed: true),
        Rule(.firewall, .server, allowed: true),
        Rule(.firewall, .vpnGateway, allowed: true),
        Rule(.firewall, .proxy, allowed: true),
        Rule(.firewall, .ids, allowed: true),
        Rule(.firewall, .loadBalancer, allowed: true),
        Rule(.firewall, .webServer, allowed: true),
        Rule(.firewall, .mailServer, allowed: true),
        Rule(.firewall, .businessServer, allowed: true),
        
        // VPN Gateway - virtualna privatna mreža
        Rule(.vpnGateway, .firewall, allowed: true),
        Rule(.vpnGateway, .router, allowed: true),
        Rule(.vpnGateway, .server, allowed: true),
        Rule(.vpnGateway, .switchDevice, allowed: true),
        
        // Proxy - proxy server
        Rule(.proxy, .firewall, allowed: true),
        Rule(.proxy, .router, allowed: true),
        Rule(.proxy, .server, allowed: true),
        Rule(.proxy, .switchDevice, allowed: true),
        
        // IDS/IPS - detekcija i prevencija napada
        Rule(.ids, .firewall, allowed: true),
        Rule(.ids, .switchDevice, allowed: true),
        Rule(.ids, .router, allowed: true),
        Rule(.ids, .routerWifi, allowed: true),
        
        // ========== SPECIALIZED SERVERS ==========
        // DNS Server - DNS servisi (može se spojiti samo na server, router, switch i Satellite Earth Station)
        Rule(.dnsServer, .router, allowed: true),
        Rule(.dnsServer, .switchDevice, allowed: true),
        Rule(.dnsServer, .server, allowed: true),
        Rule(.dnsServer, .isp, allowed: true),
        
        // DHCP Server - DHCP servisi (može se spojiti samo na server, router, switch i Satellite Earth Station)
        Rule(.dhcpServer, .router, allowed: true),
        Rule(.dhcpServer, .switchDevice, allowed: true),
        Rule(.dhcpServer, .server, allowed: true),
        Rule(.dhcpServer, .isp, allowed: true),
        
        // Web Server - web servisi
        Rule(.webServer, .loadBalancer, allowed: true),
        Rule(.webServer, .server, allowed: true),
        Rule(.webServer, .firewall, allowed: true),
        Rule(.webServer, .databaseServer, allowed: true),
        Rule(.webServer, .switchDevice, allowed: true),
        Rule(.webServer, .router, allowed: true),
        
        // Database Server - baze podataka
        Rule(.databaseServer, .server, allowed: true),
        Rule(.databaseServer, .webServer, allowed: true),
        Rule(.databaseServer, .switchDevice, allowed: true),
        Rule(.databaseServer, .fileServer, allowed: true),
        
        // Mail Server - email servisi
        Rule(.mailServer, .server, allowed: true),
        Rule(.mailServer, .router, allowed: true),
        Rule(.mailServer, .firewall, allowed: true),
        Rule(.mailServer, .switchDevice, allowed: true),
        
        // File Server - file servisi
        Rule(.fileServer, .server, allowed: true),
        Rule(.fileServer, .switchDevice, allowed: true),
        Rule(.fileServer, .router, allowed: true),
        Rule(.fileServer, .databaseServer, allowed: true),
        Rule(.fileServer, .nas, allowed: true),
        
        // NAS - Network Attached Storage
        Rule(.nas, .switchDevice, allowed: true),
        Rule(.nas, .router, allowed: true),
        Rule(.nas, .server, allowed: true),
        Rule(.nas, .fileServer, allowed: true),
        
        // Printer - printeri
        Rule(.printer, .switchDevice, allowed: true),
        Rule(.printer, .router, allowed: true),
        Rule(.printer, .routerWifi, allowed: true),
        Rule(.printer, .accessPoint, allowed: true),
        
        // ========== WIRELESS KOMPONENTE ==========
        // Cell Tower - mobilna mreža (može se spojiti samo na Router i Switch)
        Rule(.cellTower, .router, allowed: true),
        Rule(.cellTower, .switchDevice, allowed: true),
        
        // Signal Tower - signalni toranj
        Rule(.signalTower, .mobile, allowed: true),
        Rule(.signalTower, .tablet, allowed: true),
        Rule(.signalTower, .laptop, allowed: true),
        
        // Satellite Gateway - satelitski gateway
        Rule(.satelliteGateway, .user, allowed: true),
        Rule(.satelliteGateway, .isp, allowed: true),
        Rule(.satelliteGateway, .router, allowed: true),
        Rule(.satelliteGateway, .modem, allowed: true),
        Rule(.satelliteGateway, .server, allowed: true),
        Rule(.satelliteGateway, .switchDevice, allowed: true),
        Rule(.satelliteGateway, .firewall, allowed: true),
        
        // ISP (Satellite Earth Station) - internet provajder
        Rule(.isp, .satelliteGateway, allowed: true),
        Rule(.isp, .modem, allowed: true),
        Rule(.isp, .router, allowed: true),
        Rule(.isp, .routerWifi, allowed: true),
        
        // ========== CLOUD/EDGE KOMPONENTE ==========
        // Cloud - cloud infrastruktura
        Rule(.cloud, .router, allowed: true),
        Rule(.cloud, .edgeNode, allowed: true),
        Rule(.cloud, .cdnNode, allowed: true),
        Rule(.cloud, .server, allowed: true),
        Rule(.cloud, .loadBalancer, allowed: true),
        
        // Edge Node - edge computing
        Rule(.edgeNode, .router, allowed: true),
        Rule(.edgeNode, .server, allowed: true),
        Rule(.edgeNode, .cloud, allowed: true),
        Rule(.edgeNode, .switchDevice, allowed: true),
        Rule(.edgeNode, .cdnNode, allowed: true),
        
        // CDN Node - Content Delivery Network
        Rule(.cdnNode, .router, allowed: true),
        Rule(.cdnNode, .edgeNode, allowed: true),
        Rule(.cdnNode, .cloud, allowed: true),
        Rule(.cdnNode, .server, allowed: true),
        Rule(.cdnNode, .webServer, allowed: true),
        
        // ========== IoT KOMPONENTE ==========
        // IoT Device - IoT uređaji
        Rule(.iotDevice, .routerWifi, allowed: true),
        Rule(.iotDevice, .accessPoint, allowed: true),
        Rule(.iotDevice, .switchDevice, allowed: true),
        Rule(.iotDevice, .router, allowed: true),
        Rule(.iotDevice, .sensor, allowed: true),
        
        // Sensor - senzori
        Rule(.sensor, .iotDevice, allowed: true),
        Rule(.sensor, .routerWifi, allowed: true),
        Rule(.sensor, .accessPoint, allowed: true),
        Rule(.sensor, .switchDevice, allowed: true),
        
        // Smart TV - pametni TV
        Rule(.smartTV, .routerWifi, allowed: true),
        Rule(.smartTV, .accessPoint, allowed: true),
        Rule(.smartTV, .router, allowed: true),
        Rule(.smartTV, .switchDevice, allowed: true),
        
        // Smart Speaker - pametni zvučnici
        Rule(.smartSpeaker, .routerWifi, allowed: true),
        Rule(.smartSpeaker, .accessPoint, allowed: true),
        Rule(.smartSpeaker, .router, allowed: true),
        
        // Security Camera - sigurnosne kamere
        Rule(.securityCamera, .routerWifi, allowed: true),
        Rule(.securityCamera, .accessPoint, allowed: true),
        Rule(.securityCamera, .switchDevice, allowed: true),
        Rule(.securityCamera, .router, allowed: true),
        Rule(.securityCamera, .server, allowed: true),
        
        // ========== NILTERNius KOMPONENTE ==========
        // Nilternius - Nilternius komponenta
        Rule(.nilternius, .nilterniusServer, allowed: true),
        Rule(.nilternius, .router, allowed: true),
        Rule(.nilternius, .switchDevice, allowed: true),
        Rule(.nilternius, .firewall, allowed: true),
        
        // Nilternius Server - Nilternius server
        Rule(.nilterniusServer, .nilternius, allowed: true),
        Rule(.nilterniusServer, .server, allowed: true),
        Rule(.nilterniusServer, .router, allowed: true),
        Rule(.nilterniusServer, .switchDevice, allowed: true),
        Rule(.nilterniusServer, .firewall, allowed: true),
        
        // Business Server - poslovni server
        Rule(.businessServer, .server, allowed: true),
        Rule(.businessServer, .router, allowed: true),
        Rule(.businessServer, .switchDevice, allowed: true),
        Rule(.businessServer, .firewall, allowed: true),
        Rule(.businessServer, .loadBalancer, allowed: true),
        Rule(.businessServer, .databaseServer, allowed: true),
        Rule(.businessServer, .webServer, allowed: true),
        
        // ========== AREA KOMPONENTE ==========
        // Area komponente se mogu spajati s bilo čime (logički okružuju druge komponente)
        // Ali ne spajaju se direktno - one su kontejneri
        // Ovdje možemo definirati da se ne mogu direktno spajati
        Rule(.userArea, .userArea, allowed: false, reason: "Area komponente se ne mogu direktno spajati"),
        Rule(.businessArea, .businessArea, allowed: false, reason: "Area komponente se ne mogu direktno spajati"),
        Rule(.businessPrivateArea, .businessPrivateArea, allowed: false, reason: "Area komponente se ne mogu direktno spajati"),
        Rule(.nilterniusArea, .nilterniusArea, allowed: false, reason: "Area komponente se ne mogu direktno spajati"),
    ]
    
    /// Provjerava da li je konekcija dozvoljena između dvije komponente
    /// - Parameters:
    ///   - fromType: Tip komponente od koje se spaja
    ///   - toType: Tip komponente na koju se spaja
    /// - Returns: Tuple (allowed: Bool, reason: String?) - je li dozvoljeno i razlog
    static func isConnectionAllowed(from fromType: NetworkComponent.ComponentType, 
                                    to toType: NetworkComponent.ComponentType) -> (allowed: Bool, reason: String?) {
        // Provjeri eksplicitna pravila
        if let rule = rules.first(where: { 
            ($0.fromType == fromType && $0.toType == toType) ||
            ($0.fromType == toType && $0.toType == fromType) // Konekcije su obostrane
        }) {
            return (rule.allowed, rule.reason)
        }
        
        // Ako nema eksplicitnog pravila, default je da nije dozvoljeno
        // (za sigurnost - eksplicitno mora biti definirano)
        return (false, "Nema definirano pravilo za konekciju između \(fromType.displayName) i \(toType.displayName)")
    }
    
    /// Vraća sve dozvoljene tipove komponenti s kojima se može spojiti određeni tip
    /// - Parameter componentType: Tip komponente
    /// - Returns: Lista dozvoljenih tipova komponenti
    static func getAllowedConnectionTypes(for componentType: NetworkComponent.ComponentType) -> [NetworkComponent.ComponentType] {
        var allowedTypes: Set<NetworkComponent.ComponentType> = []
        
        for rule in rules {
            if rule.fromType == componentType && rule.allowed {
                allowedTypes.insert(rule.toType)
            }
            if rule.toType == componentType && rule.allowed {
                allowedTypes.insert(rule.fromType)
            }
        }
        
        return Array(allowedTypes).sorted(by: { $0.displayName < $1.displayName })
    }
}

