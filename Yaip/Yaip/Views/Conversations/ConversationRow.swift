//
//  ConversationRow.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserID: String?
    @State private var otherUserStatus: UserStatus = .offline
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with online status badge
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                if let imageURL = conversation.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: conversation.type == .group ? "person.3.fill" : "person.circle.fill")
                            .foregroundStyle(.gray)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Image(systemName: conversation.type == .group ? "person.3.fill" : "person.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }
                
                // Online status badge (only for 1-on-1 chats)
                if conversation.type == .oneOnOne {
                    OnlineStatusBadge(status: otherUserStatus, size: 14)
                        .offset(x: 2, y: 2)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.name ?? "Unknown")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.timestamp.relativeTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text("No messages yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            
            // Unread badge
            if let currentUserID = currentUserID,
               let unreadCount = conversation.unreadCount[currentUserID],
               unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .frame(minWidth: 24, minHeight: 24)
            }
        }
        .padding(.vertical, 4)
        .task {
            await loadOtherUserStatus()
        }
    }
    
    private func loadOtherUserStatus() async {
        // Only for 1-on-1 conversations
        guard conversation.type == .oneOnOne,
              let currentUserID = currentUserID,
              let otherUserID = conversation.participants.first(where: { $0 != currentUserID }) else {
            return
        }
        
        // Fetch user status
        do {
            let user = try await UserService.shared.fetchUser(id: otherUserID)
            otherUserStatus = user.status
        } catch {
            print("Error loading user status: \(error)")
        }
    }
}

#Preview {
    List {
        ConversationRow(
            conversation: Conversation(
                id: "1",
                type: .oneOnOne,
                participants: ["user1", "user2"],
                name: "John Doe",
                imageURL: nil,
                lastMessage: LastMessage(
                    text: "Hey, how are you doing today?",
                    senderID: "user2",
                    timestamp: Date().addingTimeInterval(-3600)
                ),
                createdAt: Date(),
                updatedAt: Date(),
                unreadCount: ["user1": 3]
            ),
            currentUserID: "user1"
        )
        
        ConversationRow(
            conversation: Conversation(
                id: "2",
                type: .group,
                participants: ["user1", "user2", "user3"],
                name: "Team Chat",
                imageURL: nil,
                lastMessage: nil,
                createdAt: Date(),
                updatedAt: Date(),
                unreadCount: [:]
            ),
            currentUserID: "user1"
        )
    }
}

