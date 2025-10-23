//
//  ChatViewModel.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// ViewModel for managing chat messages
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var selectedImage: UIImage?
    @Published var otherUserIsTyping = false
    @Published var isLoading = false
    @Published var isUploadingImage = false
    @Published var errorMessage: String?
    @Published var participantNames: [String: String] = [:] // userID -> displayName
    
    let conversation: Conversation
    private let messageService = MessageService.shared
    private let conversationService = ConversationService.shared
    private let authManager = AuthManager.shared
    private let localStorage = LocalStorageManager.shared
    private let storageService = StorageService.shared
    private let networkMonitor = NetworkMonitor.shared
    
    nonisolated(unsafe) private var messageListener: ListenerRegistration?
    nonisolated(unsafe) private var typingListener: ListenerRegistration?
    private var typingTimer: Timer?
    
    init(conversation: Conversation) {
        self.conversation = conversation
        setupMessageTextObserver()
        
        // Load participant names for group chats
        if conversation.type == .group {
            Task {
                await loadParticipantNames()
            }
        }
    }
    
    /// Get sender display name
    func getSenderName(for userID: String) -> String {
        return participantNames[userID] ?? "Unknown"
    }
    
    /// Load participant names from Firestore
    private func loadParticipantNames() async {
        do {
            let users = try await UserService.shared.fetchUsers(ids: conversation.participants)
            
            await MainActor.run {
                for user in users {
                    if let userID = user.id {
                        self.participantNames[userID] = user.displayName
                    }
                }
            }
        } catch {
            print("Error loading participant names: \(error)")
        }
    }
    
    /// Start listening to messages
    func startListening() {
        guard let conversationID = conversation.id else { return }
        
        isLoading = true
        
        // Load from local storage first
        Task {
            do {
                let localMessages = try localStorage.fetchMessages(conversationID: conversationID)
                self.messages = localMessages
            } catch {
                print("Error loading local messages: \(error)")
            }
        }
        
        // Listen to messages
        messageListener = messageService.listenToMessages(conversationID: conversationID) { [weak self] firestoreMessages in
            Task { @MainActor in
                guard let self = self else { return }
                
                let oldMessages = self.messages
                
                // Smart merge: Keep Firestore messages + pending local messages
                var mergedMessages: [Message] = []
                let firestoreIDs = Set(firestoreMessages.compactMap { $0.id })
                
                // Add all Firestore messages (source of truth for synced messages)
                mergedMessages.append(contentsOf: firestoreMessages)
                
                // Keep local pending/failed messages that haven't synced yet
                let pendingLocal = oldMessages.filter { localMsg in
                    guard let id = localMsg.id else { return false }
                    // Keep if not in Firestore and still pending/failed
                    return !firestoreIDs.contains(id) && 
                           (localMsg.status == .sending || localMsg.status == .failed)
                }
                mergedMessages.append(contentsOf: pendingLocal)
                
                // Sort by timestamp
                mergedMessages.sort { $0.timestamp < $1.timestamp }
                
                self.messages = mergedMessages
                self.isLoading = false
                
                // Save Firestore messages to local storage
                for message in firestoreMessages {
                    try? self.localStorage.saveMessage(message)
                    // Delete cached image once uploaded
                    if message.mediaURL != nil, let id = message.id {
                        self.localStorage.deleteImage(forMessageID: id)
                    }
                }
                
                // Auto-mark new unread messages as read (if we're viewing the chat)
                guard let userID = self.authManager.currentUserID else { return }
                
                let newMessages = firestoreMessages.filter { newMsg in
                    !oldMessages.contains(where: { $0.id == newMsg.id })
                }
                
                // Mark any new messages from others as read immediately
                let unreadFromOthers = newMessages.filter { msg in
                    msg.senderID != userID && !msg.readBy.contains(userID)
                }
                
                if !unreadFromOthers.isEmpty {
                    print("📖 Auto-marking \(unreadFromOthers.count) new messages as read")
                    self.markAsRead()
                }
            }
        }
        
        // Listen to typing indicator for other user
        if conversation.type == .oneOnOne,
           let currentUserID = authManager.currentUserID,
           let otherUserID = conversation.participants.first(where: { $0 != currentUserID }) {
            
            typingListener = messageService.listenToTypingStatus(
                conversationID: conversationID,
                otherUserID: otherUserID
            ) { [weak self] isTyping in
                Task { @MainActor in
                    self?.otherUserIsTyping = isTyping
                }
            }
        }
    }
    
    /// Stop listening to messages
    nonisolated func stopListening() {
        messageListener?.remove()
        typingListener?.remove()
        messageListener = nil
        typingListener = nil
    }
    
    /// Send a message
    func sendMessage() async {
        print("🚀 ==== sendMessage() START ====")
        print("   Current messages count: \(messages.count)")
        print("   messageText: '\(messageText)'")
        print("   selectedImage: \(selectedImage != nil ? "present" : "nil")")
        
        guard let currentUserID = authManager.currentUserID,
              let conversationID = conversation.id else {
            print("❌ EARLY RETURN: Missing currentUserID or conversationID")
            print("   currentUserID: \(String(describing: authManager.currentUserID))")
            print("   conversationID: \(String(describing: conversation.id))")
            return
        }
        print("✅ UserID and ConversationID validated")
        
        // Ensure we have either text or image
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = selectedImage
        
        print("📝 Text after trim: '\(text)' (length: \(text.count))")
        print("📝 Image: \(image != nil ? "present" : "nil")")
        
        guard !text.isEmpty || image != nil else {
            print("❌ EARLY RETURN: No text or image to send")
            return
        }
        print("✅ Message content validated")
        
        // Clear inputs immediately
        messageText = ""
        selectedImage = nil
        print("✅ Cleared input fields")
        print("   New messageText: '\(messageText)'")
        
        // Stop typing indicator (fire-and-forget - don't block on this)
        print("🔄 Stopping typing indicator (non-blocking)...")
        Task {
            await updateTypingStatus(false)
            print("✅ Typing indicator stopped")
        }
        print("✅ Typing task dispatched, continuing with message creation...")
        
        print("📦 Creating message object...")
        
        // Create message immediately (optimistic UI)
        let messageID = UUID().uuidString
        print("📦 Generated messageID: \(messageID)")
        var newMessage = Message(
            id: nil,
            conversationID: conversationID,
            senderID: currentUserID,
            text: text.isEmpty ? nil : text,
            mediaURL: nil, // Will be set after upload
            mediaType: image != nil ? .image : nil,
            timestamp: Date(),
            status: .sending,
            readBy: [currentUserID]
        )
        newMessage.id = messageID
        
        // Optimistic update - add to UI immediately (ALWAYS show, even if offline)
        messages.append(newMessage)
        print("✅ ===== MESSAGE ADDED TO UI ===== ")
        print("   Message ID: \(messageID)")
        print("   Message text: '\(newMessage.text ?? "nil")'")
        print("   Message status: \(newMessage.status)")
        print("   Total messages now: \(messages.count)")
        
        // Save locally first (so it persists across app restarts)
        try? localStorage.saveMessage(newMessage)
        
        // Save image locally if present (for retry later)
        if let image = image {
            localStorage.saveImage(image, forMessageID: messageID)
            print("✅ Saved message and image locally")
        } else {
            print("✅ Saved message locally")
        }
        
        // Upload image if present (only if online)
        var mediaURL: String?
        if let image = image {
            if networkMonitor.isConnected {
                print("🖼️ Uploading image (online)...")
                do {
                    mediaURL = try await storageService.uploadChatImage(image, conversationID: conversationID)
                    print("✅ Image uploaded: \(mediaURL ?? "nil")")
                    
                    // Update message with mediaURL
                    if let index = messages.firstIndex(where: { $0.id == messageID }) {
                        messages[index].mediaURL = mediaURL
                        newMessage.mediaURL = mediaURL
                        try? localStorage.saveMessage(messages[index])
                        print("✅ Updated message with mediaURL")
                    }
                } catch {
                    print("❌ Image upload failed: \(error.localizedDescription)")
                    // Mark as failed (will retry later)
                    if let index = messages.firstIndex(where: { $0.id == messageID }) {
                        messages[index].status = .failed
                        print("⚠️ Message marked as failed (image upload error)")
                    }
                    return // Don't try to send to Firestore without image URL
                }
            } else {
                print("📵 Offline - skipping image upload, will retry when online")
                // Leave message in .sending state with no mediaURL
                // The retry mechanism will pick it up when connection is restored
                return // Don't try to send to Firestore yet
            }
        }
        
        // Send to Firestore
        print("📤 Sending message to Firestore...")
        do {
            try await messageService.sendMessage(newMessage)
            print("✅ Message sent to Firestore")
            
            // Mark as synced
            try? localStorage.markMessageSynced(id: messageID)
            
            // Update message status to sent
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .sent
                print("✅ Updated message status to .sent in UI")
            }
            
            // Update conversation's last message
            let lastMessageText = text.isEmpty ? "📷 Photo" : text
            let lastMessage = LastMessage(
                text: lastMessageText,
                senderID: currentUserID,
                timestamp: Date()
            )
            try await conversationService.updateLastMessage(
                conversationID: conversationID,
                lastMessage: lastMessage
            )
            print("✅ Updated conversation lastMessage")
            
        } catch {
            print("❌ Error sending message to Firestore: \(error.localizedDescription)")
            // Update message status to failed (but keep it visible!)
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .failed
                print("⚠️ Updated message status to .failed (will retry when online)")
            }
            // Don't show error to user - message will auto-retry when connection restored
        }
    }
    
    /// Retry sending a failed or stuck message
    func retryMessage(_ message: Message) async {
        guard let messageID = message.id,
              let index = messages.firstIndex(where: { $0.id == messageID }) else {
            print("❌ Cannot retry message: message not found")
            return
        }
        
        // Only retry if failed or stuck (sending with no URL)
        let shouldRetry = message.status == .failed || 
                         (message.status == .sending && message.mediaType == .image && message.mediaURL == nil)
        
        guard shouldRetry else {
            print("❌ Cannot retry message: status=\(message.status), has URL: \(message.mediaURL != nil)")
            return
        }
        
        print("🔄 Retrying message: \(messageID) (status: \(message.status))")
        
        // Update status to sending
        messages[index].status = .sending
        
        var updatedMessage = message
        
        // If message has mediaType but no mediaURL, try to upload image again
        if updatedMessage.mediaType == .image && updatedMessage.mediaURL == nil {
            if let image = localStorage.loadImage(forMessageID: messageID) {
                print("🖼️ Found cached image, uploading...")
                do {
                    let mediaURL = try await storageService.uploadChatImage(image, conversationID: conversation.id!)
                    updatedMessage.mediaURL = mediaURL
                    messages[index].mediaURL = mediaURL
                    print("✅ Image uploaded on retry: \(mediaURL)")
                } catch {
                    print("❌ Image upload failed on retry: \(error.localizedDescription)")
                    messages[index].status = .failed
                    return
                }
            } else {
                print("⚠️ No cached image found for message")
            }
        }
        
        // Try to send to Firestore
        do {
            try await messageService.sendMessage(updatedMessage)
            print("✅ Message sent on retry")
            
            // Mark as synced
            try? localStorage.markMessageSynced(id: messageID)
            
            // Update status to sent
            messages[index].status = .sent
            
            // Update conversation's last message
            if let conversationID = conversation.id,
               let currentUserID = authManager.currentUserID {
                let lastMessageText = updatedMessage.text ?? "📷 Photo"
                let lastMessage = LastMessage(
                    text: lastMessageText,
                    senderID: currentUserID,
                    timestamp: updatedMessage.timestamp
                )
                try await conversationService.updateLastMessage(
                    conversationID: conversationID,
                    lastMessage: lastMessage
                )
            }
            
        } catch {
            print("❌ Retry failed: \(error.localizedDescription)")
            messages[index].status = .failed
        }
    }
    
    /// Retry all failed messages and stuck pending messages
    func retryAllFailedMessages() async {
        print("🔄 Retrying all failed/stuck messages...")
        
        // Find messages that need retry:
        // 1. Explicitly failed messages
        // 2. Stuck "sending" image messages (mediaType=.image but no mediaURL - these got stuck uploading offline)
        let messagesToRetry = messages.filter { message in
            if message.status == .failed {
                return true
            }
            // Check for stuck image uploads
            if message.status == .sending && message.mediaType == .image && message.mediaURL == nil {
                print("⚠️ Found stuck image upload: \(message.id ?? "unknown")")
                return true
            }
            return false
        }
        
        print("📝 Found \(messagesToRetry.count) messages to retry")
        
        for message in messagesToRetry {
            await retryMessage(message)
        }
    }
    
    /// Mark all messages as read
    func markAsRead() {
        guard let currentUserID = authManager.currentUserID,
              let conversationID = conversation.id else {
            return
        }
        
        Task {
            let unreadMessageIDs = messages
                .filter { !$0.readBy.contains(currentUserID) }
                .compactMap { $0.id }
            
            guard !unreadMessageIDs.isEmpty else { return }
            
            do {
                try await messageService.markMessagesAsRead(
                    conversationID: conversationID,
                    messageIDs: unreadMessageIDs,
                    userID: currentUserID
                )
            } catch {
                print("Error marking messages as read: \(error.localizedDescription)")
            }
        }
    }
    
    /// Update typing status
    private func updateTypingStatus(_ isTyping: Bool) async {
        guard let currentUserID = authManager.currentUserID,
              let conversationID = conversation.id else {
            return
        }
        
        do {
            try await messageService.updateTypingStatus(
                conversationID: conversationID,
                userID: currentUserID,
                isTyping: isTyping
            )
        } catch {
            print("Error updating typing status: \(error.localizedDescription)")
        }
    }
    
    /// Setup observer for message text to update typing indicator
    private func setupMessageTextObserver() {
        $messageText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                Task {
                    await self?.handleTypingChange(text: text)
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func handleTypingChange(text: String) async {
        let isTyping = !text.isEmpty
        await updateTypingStatus(isTyping)
        
        // Auto-stop typing after 3 seconds of no changes
        typingTimer?.invalidate()
        if isTyping {
            typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                Task {
                    await self?.updateTypingStatus(false)
                }
            }
        }
    }
    
    deinit {
        stopListening()
        typingTimer?.invalidate()
    }
}

