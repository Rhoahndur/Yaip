import Foundation
@testable import Yaip

final class MockNetworkMonitor: NetworkMonitorProtocol {
    var isConnected: Bool = true
    var connectionType: NetworkMonitor.ConnectionType = .wifi
    var isCheckingConnection: Bool = false

    func startMonitoring() {}
    func checkConnectionNow() {}
    func forceConnectivityCheck() async {}
    func stopMonitoring() {}

    /// Simulate network reconnection: sets isConnected and posts .networkDidReconnect
    func simulateReconnect() {
        isConnected = true
        NotificationCenter.default.post(name: .networkDidReconnect, object: nil)
    }

    /// Simulate network loss: clears isConnected and posts .networkDidDisconnect
    func simulateDisconnect() {
        isConnected = false
        NotificationCenter.default.post(name: .networkDidDisconnect, object: nil)
    }
}
