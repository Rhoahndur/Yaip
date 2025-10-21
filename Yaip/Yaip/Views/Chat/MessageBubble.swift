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
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Image if present
                if let mediaURL = message.mediaURL, message.mediaType == .image {
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
                                .cornerRadius(12)
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
                        HStack(spacing: 2) {
                            statusIcon
                            if message.status == .read && message.readBy.count > 1 {
                                Text("Read")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
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
            HStack(spacing: 2) {
                Image(systemName: "checkmark.checkmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .read:
            HStack(spacing: 2) {
                Image(systemName: "checkmark.checkmark")
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

