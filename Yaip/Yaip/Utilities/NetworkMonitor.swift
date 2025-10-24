//
//  NetworkMonitor.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import Network
import Combine

/// Monitors network connectivity status
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .wifi
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        // Start with optimistic connection state
        isConnected = true
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            self.updateConnectionState(from: path)
        }
        monitor.start(queue: queue)
        print("🔍 Network monitoring started with initial state: isConnected = \(isConnected)")
        
        // Also check immediately to get current state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkConnectionNow()
        }
    }
    
    /// Manually check connection status now (workaround for NWPathMonitor not always firing updates)
    func checkConnectionNow() {
        print("🔄 Manually checking connection status...")
        let currentPath = monitor.currentPath
        updateConnectionState(from: currentPath)
    }
    
    private func updateConnectionState(from path: NWPath) {
        let newConnectionState = path.status == .satisfied
        let newConnectionType = self.getConnectionType(from: path)
        
        print("🌐 Network status changed:")
        print("   Status: \(path.status)")
        print("   isExpensive: \(path.isExpensive)")
        print("   isConstrained: \(path.isConstrained)")
        print("   Connected: \(newConnectionState)")
        print("   Type: \(newConnectionType)")
        print("   Available interfaces: \(path.availableInterfaces.map { $0.name })")
        print("   WiFi available: \(path.usesInterfaceType(.wifi))")
        print("   Ethernet available: \(path.usesInterfaceType(.wiredEthernet))")
        print("   Cellular available: \(path.usesInterfaceType(.cellular))")
        
        DispatchQueue.main.async {
            // Always update (let @Published handle change notification)
            let oldState = self.isConnected
            self.isConnected = newConnectionState
            self.connectionType = newConnectionType
            
            print("📱 Updated NetworkMonitor.isConnected: \(oldState) → \(self.isConnected)")
            
            if newConnectionState {
                print("✅ ONLINE via \(newConnectionType)")
            } else {
                print("❌ OFFLINE - No network available")
            }
        }
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }
}

