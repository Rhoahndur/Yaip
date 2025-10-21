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
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name (for received messages in groups)
                if !isFromCurrentUser {
                    Text(senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 12)
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
            Image(systemName: "checkmark.checkmark")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .read:
            HStack(spacing: 2) {
                Image(systemName: "checkmark.checkmark")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .fontWeight(.semibold)
                
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
            isFromCurrentUser: false
        )
    }
    .padding()
}

