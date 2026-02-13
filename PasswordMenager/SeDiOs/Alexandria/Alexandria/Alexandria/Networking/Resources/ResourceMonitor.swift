//
//  ResourceMonitor.swift
//  Alexandria
//
//  Per-app resource dashboard – CPU, memorija, throttling.
//

import Foundation
import Darwin

/// Resource monitor – CPU, memory, per-app limits
@MainActor
final class ResourceMonitor: ObservableObject {
    static let shared = ResourceMonitor()
    
    @Published private(set) var cpuUsagePercent: Double = 0
    @Published private(set) var memoryUsedBytes: UInt64 = 0
    @Published private(set) var memoryLimitBytes: UInt64? = nil
    
    private var timer: Timer?
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetrics()
            }
        }
        timer?.fire()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateMetrics() {
        memoryUsedBytes = getCurrentMemoryUsage()
        cpuUsagePercent = getCPUUsage()
    }
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return info.resident_size
    }
    
    private func getCPUUsage() -> Double {
        var totalUsage: Double = 0
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &threadList, &threadCount) == KERN_SUCCESS,
              let threads = threadList else { return 0 }
        defer { vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.size)) }
        
        for i in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var count = mach_msg_type_number_t(THREAD_INFO_MAX)
            let result = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
                }
            }
            if result == KERN_SUCCESS, (threadInfo.flags & TH_FLAGS_IDLE) == 0 {
                totalUsage += Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100
            }
        }
        return min(totalUsage, 100)
    }
    
    var memoryUsedMB: Double {
        Double(memoryUsedBytes) / (1024 * 1024)
    }
}
