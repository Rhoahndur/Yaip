//
//  MessageReadReceiptsView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import SwiftUI

/// Shows who has read a message (for group chats)
struct MessageReadReceiptsView: View {
    let message: Message
    let conversation: Conversation
    let currentUserID: String
    
    @State private var readByUsers: [(id: String, name: String, readAt: Date?)] = []
    @State private var unreadUsers: [(id: String, name: String)] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Read by section
                if !readByUsers.isEmpty {
                    Section("Read by") {
                        ForEach(readByUsers, id: \.id) { user in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text(user.name)
                                        .font(.body)
                                    
                                    if let readAt = user.readAt {
                                        Text("Read \(readAt.relativeTime)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Not read by section
                if !unreadUsers.isEmpty {
                    Section("Not read by") {
                        ForEach(unreadUsers, id: \.id) { user in
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                                
                                Text(user.name)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Loading state
                if isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Read Receipts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadReadReceipts()
            }
        }
    }
    
    private func loadReadReceipts() async {
        isLoading = true
        
        // Get all participants except sender
        let participants = conversation.participants.filter { $0 != message.senderID }
        
        var read: [(id: String, name: String, readAt: Date?)] = []
        var unread: [(id: String, name: String)] = []
        
        for participantID in participants {
            do {
                let user = try await UserService.shared.fetchUser(id: participantID)
                
                if message.readBy.contains(participantID) {
                    // User has read the message
                    // Try to get read timestamp (would need to add this to model)
                    read.append((id: participantID, name: user.displayName, readAt: nil))
                } else {
                    // User hasn't read the message
                    unread.append((id: participantID, name: user.displayName))
                }
            } catch {
                print("Error fetching user \(participantID): \(error)")
            }
        }
        
        readByUsers = read
        unreadUsers = unread
        isLoading = false
    }
}

#Preview {
    MessageReadReceiptsView(
        message: Message(
            id: "1",
            conversationID: "conv1",
            senderID: "user1",
            text: "Hello everyone!",
            mediaURL: nil,
            mediaType: nil,
            timestamp: Date(),
            status: .read,
            readBy: ["user2"]
        ),
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

