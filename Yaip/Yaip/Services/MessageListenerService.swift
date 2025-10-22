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
    private var processedMessageIDs = Set<String>() // Deduplicate notifications
    private var currentlyViewingConversationID: String? // Track which chat is open
    
    private init() {}
    
    /// Start listening for new messages in all user's conversations
    func startListening(userID: String, conversations: [Conversation]) {
        self.currentUserID = userID
        
        // Stop any existing listeners
        stopAllListeners()
        
        // Clear processed messages when restarting
        processedMessageIDs.removeAll()
        
        print("🔊 Starting message listeners for \(conversations.count) conversations")
        print("   Current user: \(userID)")
        
        // Set up listener for each conversation
        for conversation in conversations {
            guard let conversationID = conversation.id else { continue }
            startListeningToConversation(conversationID: conversationID)
        }
    }
    
    /// Start listening to a specific conversation
    private func startListeningToConversation(conversationID: String) {
        // Don't set up duplicate listeners
        guard conversationListeners[conversationID] == nil else { 
            print("⏭️ Already listening to: \(conversationID)")
            return
        }
        
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
                
                guard let snapshot = snapshot else { return }
                
                // Only process document ADDITIONS (not modifications or deletions)
                let newDocuments = snapshot.documentChanges.filter { $0.type == .added }
                
                print("📨 Snapshot received: \(newDocuments.count) new messages in \(conversationID)")
                
                // Process new messages
                for change in newDocuments {
                    if let message = try? change.document.data(as: Message.self) {
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
        guard let currentUserID = currentUserID,
              let messageID = message.id else {
            print("⚠️ No current user ID or message ID, skipping notification")
            return
        }
        
        // Deduplicate: Skip if we've already processed this message
        guard !processedMessageIDs.contains(messageID) else {
            print("⏭️ Already processed message: \(messageID)")
            return
        }
        processedMessageIDs.insert(messageID)
        
        // Don't notify for our own messages
        guard message.senderID != currentUserID else {
            print("⏭️ Skipping notification for own message")
            print("   Sender: \(message.senderID)")
            print("   Current User: \(currentUserID)")
            print("   Message ID: \(messageID)")
            return
        }
        
        print("📬 New message - triggering notification!")
        print("   Message ID: \(messageID)")
        print("   Conversation: \(conversationID)")
        print("   From: \(message.senderID)")
        print("   To User: \(currentUserID)")
        print("   Text: \(message.text ?? "nil")")
        
        // Get sender name
        let senderName = await getSenderName(senderID: message.senderID)
        
        // Get conversation details
        let conversationDetails = await getConversationDetails(conversationID: conversationID)
        
        // Determine message text (handle image-only messages)
        let messageText = message.text ?? (message.mediaURL != nil ? "📷 Sent a photo" : "")
        
        // Check if user is actively viewing this conversation
        let isViewingConversation = isViewingThisConversation(conversationID)
        
        // Calculate total unread messages for badge
        let totalUnreadCount = await getTotalUnreadCount(for: currentUserID)
        
        // If viewing this conversation, don't show ANY notifications
        if isViewingConversation {
            print("🙈 Suppressing all notifications - user is in this chat")
            return
        }
        
        // If app is in foreground and we're NOT viewing this conversation, show in-app banner
        InAppBannerManager.shared.showMessageBanner(
            conversationID: conversationID,
            senderName: senderName,
            messageText: messageText
        )
        
        // Send local notification (iOS handles if user is in the app)
        await LocalNotificationManager.shared.sendMessageNotification(
            conversationID: conversationID,
            messageID: messageID, // Pass message ID for deep linking
            senderName: senderName,
            messageText: messageText,
            isGroup: conversationDetails.isGroup,
            groupName: conversationDetails.name,
            totalUnreadCount: totalUnreadCount
        )
    }
    
    /// Calculate total unread messages across all conversations
    private func getTotalUnreadCount(for userID: String) async -> Int {
        do {
            let snapshot = try await db.collection(Constants.Collections.conversations)
                .whereField("participants", arrayContains: userID)
                .getDocuments()
            
            var totalUnread = 0
            for document in snapshot.documents {
                if let conversation = try? document.data(as: Conversation.self),
                   let unreadCount = conversation.unreadCount[userID] {
                    totalUnread += unreadCount
                }
            }
            
            print("🔢 Total unread messages for \(userID): \(totalUnread)")
            return totalUnread
        } catch {
            print("❌ Error calculating unread count: \(error)")
            return 1 // Fallback to 1
        }
    }
    
    /// Set which conversation is currently being viewed
    func setCurrentlyViewing(conversationID: String?) {
        currentlyViewingConversationID = conversationID
        if let id = conversationID {
            print("👁️  Now viewing conversation: \(id)")
        } else {
            print("👁️  No longer viewing any conversation")
        }
    }
    
    /// Check if user is currently viewing a conversation
    private func isViewingThisConversation(_ conversationID: String) -> Bool {
        let isViewing = currentlyViewingConversationID == conversationID
        if isViewing {
            print("🙈 User is viewing this conversation - suppressing notification")
        }
        return isViewing
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
        processedMessageIDs.removeAll()
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

