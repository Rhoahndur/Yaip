//
//  MessageListenerService.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// Listens for new messages across all conversations (acts like websocket push)
@MainActor
class MessageListenerService: ObservableObject {
    static let shared = MessageListenerService()
    
    private var conversationListeners: [String: ListenerRegistration] = [:]
    private let db = Firestore.firestore()
    private var currentUserID: String?
    
    private init() {}
    
    /// Start listening for new messages in all user's conversations
    func startListening(userID: String, conversations: [Conversation]) {
        self.currentUserID = userID
        
        // Stop any existing listeners
        stopAllListeners()
        
        print("🔊 Starting message listeners for \(conversations.count) conversations")
        
        // Set up listener for each conversation
        for conversation in conversations {
            guard let conversationID = conversation.id else { continue }
            startListeningToConversation(conversationID: conversationID)
        }
    }
    
    /// Start listening to a specific conversation
    private func startListeningToConversation(conversationID: String) {
        // Don't set up duplicate listeners
        guard conversationListeners[conversationID] == nil else { return }
        
        // Get the last message timestamp to only listen for NEW messages
        let now = Date()
        
        let listener = db.collection(Constants.Collections.conversations)
            .document(conversationID)
            .collection(Constants.Collections.messages)
            .whereField("timestamp", isGreaterThan: Timestamp(date: now))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to messages: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Process new messages
                for document in documents {
                    if let message = try? document.data(as: Message.self) {
                        Task { @MainActor in
                            await self.handleNewMessage(message, conversationID: conversationID)
                        }
                    }
                }
            }
        
        conversationListeners[conversationID] = listener
        print("✅ Listening to conversation: \(conversationID)")
    }
    
    /// Handle a new message (trigger notifications)
    private func handleNewMessage(_ message: Message, conversationID: String) async {
        guard let currentUserID = currentUserID else { return }
        
        // Don't notify for our own messages
        guard message.senderID != currentUserID else { return }
        
        print("📬 New message received in conversation: \(conversationID)")
        print("   From: \(message.senderID)")
        print("   Text: \(message.text)")
        
        // Get sender name
        let senderName = await getSenderName(senderID: message.senderID)
        
        // Get conversation details
        let conversationDetails = await getConversationDetails(conversationID: conversationID)
        
        // Check if we're currently viewing this conversation
        let isViewingConversation = NotificationCenter.default
            .publisher(for: .currentConversationChanged)
            .first()
            .map { notification in
                notification.userInfo?["conversationID"] as? String == conversationID
            }
        
        // If app is in foreground and we're NOT viewing this conversation, show in-app banner
        if !isViewingThisConversation(conversationID) {
            InAppBannerManager.shared.showMessageBanner(
                conversationID: conversationID,
                senderName: senderName,
                messageText: message.text
            )
        }
        
        // Always send local notification (iOS handles if user is in the app)
        await LocalNotificationManager.shared.sendMessageNotification(
            conversationID: conversationID,
            senderName: senderName,
            messageText: message.text,
            isGroup: conversationDetails.isGroup,
            groupName: conversationDetails.name
        )
    }
    
    /// Check if user is currently viewing a conversation
    private func isViewingThisConversation(_ conversationID: String) -> Bool {
        // This would be set by ChatView when it appears/disappears
        // For now, return false to always show banners
        return false
    }
    
    /// Get sender display name
    private func getSenderName(senderID: String) async -> String {
        do {
            let user = try await UserService.shared.fetchUser(id: senderID)
            return user.displayName
        } catch {
            print("❌ Error fetching sender name: \(error)")
            return "Someone"
        }
    }
    
    /// Get conversation details
    private func getConversationDetails(conversationID: String) async -> (isGroup: Bool, name: String?) {
        do {
            let snapshot = try await db.collection(Constants.Collections.conversations)
                .document(conversationID)
                .getDocument()
            
            let conversation = try snapshot.data(as: Conversation.self)
            return (conversation.type == .group, conversation.name)
        } catch {
            print("❌ Error fetching conversation: \(error)")
            return (false, nil)
        }
    }
    
    /// Add a new conversation to listen to
    func addConversation(conversationID: String) {
        startListeningToConversation(conversationID: conversationID)
    }
    
    /// Stop listening to all conversations
    func stopAllListeners() {
        for (conversationID, listener) in conversationListeners {
            listener.remove()
            print("🔇 Stopped listening to: \(conversationID)")
        }
        conversationListeners.removeAll()
    }
    
    /// Stop listening (called on logout)
    func stopListening() {
        stopAllListeners()
        currentUserID = nil
        print("🔇 Message listener service stopped")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let currentConversationChanged = Notification.Name("currentConversationChanged")
}

