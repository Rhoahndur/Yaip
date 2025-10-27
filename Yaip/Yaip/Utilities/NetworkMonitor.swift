//
//  NetworkMonitor.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import Network
import Combine
import UIKit

/// Monitors network connectivity status
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .wifi
    @Published var isCheckingConnection: Bool = false  // Track manual check state for UI

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var reconnectTimer: Timer?
    private var isPerformingRealCheck = false
    private var appLifecycleObservers: [Any] = []
    
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
        setupAppLifecycleObservers()
    }

    deinit {
        stopMonitoring()
        // Remove app lifecycle observers
        appLifecycleObservers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Setup observers for app lifecycle events
    private func setupAppLifecycleObservers() {
        // Check connection when app becomes active (e.g., after unlocking device)
        let willEnterForeground = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 App entering foreground - immediate fast check")
            Task { @MainActor in
                await self?.performRealConnectivityCheckAsync()
            }
        }

        let didBecomeActive = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 App became active - immediate fast check")
            Task { @MainActor in
                await self?.performRealConnectivityCheckAsync()
            }
        }

        appLifecycleObservers = [willEnterForeground, didBecomeActive]
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            self.updateConnectionState(from: path)
        }
        monitor.start(queue: queue)
        print("🔍 Network monitoring started")

        // Check immediately - no delay
        Task { @MainActor in
            await self.performRealConnectivityCheckAsync()
        }
    }
    
    /// Manually check connection status now (workaround for NWPathMonitor not always firing updates)
    func checkConnectionNow() {
        print("🔄 Quick check - triggering fast async connectivity check...")

        // Skip NWPathMonitor (it's unreliable) - go straight to real check
        Task { @MainActor in
            await self.performRealConnectivityCheckAsync()
        }
    }

    /// Force a comprehensive connectivity check (used when user taps reconnect button)
    @MainActor
    func forceConnectivityCheck() async {
        print("🔄 FORCE CHECK: User triggered manual connectivity check")

        // First, check NWPathMonitor
        let currentPath = monitor.currentPath
        print("   NWPathMonitor status: \(currentPath.status)")

        // Always perform a real connectivity check regardless of what NWPathMonitor says
        await performRealConnectivityCheckAsync()
    }

    /// Async version of performRealConnectivityCheck for direct await calls
    /// Uses FAST parallel checks with multiple endpoints
    @MainActor
    private func performRealConnectivityCheckAsync() async {
        // Prevent multiple concurrent checks
        guard !isPerformingRealCheck else {
            print("⏳ Real check already in progress, skipping...")
            return
        }

        isPerformingRealCheck = true
        isCheckingConnection = true  // Update UI state
        defer {
            isPerformingRealCheck = false
            isCheckingConnection = false  // Reset UI state
        }

        print("🌐 Performing FAST connectivity check with multiple endpoints...")

        // Race multiple endpoints for faster detection
        let endpoints = [
            "https://www.google.com",
            "https://www.cloudflare.com",
            "https://1.1.1.1"
        ]

        await withTaskGroup(of: Bool.self) { group in
            for endpoint in endpoints {
                group.addTask {
                    await self.checkEndpoint(endpoint)
                }
            }

            // Wait for the FIRST successful response
            for await isReachable in group {
                if isReachable {
                    print("✅ FAST CHECK: Internet IS available!")

                    // Cancel remaining checks
                    group.cancelAll()

                    // Force update to online if we're currently showing offline
                    if !self.isConnected {
                        let oldState = self.isConnected
                        self.isConnected = true
                        self.connectionType = .wifi
                        print("📱 Updated NetworkMonitor.isConnected: \(oldState) → \(self.isConnected) (via fast check)")
                        print("🎉 CONNECTION RESTORED - Triggering reconnect notifications")
                        NotificationCenter.default.post(name: .networkDidReconnect, object: nil)
                        self.stopReconnectPolling()
                    } else {
                        print("✓ Already showing online, no update needed")
                    }

                    return
                }
            }

            // All checks failed
            print("❌ FAST CHECK: All endpoints failed - still offline")

            // Confirm offline state
            if self.isConnected {
                let oldState = self.isConnected
                self.isConnected = false
                self.connectionType = .unknown
                print("📱 Updated NetworkMonitor.isConnected: \(oldState) → \(self.isConnected)")
                self.startReconnectPolling()
            }
        }
    }

    /// Check a single endpoint with fast timeout
    private func checkEndpoint(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 2.0  // Very fast timeout - 2 seconds
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                print("✅ Endpoint \(urlString) reachable")
                return true
            }
        } catch {
            // Fail silently - we're racing multiple endpoints
        }

        return false
    }
    
    /// Legacy method - now redirects to async version
    private func performRealConnectivityCheck() {
        Task { @MainActor in
            await performRealConnectivityCheckAsync()
        }
    }
    
    private func updateConnectionState(from path: NWPath) {
        let newConnectionState = path.status == .satisfied
        let newConnectionType = self.getConnectionType(from: path)

        print("🌐 Network status update:")
        print("   Path status: \(path.status)")
        print("   Connected: \(newConnectionState)")
        print("   Type: \(newConnectionType)")
        print("   WiFi: \(path.usesInterfaceType(.wifi))")
        print("   Cellular: \(path.usesInterfaceType(.cellular))")
        print("   Ethernet: \(path.usesInterfaceType(.wiredEthernet))")

        DispatchQueue.main.async {
            // Always update (let @Published handle change notification)
            let oldState = self.isConnected
            self.isConnected = newConnectionState
            self.connectionType = newConnectionType

            print("📱 Updated NetworkMonitor.isConnected: \(oldState) → \(self.isConnected)")

            // Detect transition from offline → online
            let wasOffline = oldState == false
            let isNowOnline = newConnectionState == true

            if wasOffline && isNowOnline {
                print("🎉 CONNECTION RESTORED - Triggering reconnect notifications")
                // Post notification for immediate sync
                NotificationCenter.default.post(name: .networkDidReconnect, object: nil)
            }

            if newConnectionState {
                print("✅ ONLINE via \(newConnectionType)")
                // Stop polling timer when we're back online
                self.stopReconnectPolling()
            } else {
                print("❌ OFFLINE - No network available")
                // Start polling timer to periodically check for reconnection
                self.startReconnectPolling()
            }
        }
    }
    
    func stopMonitoring() {
        monitor.cancel()
        stopReconnectPolling()
    }
    
    /// Start periodic polling to check for reconnection (only runs when offline)
    /// AGGRESSIVE: Checks every 1 second for immediate reconnection detection
    private func startReconnectPolling() {
        // Don't start if already running
        guard reconnectTimer == nil else { return }

        print("⏱️ Starting AGGRESSIVE reconnect polling (every 1 second)")
        print("   Note: Fast polling for immediate WiFi recovery")

        // First check immediately
        Task { @MainActor in
            await self.performRealConnectivityCheckAsync()
        }

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Only check if we're still offline
            if !self.isConnected {
                print("🔄 Fast polling check...")
                Task { @MainActor in
                    await self.performRealConnectivityCheckAsync()
                }
            }
        }
    }
    
    /// Stop periodic polling (called when we detect online)
    private func stopReconnectPolling() {
        if reconnectTimer != nil {
            print("⏹️ Stopping reconnect polling - we're online!")
            reconnectTimer?.invalidate()
            reconnectTimer = nil
        }
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

// MARK: - Notification Names
extension Notification.Name {
    static let networkDidReconnect = Notification.Name("networkDidReconnect")
}

