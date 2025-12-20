//
//  NetworkSimulation.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation
import SwiftUI

/// Simulacija mrežnog prometa
class NetworkSimulation: ObservableObject {
    @Published var isRunning = false
    @Published var packets: [AnimatedPacket] = []
    @Published var packetCount: Int = 0
    @Published var bytesTransferred: Int64 = 0
    
    private var simulationTimer: Timer?
    weak var topology: NetworkTopology?
    
    init(topology: NetworkTopology? = nil) {
        self.topology = topology
    }
    
    func setTopology(_ topology: NetworkTopology) {
        self.topology = topology
    }
    
    func start() {
        guard !isRunning else { return }
        guard let topology = topology else { return }
        guard topology.clientA != nil && topology.clientB != nil else { return }
        
        isRunning = true
        packetCount = 0
        bytesTransferred = 0
        
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.generatePacket()
        }
    }
    
    func stop() {
        isRunning = false
        simulationTimer?.invalidate()
        simulationTimer = nil
        packets.removeAll()
    }
    
    private func generatePacket() {
        guard let topology = topology else { return }
        guard let clientA = topology.clientA,
              let clientB = topology.clientB else { return }
        
        // Find path between A and B
        let path = findPath(from: clientA.id, to: clientB.id)
        guard !path.isEmpty else { return }
        
        // Create packet
        let packet = NetworkPacket(
            id: UUID(),
            source: clientA.id,
            destination: clientB.id,
            payload: Data([UInt8].init(repeating: 0, count: Int.random(in: 64...1500))),
            timestamp: Date(),
            packetProtocol: [.tcp, .udp, .http, .https].randomElement() ?? .tcp
        )
        
        // Create animated packet
        let animatedPacket = AnimatedPacket(
            id: packet.id,
            packet: packet,
            path: path,
            progress: 0.0
        )
        
        packets.append(animatedPacket)
        packetCount += 1
        bytesTransferred += Int64(packet.payload.count)
        
        // Animate packet
        animatePacket(animatedPacket)
    }
    
    private func animatePacket(_ animatedPacket: AnimatedPacket) {
        let duration: TimeInterval = 2.0
        let steps = 60
        let stepDuration = duration / Double(steps)
        
        var currentStep = 0
        
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if let index = self.packets.firstIndex(where: { $0.id == animatedPacket.id }) {
                let progress = Double(currentStep) / Double(steps)
                self.packets[index].progress = progress
                
                if progress >= 1.0 {
                    // Packet reached destination
                    self.packets.removeAll { $0.id == animatedPacket.id }
                    timer.invalidate()
                }
            } else {
                timer.invalidate()
            }
            
            currentStep += 1
        }
    }
    
    private func findPath(from: UUID, to: UUID) -> [UUID] {
        guard let topology = topology else { return [] }
        // Simple BFS to find path
        var queue: [(UUID, [UUID])] = [(from, [from])]
        var visited: Set<UUID> = [from]
        
        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()
            
            if current == to {
                return path
            }
            
            let connections = topology.getConnections(for: current)
            for connection in connections {
                let next = connection.fromComponentId == current ? connection.toComponentId : connection.fromComponentId
                
                if !visited.contains(next) {
                    visited.insert(next)
                    queue.append((next, path + [next]))
                }
            }
        }
        
        return []
    }
}

/// Animated packet for visualization
class AnimatedPacket: Identifiable, ObservableObject {
    let id: UUID
    let packet: NetworkPacket
    let path: [UUID]
    @Published var progress: Double
    
    init(id: UUID, packet: NetworkPacket, path: [UUID], progress: Double) {
        self.id = id
        self.packet = packet
        self.path = path
        self.progress = progress
    }
}

