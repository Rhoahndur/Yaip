//
//  InAppBannerView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import SwiftUI

/// In-app notification banner (shown when app is in foreground)
struct InAppBannerView: View {
    let senderName: String
    let messageText: String
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(senderName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(messageText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            )
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}

/// Manager for in-app banner notifications
@MainActor
class InAppBannerManager: ObservableObject {
    static let shared = InAppBannerManager()
    
    @Published var currentBanner: BannerData?
    @Published var showBanner = false
    
    private init() {}
    
    struct BannerData: Identifiable {
        let id = UUID()
        let conversationID: String
        let senderName: String
        let messageText: String
    }
    
    /// Show banner for a new message
    func showMessageBanner(
        conversationID: String,
        senderName: String,
        messageText: String
    ) {
        // Don't show if already showing the same banner
        if let current = currentBanner,
           current.conversationID == conversationID {
            return
        }
        
        currentBanner = BannerData(
            conversationID: conversationID,
            senderName: senderName,
            messageText: messageText
        )
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showBanner = true
        }
        
        // Auto-dismiss after 4 seconds
        Task {
            try? await Task.sleep(for: .seconds(4))
            dismissBanner()
        }
    }
    
    /// Dismiss banner
    func dismissBanner() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showBanner = false
        }
        
        // Clear data after animation
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            currentBanner = nil
        }
    }
}

// MARK: - Banner Overlay Modifier

struct InAppBannerModifier: ViewModifier {
    @StateObject private var bannerManager = InAppBannerManager.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if bannerManager.showBanner, let banner = bannerManager.currentBanner {
                InAppBannerView(
                    senderName: banner.senderName,
                    messageText: banner.messageText,
                    onTap: {
                        // Post notification to open conversation
                        NotificationCenter.default.post(
                            name: .openConversation,
                            object: nil,
                            userInfo: ["conversationID": banner.conversationID]
                        )
                        bannerManager.dismissBanner()
                    },
                    onDismiss: {
                        bannerManager.dismissBanner()
                    }
                )
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

extension View {
    func withInAppBanner() -> some View {
        modifier(InAppBannerModifier())
    }
}

#Preview {
    VStack {
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.1))
    .overlay(alignment: .top) {
        InAppBannerView(
            senderName: "Alice Smith",
            messageText: "Hey! How are you doing today?",
            onTap: { print("Tapped") },
            onDismiss: { print("Dismissed") }
        )
        .padding(.top, 50)
    }
}

