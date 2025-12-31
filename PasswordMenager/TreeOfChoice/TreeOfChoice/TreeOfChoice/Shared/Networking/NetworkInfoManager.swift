//
//  NetworkInfoManager.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation
import SystemConfiguration
#if os(macOS)
import Network
#endif

/// Manager za dohvaćanje mrežnih informacija (IP adrese, MAC adresa, gateway status)
class NetworkInfoManager: ObservableObject {
    
    @Published var privateIP: String = "Unknown"
    @Published var publicIP: String = "Unknown"
    @Published var macAddress: String = "Unknown"
    @Published var isGateway: Bool = false
    @Published var gatewayIP: String = "Unknown"
    @Published var gatewayMAC: String = "Unknown"
    @Published var serverIP: String = "Unknown"
    @Published var port: String = "Unknown"
    
    static let shared = NetworkInfoManager()
    
    private init() {
        // Ne osvježavaj automatski pri inicijalizaciji
        // Osvježi tek kada se pozove refreshNetworkInfo() eksplicitno
    }
    
    /// Osvježi sve mrežne informacije
    func refreshNetworkInfo() {
        // Dohvati osnovne informacije (sinkrono)
        getPrivateIP()
        getMACAddress()
        checkGatewayStatus()
        
        // Javna IP se dohvaća asinkrono (preko API-ja)
        getPublicIP()
    }
    
    /// Dohvati privatnu IP adresu
    private func getPrivateIP() {
        #if os(macOS)
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return }
        guard let firstAddr = ifaddr else { return }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                let name = String(cString: interface.ifa_name)
                
                // Ignoriraj loopback i virtualne interfejse
                if name == "lo0" || name.hasPrefix("vmnet") || name.hasPrefix("vboxnet") {
                    continue
                }
                
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr,
                           socklen_t(interface.ifa_addr.pointee.sa_len),
                           &hostname,
                           socklen_t(hostname.count),
                           nil,
                           socklen_t(0),
                           NI_NUMERICHOST)
                address = String(cString: hostname)
                
                // Uzmi prvu validnu IPv4 adresu
                if let addr = address, !addr.isEmpty, addr.contains(".") {
                    self.privateIP = addr
                    break
                }
            }
        }
        freeifaddrs(ifaddr)
        #else
        self.privateIP = "Not available"
        #endif
    }
    
    /// Dohvati javnu IP adresu (preko external API-ja)
    private func getPublicIP() {
        // Pokušaj dohvatiti javnu IP preko external API-ja
        let urls = [
            "https://api.ipify.org",
            "https://icanhazip.com",
            "https://ifconfig.me/ip"
        ]
        
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            
            let semaphore = DispatchSemaphore(value: 0)
            var result: String?
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                defer { semaphore.signal() }
                
                if let data = data, let ip = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    result = ip
                }
            }.resume()
            
            if semaphore.wait(timeout: .now() + 2) == .success, let ip = result, !ip.isEmpty {
                self.publicIP = ip
                return
            }
        }
        
        self.publicIP = "Unknown"
    }
    
    /// Dohvati MAC adresu
    private func getMACAddress() {
        #if os(macOS)
        // Koristi system_profiler za MAC adresu (najpouzdaniji način)
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPNetworkDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            // Parsiraj MAC adresu iz outputa
            let pattern = "MAC Address: ([0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2})"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = output as NSString
                let results = regex.matches(in: output, options: [], range: NSRange(location: 0, length: nsString.length))
                
                // Uzmi prvu MAC adresu koja nije 00:00:00:00:00:00
                for result in results {
                    if result.numberOfRanges > 1 {
                        let range = result.range(at: 1)
                        let mac = nsString.substring(with: range)
                        if mac != "00:00:00:00:00:00" {
                            self.macAddress = mac
                            return
                        }
                    }
                }
            }
        }
        
        // Fallback: pokušaj preko ifconfig
        let ifconfigTask = Process()
        ifconfigTask.launchPath = "/sbin/ifconfig"
        
        let ifconfigPipe = Pipe()
        ifconfigTask.standardOutput = ifconfigPipe
        ifconfigTask.launch()
        ifconfigTask.waitUntilExit()
        
        let ifconfigData = ifconfigPipe.fileHandleForReading.readDataToEndOfFile()
        if let ifconfigOutput = String(data: ifconfigData, encoding: .utf8) {
            let pattern = "ether ([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2})"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = ifconfigOutput as NSString
                if let result = regex.firstMatch(in: ifconfigOutput, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    if result.numberOfRanges > 1 {
                        let range = result.range(at: 1)
                        let mac = nsString.substring(with: range)
                        if mac != "00:00:00:00:00:00" {
                            self.macAddress = mac
                            return
                        }
                    }
                }
            }
        }
        
        self.macAddress = "Unknown"
        #else
        self.macAddress = "Not available"
        #endif
    }
    
    /// Provjeri jesmo li gateway (provjerava MAC adresu gatewaya)
    private func checkGatewayStatus() {
        #if os(macOS)
        var gatewayIPAddress: String?
        
        // Provjeri default route
        let task = Process()
        task.launchPath = "/sbin/route"
        task.arguments = ["-n", "get", "default"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            // Parsiraj gateway IP
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("gateway:") {
                    let parts = line.components(separatedBy: ":")
                    if parts.count > 1 {
                        gatewayIPAddress = parts[1].trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        
        if let gateway = gatewayIPAddress, !gateway.isEmpty {
            self.gatewayIP = gateway
            
            // Dohvati MAC adresu gatewaya iz ARP tablice
            let arpTask = Process()
            arpTask.launchPath = "/usr/sbin/arp"
            arpTask.arguments = ["-n", gateway]
            
            let arpPipe = Pipe()
            arpTask.standardOutput = arpPipe
            arpTask.launch()
            arpTask.waitUntilExit()
            
            let arpData = arpPipe.fileHandleForReading.readDataToEndOfFile()
            if let arpOutput = String(data: arpData, encoding: .utf8) {
                // Parsiraj MAC adresu iz ARP outputa
                // Format: gateway (192.168.1.1) at aa:bb:cc:dd:ee:ff on en0
                let pattern = "at ([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2})"
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let nsString = arpOutput as NSString
                    if let result = regex.firstMatch(in: arpOutput, options: [], range: NSRange(location: 0, length: nsString.length)) {
                        if result.numberOfRanges > 1 {
                            let range = result.range(at: 1)
                            let gatewayMAC = nsString.substring(with: range)
                            self.gatewayMAC = gatewayMAC
                            
                            // Provjeri je li naša MAC adresa ista kao gateway MAC adresa
                            // Ako jesmo, onda smo gateway
                            self.isGateway = (self.macAddress.lowercased() == gatewayMAC.lowercased())
                        }
                    }
                }
            }
            
            // Ako nismo uspjeli dohvatiti MAC adresu iz ARP-a, provjeri IP adresu
            if self.gatewayMAC == "Unknown" {
                // Provjeri je li naša IP adresa jednaka gateway IP-u
                self.isGateway = (self.privateIP == gateway)
            }
        } else {
            // Alternativna provjera: provjeri je li naša IP u gateway range-u
            // Ako je naša IP 192.168.1.1 ili 10.0.0.1 ili slično, vjerojatno smo gateway
            let ipParts = self.privateIP.components(separatedBy: ".")
            if ipParts.count == 4, let lastOctet = Int(ipParts[3]), lastOctet == 1 {
                self.isGateway = true
                self.gatewayIP = self.privateIP
            }
        }
        #else
        self.isGateway = false
        #endif
    }
    
    /// Postavi server IP adresu (iz serverAddress URL-a)
    func setServerIP(from serverAddress: String) {
        guard let url = URL(string: serverAddress) else {
            self.serverIP = "Unknown"
            return
        }
        
        // Postavi port iz URL-a
        if let port = url.port {
            self.port = "\(port)"
        } else {
            // Default port ovisno o shemi
            if url.scheme == "https" || url.scheme == "wss" {
                self.port = "443"
            } else if url.scheme == "http" || url.scheme == "ws" {
                self.port = "80"
            } else {
                self.port = "443"
            }
        }
        
        if let host = url.host {
            // Pokušaj dohvatiti IP adresu hostname-a
            let hostname = host as CFString
            let hostRef = CFHostCreateWithName(nil, hostname).takeRetainedValue()
            CFHostStartInfoResolution(hostRef, .addresses, nil)
            
            var resolved: DarwinBoolean = false
            if let addresses = CFHostGetAddressing(hostRef, &resolved)?.takeUnretainedValue() as? [Data] {
                for address in addresses {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    address.withUnsafeBytes { bytes in
                        let sockaddr = bytes.bindMemory(to: sockaddr.self).baseAddress!
                        getnameinfo(sockaddr,
                                   socklen_t(address.count),
                                   &hostname,
                                   socklen_t(hostname.count),
                                   nil,
                                   socklen_t(0),
                                   NI_NUMERICHOST)
                    }
                    let ip = String(cString: hostname)
                    if !ip.isEmpty && ip.contains(".") {
                        self.serverIP = ip
                        return
                    }
                }
            }
            
            // Fallback: koristi hostname
            self.serverIP = host
        } else {
            self.serverIP = "Unknown"
        }
    }
}


