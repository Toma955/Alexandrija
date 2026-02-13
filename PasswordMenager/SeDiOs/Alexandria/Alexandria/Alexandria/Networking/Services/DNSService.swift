//
//  DNSService.swift
//  Alexandria
//
//  DNS – pretvara domene u IP (getaddrinfo).
//

import Foundation
import Darwin

enum DNSService {
    /// Dohvati IP adrese za hostname
    static func lookup(host: String) async throws -> [String] {
        try await Task.detached(priority: .userInitiated) {
            var hints = addrinfo()
            hints.ai_family = AF_UNSPEC
            hints.ai_socktype = SOCK_STREAM
            var result: UnsafeMutablePointer<addrinfo>?
            let status = getaddrinfo(host, nil, &hints, &result)
            guard status == 0, let res = result else {
                throw DNSError.resolveFailed
            }
            defer { freeaddrinfo(res) }
            var ips: [String] = []
            var ptr = res
            while true {
                var hostbuf = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(ptr.pointee.ai_addr, ptr.pointee.ai_addrlen, &hostbuf, socklen_t(hostbuf.count), nil, 0, NI_NUMERICHOST) == 0 {
                    ips.append(String(cString: hostbuf))
                }
                guard let next = ptr.pointee.ai_next else { break }
                ptr = next
            }
            return ips
        }.value
    }
    
    enum DNSError: Error {
        case resolveFailed
    }
}
