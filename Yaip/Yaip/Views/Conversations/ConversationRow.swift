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
    @State private var showUserProfile = false
    @State private var otherUser: User?
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    // Check if this conversation has unread messages
    private var hasUnreadMessages: Bool {
        guard let currentUserID = currentUserID else { return false }
        return (conversation.unreadCount[currentUserID] ?? 0) > 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar with online status badge (tappable for 1-on-1)
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
            .onTapGesture {
                // Only show profile for 1-on-1 chats
                if conversation.type == .oneOnOne, let user = otherUser {
                    showUserProfile = true
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName.truncated(to: 25))
                        .font(.system(size: 17, weight: hasUnreadMessages ? .bold : .semibold))
                        .foregroundStyle(hasUnreadMessages ? .primary : .primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.timestamp.timeString)
                            .font(.system(size: 15, weight: hasUnreadMessages ? .semibold : .regular))
                            .foregroundStyle(hasUnreadMessages ? Color.blue : .secondary)
                    }
                }
                
                HStack(spacing: 8) {
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.text)
                            .font(.system(size: 15, weight: hasUnreadMessages ? .medium : .regular))
                            .foregroundStyle(hasUnreadMessages ? .primary : .secondary)
                            .lineLimit(2)
                    } else {
                        Text("No messages yet")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                            .italic()
                    }
                    
                    Spacer()
                    
                    // Unread badge - show count or blue dot
                    if let currentUserID = currentUserID,
                       let unreadCount = conversation.unreadCount[currentUserID],
                       unreadCount > 0 {
                        if unreadCount > 1 {
                            // Show count for multiple unread
                            Text("\(unreadCount)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .clipShape(Capsule())
                                .frame(minWidth: 24)
                        } else {
                            // Show blue dot for single unread
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                        }
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
        .sheet(isPresented: $showUserProfile) {
            if let user = otherUser {
                UserProfileModal(user: user)
            }
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
                otherUser = user // Store full user object for profile modal

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


