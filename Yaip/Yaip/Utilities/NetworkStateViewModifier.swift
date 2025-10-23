//
//  NetworkStateViewModifier.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/23/25.
//

import SwiftUI

// MARK: - Network Reconnection Handler

/// View modifier that triggers an action when network reconnects
struct NetworkReconnectModifier: ViewModifier {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    let onReconnect: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
                // Only trigger on reconnection (false → true)
                if !oldValue && newValue {
                    Task {
                        await onReconnect()
                    }
                }
            }
    }
}

extension View {
    /// Executes an async action when the network reconnects
    func onNetworkReconnect(perform action: @escaping () async -> Void) -> some View {
        modifier(NetworkReconnectModifier(onReconnect: action))
    }
}

// MARK: - Network State Banner

/// View modifier that displays a network state banner when offline
struct NetworkStateBannerModifier: ViewModifier {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            // Offline banner
            if !networkMonitor.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(.white)
                        .font(.caption)
                    Text("No internet connection")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            content
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }
}

extension View {
    /// Displays a banner at the top when network is offline
    func networkStateBanner() -> some View {
        modifier(NetworkStateBannerModifier())
    }
}

