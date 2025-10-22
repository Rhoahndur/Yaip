//
//  GroupMessageBubble.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

struct GroupMessageBubble: View {
    let message: Message
    let senderName: String
    let isFromCurrentUser: Bool
    let conversation: Conversation
    let currentUserID: String
    
    @State private var showingReadReceipts = false
    
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
                
                // Image if present
                if let mediaURL = message.mediaURL, message.mediaType == .image {
                    let _ = print("🖼️ GroupMessageBubble displaying image: \(mediaURL)")
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
                }
                
                // Message text
                if let text = message.text {
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
                    }
                }
            }
            
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .onTapGesture {
            // Only show read receipts for your own messages in group chats
            if isFromCurrentUser && conversation.type == .group {
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

