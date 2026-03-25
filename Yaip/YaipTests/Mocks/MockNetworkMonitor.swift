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
}
