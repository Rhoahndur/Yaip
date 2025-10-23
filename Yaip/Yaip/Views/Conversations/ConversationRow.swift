//
//  ConversationRow.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI
import FirebaseFirestore

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserID: String?
    @State private var otherUserStatus: UserStatus = .offline
    @State private var displayName: String = "Loading..."
    @State private var statusListener: ListenerRegistration?
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar with online status badge
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                
                if let imageURL = conversation.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: conversation.type == .group ? "person.3.fill" : "person.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title2)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                } else {
                    Image(systemName: conversation.type == .group ? "person.3.fill" : "person.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title2)
                }
                
                // Online status badge (only for 1-on-1 chats and when we're online)
                if conversation.type == .oneOnOne && networkMonitor.isConnected {
                    OnlineStatusBadge(status: otherUserStatus, size: 16)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .offset(x: 3, y: 3)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.timestamp.timeString)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 8) {
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.text)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("No messages yet")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                            .italic()
                    }
                    
                    Spacer()
                    
                    // Unread badge
                    if let currentUserID = currentUserID,
                       let unreadCount = conversation.unreadCount[currentUserID],
                       unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .frame(minWidth: 24)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .task {
            await loadConversationDetails()
        }
        .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
            // Reload status when reconnecting
            if !oldValue && newValue && conversation.type == .oneOnOne {
                Task {
                    await loadConversationDetails()
                }
            }
        }
        .onDisappear {
            // Clean up listener when view disappears
            statusListener?.remove()
            statusListener = nil
        }
    }
    
    private func loadConversationDetails() async {
        if conversation.type == .oneOnOne {
            // For 1-on-1, get other user's info
            guard let currentUserID = currentUserID else {
                print("⚠️ No current user ID")
                displayName = "Unknown"
                return
            }
            
            guard let otherUserID = conversation.participants.first(where: { $0 != currentUserID }) else {
                print("⚠️ ConversationRow: Could not find other user in conversation \(conversation.id ?? "no-id")")
                displayName = "Unknown"
                return
            }
            
            do {
                let user = try await UserService.shared.fetchUser(id: otherUserID)
                displayName = user.displayName
                otherUserStatus = user.status
                
                // 🔥 Set up real-time status listener
                setupStatusListener(for: otherUserID)
            } catch {
                // User document doesn't exist in Firestore - likely deleted or data inconsistency
                print("⚠️ User document not found: \(otherUserID)")
                print("   This conversation may have stale data. Consider deleting it.")
                displayName = "Deleted User"
            }
        } else {
            // For group chats, use stored name
            displayName = conversation.name ?? "Group Chat"
        }
    }
    
    private func setupStatusListener(for userID: String) {
        // Remove any existing listener
        statusListener?.remove()
        
        // Set up real-time listener for user status
        statusListener = PresenceService.shared.listenToPresence(userID: userID) { status, lastSeen in
            DispatchQueue.main.async {
                self.otherUserStatus = status
            }
        }
        
        print("🔔 Real-time status listener started for user: \(userID)")
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


