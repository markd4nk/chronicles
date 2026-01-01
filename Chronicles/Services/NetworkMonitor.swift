//
//  NetworkMonitor.swift
//  Chronicles
//
//  Network connectivity monitor using NWPathMonitor
//

import Foundation
import Network
import Combine

/// Monitors network connectivity status
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    /// Whether the device is connected to the network (thread-safe)
    @Published private(set) var isConnected: Bool = true
    
    /// The current connection type
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    /// Whether the connection is expensive (cellular, hotspot)
    @Published private(set) var isExpensive: Bool = false
    
    /// Whether the connection is constrained (low data mode)
    @Published private(set) var isConstrained: Bool = false
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.chronicles.networkmonitor")
    
    enum ConnectionType: Sendable {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    /// Start monitoring network changes
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
        monitor.start(queue: queue)
    }
    
    /// Handle path update on background queue, then dispatch to main
    private func handlePathUpdate(_ path: NWPath) {
        let connected = path.status == .satisfied
        let expensive = path.isExpensive
        let constrained = path.isConstrained
        
        let type: ConnectionType
        if path.usesInterfaceType(.wifi) {
            type = .wifi
        } else if path.usesInterfaceType(.cellular) {
            type = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            type = .ethernet
        } else {
            type = .unknown
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = connected
            self?.isExpensive = expensive
            self?.isConstrained = constrained
            self?.connectionType = type
            
            #if DEBUG
            print("[NetworkMonitor] Status: \(connected ? "Connected" : "Disconnected"), Type: \(type)")
            #endif
        }
    }
    
    /// Check if we should attempt network operations
    /// Returns true if connected, false if definitely offline
    var shouldAttemptNetworkOperation: Bool {
        isConnected
    }
    
    /// Wait for network to become available (with timeout)
    /// - Parameter timeout: Maximum time to wait in seconds
    /// - Returns: True if network became available, false if timed out
    @MainActor
    func waitForConnection(timeout: TimeInterval = 5.0) async -> Bool {
        if isConnected {
            return true
        }
        
        // Wait for connection with timeout
        let deadline = Date().addingTimeInterval(timeout)
        
        while Date() < deadline {
            if isConnected {
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        return isConnected
    }
}

// MARK: - Convenience Extensions

extension NetworkMonitor {
    /// Execute operation only if network is available
    /// - Parameters:
    ///   - fallback: Value to return if offline
    ///   - operation: The network operation to execute
    /// - Returns: Result of operation or fallback value
    func executeIfOnline<T>(fallback: T, operation: () async throws -> T) async -> T {
        guard isConnected else {
            print("[NetworkMonitor] Skipping operation - offline")
            return fallback
        }
        
        do {
            return try await operation()
        } catch {
            print("[NetworkMonitor] Operation failed: \(error.localizedDescription)")
            return fallback
        }
    }
    
    /// Execute operation only if network is available, throwing if offline
    func executeIfOnlineOrThrow<T>(operation: () async throws -> T) async throws -> T {
        guard isConnected else {
            throw NSError(
                domain: "NetworkMonitor",
                code: -1009,
                userInfo: [NSLocalizedDescriptionKey: "No network connection"]
            )
        }
        
        return try await operation()
    }
}
