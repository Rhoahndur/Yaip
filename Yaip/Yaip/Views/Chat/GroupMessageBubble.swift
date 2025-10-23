//
//  GroupMessageBubble.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI
import Combine

struct GroupMessageBubble: View {
    let message: Message
    let senderName: String
    let isFromCurrentUser: Bool
    let conversation: Conversation
    let currentUserID: String
    var onRetry: (() -> Void)? = nil
    
    @State private var showingReadReceipts = false
    @State private var cachedImage: UIImage?
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name
                if isFromCurrentUser {
                    Text("You")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                        .padding(.trailing, 12)
                } else {
                    Text(senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 12)
                }
                
                // Image + Text together in one bubble (if both present)
                if message.mediaType == .image {
                    VStack(alignment: .leading, spacing: 0) {
                        // Image part
                        if let mediaURL = message.mediaURL {
                            // Image uploaded - show from URL
                            let _ = print("🖼️ GroupMessageBubble displaying image: \(mediaURL)")
                            AsyncImage(url: URL(string: mediaURL)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 250, height: 200)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 250)
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 250, height: 200)
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
                            // No cached image - show placeholder
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
                            .frame(width: 250, height: 200)
                            .background(Color(.systemGray6))
                        }
                        
                        // Caption text (if present) - below image in same container
                        if let text = message.text, !text.isEmpty {
                            Text(text)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: 250, alignment: .leading)
                                .foregroundStyle(isFromCurrentUser ? Color.sentMessageText : Color.receivedMessageText)
                        }
                    }
                    .background(isFromCurrentUser ? Color.sentMessageBackground : Color.receivedMessageBackground)
                    .cornerRadius(16)
                } else if let text = message.text {
                    // Text-only message (no image)
                    Text(text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isFromCurrentUser ? Color.sentMessageBackground : Color.receivedMessageBackground)
                        .foregroundStyle(isFromCurrentUser ? Color.sentMessageText : Color.receivedMessageText)
                        .cornerRadius(16)
                }
                
                // Timestamp and status
                HStack(spacing: 4) {
                    Text(message.timestamp.timeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if isFromCurrentUser {
                        statusIcon
                        
                        // Tap to retry indicator
                        if message.status == .failed {
                            Text("• Tap to retry")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            // Priority: retry failed messages first
            if message.status == .failed {
                onRetry?()
            } else if isFromCurrentUser && conversation.type == .group {
                // Show read receipts for your own messages in group chats
                showingReadReceipts = true
            }
        }
        .sheet(isPresented: $showingReadReceipts) {
            MessageReadReceiptsView(
                message: message,
                conversation: conversation,
                currentUserID: currentUserID
            )
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
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.secondary)
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
            HStack(spacing: 2) {
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
                
                // Show read count in groups
                if message.readBy.count > 1 {
                    Text("\(message.readBy.count)")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GroupMessageBubble(
            message: Message(
                id: "1",
                conversationID: "conv1",
                senderID: "user1",
                text: "Hey everyone!",
                mediaURL: nil,
                mediaType: nil,
                timestamp: Date(),
                status: .sent,
                readBy: ["user1"]
            ),
            senderName: "Alice",
            isFromCurrentUser: false,
            conversation: Conversation(
                id: "conv1",
                type: .group,
                participants: ["user1", "user2", "user3"],
                name: "Test Group",
                imageURL: nil,
                lastMessage: nil,
                createdAt: Date(),
                updatedAt: Date(),
                unreadCount: [:]
            ),
            currentUserID: "user1"
        )
    }
    .padding()
}

