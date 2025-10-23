//
//  MessageBubble.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    var onRetry: (() -> Void)? = nil
    
    @State private var cachedImage: UIImage?
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser { Spacer(minLength: 50) }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                // Image handling
                if message.mediaType == .image {
                    if let mediaURL = message.mediaURL {
                        // Image uploaded - show from URL
                        let _ = print("🖼️ MessageBubble displaying image: \(mediaURL)")
                        AsyncImage(url: URL(string: mediaURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 200, height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 250)
                                    .cornerRadius(18)
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 200, height: 200)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else if let cachedImage = cachedImage {
                        // Image pending upload - show cached image with overlay
                        ZStack(alignment: .bottomTrailing) {
                            Image(uiImage: cachedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 250)
                                .cornerRadius(18)
                                .opacity(message.status == .failed ? 0.6 : 0.9)
                            
                            // Status overlay
                            HStack(spacing: 4) {
                                if message.status == .failed {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(Color.red).padding(-4))
                                    Text("Failed")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                } else {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(.white)
                                    Text("Uploading...")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(8)
                        }
                    } else {
                        // No cached image - show placeholder (shouldn't happen often)
                        VStack(spacing: 8) {
                            if message.status == .failed {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.red)
                                Text("Image upload failed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ProgressView()
                                Text("Loading image...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 200, height: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(18)
                    }
                }
                
                // Message bubble
                if let text = message.text {
                    Text(text)
                        .font(.system(size: 16))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            isFromCurrentUser ?
                            LinearGradient(colors: [Color(hex: "0084FF"), Color(hex: "0066CC")],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color(.systemGray5), Color(.systemGray6)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)
                        )
                        .foregroundStyle(isFromCurrentUser ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                
                // Timestamp and status
                HStack(spacing: 4) {
                    Text(message.timestamp.timeString)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    if isFromCurrentUser {
                        HStack(spacing: 2) {
                            statusIcon
                            if message.status == .read && message.readBy.count > 1 {
                                Text("Read")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.blue)
                            }
                            
                            // Tap to retry indicator
                            if message.status == .failed {
                                Text("• Tap to retry")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser { Spacer(minLength: 50) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            if message.status == .failed {
                onRetry?()
            }
        }
        .onAppear {
            // Load cached image if message has no URL yet
            if message.mediaType == .image && message.mediaURL == nil,
               let messageID = message.id {
                Task { @MainActor in
                    cachedImage = LocalStorageManager.shared.loadImage(forMessageID: messageID)
                }
            }
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            HStack(spacing: 2) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .sent:
            HStack(spacing: 2) {
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .delivered:
            HStack(spacing: -2) {
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .read:
            HStack(spacing: -2) {
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .fontWeight(.semibold)
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .fontWeight(.semibold)
            }
        case .failed:
            HStack(spacing: 2) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubble(
            message: Message(
                id: "1",
                conversationID: "conv1",
                senderID: "user1",
                text: "Hey, how are you?",
                mediaURL: nil,
                mediaType: nil,
                timestamp: Date(),
                status: .sent,
                readBy: ["user1"]
            ),
            isFromCurrentUser: true
        )
        
        MessageBubble(
            message: Message(
                id: "2",
                conversationID: "conv1",
                senderID: "user2",
                text: "I'm doing great! How about you?",
                mediaURL: nil,
                mediaType: nil,
                timestamp: Date(),
                status: .read,
                readBy: ["user1", "user2"]
            ),
            isFromCurrentUser: false
        )
    }
    .padding()
}

