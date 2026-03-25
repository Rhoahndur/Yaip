import Foundation

/// Contract for network connectivity monitoring.
///
/// - Important: Used for UI feedback only, never to block operations.
///   Firebase SDK handles its own connectivity detection. See `OPTIMISTIC_NETWORK_APPROACH.md`.
protocol NetworkMonitorProtocol: AnyObject {
    /// Whether the device currently has network connectivity.
    var isConnected: Bool { get }
    /// The current connection type (wifi, cellular, etc.).
    var connectionType: NetworkMonitor.ConnectionType { get }
    /// Whether a connectivity check is currently in progress.
    var isCheckingConnection: Bool { get }

    /// Start monitoring network changes via `NWPathMonitor`.
    func startMonitoring()
    /// Trigger an immediate connectivity re-check.
    func checkConnectionNow()
    /// Force a connectivity check with an async HTTP probe. Runs on `@MainActor`.
    @MainActor func forceConnectivityCheck() async
    /// Stop monitoring and release the `NWPathMonitor`.
    func stopMonitoring()
}
