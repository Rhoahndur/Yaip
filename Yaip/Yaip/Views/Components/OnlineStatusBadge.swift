//
//  OnlineStatusBadge.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import SwiftUI

struct OnlineStatusBadge: View {
    let status: UserStatus
    let size: CGFloat
    
    init(status: UserStatus, size: CGFloat = 12) {
        self.status = status
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: size * 0.15)
            )
    }
    
    private var statusColor: Color {
        switch status {
        case .online:
            return .green
        case .away:
            return .orange
        case .offline:
            return .gray
        }
    }
}

struct OnlineStatusText: View {
    let status: UserStatus
    let lastSeen: Date?
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .online:
            return .green
        case .away:
            return .orange
        case .offline:
            return .gray
        }
    }
    
    private var statusText: String {
        switch status {
        case .online:
            return "Online"
        case .away:
            return "Away"
        case .offline:
            if let lastSeen = lastSeen {
                return "Last seen \(lastSeen.relativeTime)"
            }
            return "Offline"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            OnlineStatusBadge(status: .online)
            Text("Online")
        }
        
        HStack {
            OnlineStatusBadge(status: .away)
            Text("Away")
        }
        
        HStack {
            OnlineStatusBadge(status: .offline)
            Text("Offline")
        }
        
        Divider()
        
        OnlineStatusText(status: .online, lastSeen: nil)
        OnlineStatusText(status: .away, lastSeen: nil)
        OnlineStatusText(status: .offline, lastSeen: Date().addingTimeInterval(-3600))
    }
    .padding()
}

