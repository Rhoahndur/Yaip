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
    @Published var conversation: Conversation  // Changed from 'let' to '@Published var' to allow updates

    private let messageService = MessageService.shared
    private let conversationService = ConversationService.shared
    private let authManager = AuthManager.shared
    private let localStorage = LocalStorageManager.shared
    private let imageUploadManager = ImageUploadManager.shared
    private let networkMonitor = NetworkMonitor.shared

    nonisolated(unsafe) private var messageListener: ListenerRegistration?
    nonisolated(unsafe) private var typingListener: ListenerRegistration?
    nonisolated(unsafe) private var conversationListener: ListenerRegistration?  // Listener for conversation updates
    private var typingTimer: Timer?
    
    init(conversation: Conversation) {
        self.conversation = conversation
        setupMessageTextObserver()
        setupNetworkReconnectListener()
        
        // Load participant names for group chats
        if conversation.type == .group {
            Task {
                await loadParticipantNames()
            }
        }
    }
    
    /// Setup listener for network reconnection
    private func setupNetworkReconnectListener() {
        NotificationCenter.default.publisher(for: .networkDidReconnect)
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("🔄 Network reconnected - retrying pending messages and indexing queue")
                Task { @MainActor in
                    // Retry failed message sends
                    await self.retryAllFailedMessages()

                    // Process offline indexing queue
                    await MessageIndexingService.shared.processOfflineQueue()

                    // Optionally backfill any missed messages in current conversation
                    if let conversationID = self.conversation.id {
                        await MessageIndexingService.shared.backfillConversation(
                            conversationID: conversationID,
                            limit: 50  // Only backfill last 50 messages on reconnect
                        )
                    }
                }
            }
            .store(in: &cancellables)
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

        // Listen to conversation updates (name, participants, etc.)
        setupConversationListener()

        // Listen to messages
        messageListener = messageService.listenToMessages(conversationID: conversationID) { [weak self] firestoreMessages in
            Task { @MainActor in
                guard let self = self else { return }
                
                let oldMessages = self.messages
                
                // LIFECYCLE-AWARE MERGE: Respect local vs network state ownership
                var mergedMessages: [Message] = []
                let firestoreIDs = Set(firestoreMessages.compactMap { $0.id })
                
                // Create lookup dictionary for local messages
                var localByID: [String: Message] = [:]
                for msg in oldMessages {
                    if let id = msg.id {
                        localByID[id] = msg
                    }
                }
                
                // Add Firestore messages (but respect local states)
                for firestoreMsg in firestoreMessages {
                    guard let id = firestoreMsg.id else { continue }
                    
                    // If we have a local version, check if we should keep it instead
                    if let localMsg = localByID[id] {
                        // Keep local version if it's in a local state (.staged, .sending, .failed)
                        // These states are "owned" by the local device
                        if localMsg.status.isLocal {
                            mergedMessages.append(localMsg)
                            continue
                        }
                        // For synced states, use Firestore version (it's the source of truth)
                        // This ensures read receipts and status updates propagate
                        mergedMessages.append(firestoreMsg)
                        continue
                    }
                    
                    // Use Firestore version
                    mergedMessages.append(firestoreMsg)
                }
                
                // Keep local messages that aren't in Firestore yet
                let localOnlyMessages = oldMessages.filter { localMsg in
                    guard let id = localMsg.id else { return false }
                    return !firestoreIDs.contains(id) && localMsg.status.isLocal
                }
                mergedMessages.append(contentsOf: localOnlyMessages)
                
                // Sort by timestamp
                mergedMessages.sort { $0.timestamp < $1.timestamp }
                
                self.messages = mergedMessages
                self.isLoading = false
                
                // Auto-retry pending messages if we're online (FASTER - no delay)
                let pendingCount = mergedMessages.filter { $0.status.isLocal }.count
                if pendingCount > 0 && self.networkMonitor.isConnected {
                    print("🔄 Auto-retrying \(pendingCount) pending messages...")
                    Task {
                        await self.retryAllFailedMessages()
                    }
                }
                
                // If we received messages but NetworkMonitor thinks we're offline, force a check
                if !firestoreMessages.isEmpty && !self.networkMonitor.isConnected {
                    print("⚠️ Received messages but NetworkMonitor thinks offline - forcing check")
                    self.networkMonitor.checkConnectionNow()
                }
                
                // Save Firestore messages to local storage
                for message in firestoreMessages {
                    // Log image messages
                    if message.mediaType == .image {
                        print("📥 Received image message from Firestore:")
                        // print("   ID: \(message.id ?? "unknown")")
                        // print("   MediaURL: \(message.mediaURL ?? "none")")
                        // print("   Status: \(message.status)")
                    }
                    
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
                    // Small delay to ensure UI has updated
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                        await MainActor.run {
                            self.markAsRead()
                        }
                    }
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

    /// Setup listener for conversation updates (name, participants, etc.)
    private func setupConversationListener() {
        guard let conversationID = conversation.id else { return }

        conversationListener = Firestore.firestore()
            .collection(Constants.Collections.conversations)
            .document(conversationID)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                Task { @MainActor in
                    guard let self = self else { return }

                    if let error = error {
                        print("❌ Error listening to conversation updates: \(error)")
                        return
                    }

                    guard let document = documentSnapshot,
                          document.exists,
                          let data = document.data() else {
                        print("⚠️ Conversation document doesn't exist")
                        return
                    }

                    // Parse updated conversation fields
                    let name = data["name"] as? String
                    let participants = data["participants"] as? [String] ?? self.conversation.participants
                    let imageURL = data["imageURL"] as? String
                    let type = (data["type"] as? String).flatMap { ConversationType(rawValue: $0) } ?? self.conversation.type

                    // Update the conversation object
                    self.conversation = Conversation(
                        id: conversationID,
                        type: type,
                        participants: participants,
                        name: name,
                        imageURL: imageURL,
                        lastMessage: self.conversation.lastMessage, // Keep existing lastMessage
                        createdAt: self.conversation.createdAt, // Keep existing createdAt
                        updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        unreadCount: self.conversation.unreadCount // Keep existing unreadCount
                    )

                    print("✅ Conversation updated: name=\(name ?? "nil"), participants=\(participants.count)")

                    // Reload participant names if this is a group chat
                    if type == .group {
                        await self.loadParticipantNames()
                    }
                }
            }
    }

    /// Stop listening to messages
    nonisolated func stopListening() {
        messageListener?.remove()
        typingListener?.remove()
        conversationListener?.remove()
        messageListener = nil
        typingListener = nil
        conversationListener = nil
    }
    
    /// Send a message (with proper lifecycle stages)
    func sendMessage() async {
        guard let currentUserID = authManager.currentUserID,
              let conversationID = conversation.id else {
            return
        }
        
        // Validate content
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = selectedImage
        
        guard !text.isEmpty || image != nil else {
            return
        }
        
        // Clear inputs immediately
        messageText = ""
        selectedImage = nil
        
        // Stop typing indicator (non-blocking)
        Task {
            await updateTypingStatus(false)
        }
        
        // STAGE 1: Create message in .staged state
        let messageID = UUID().uuidString
        var newMessage = Message(
            id: nil,
            conversationID: conversationID,
            senderID: currentUserID,
            text: text.isEmpty ? nil : text,
            mediaURL: nil,
            mediaType: image != nil ? .image : nil,
            timestamp: Date(),
            status: .staged,  // Start as staged (local only)
            readBy: [currentUserID]
        )
        newMessage.id = messageID
        
        // Add to UI immediately (optimistic)
        messages.append(newMessage)
        
        // Save locally
        try? localStorage.saveMessage(newMessage)
        
        // STAGE 2: Handle image upload (if present)
        var mediaURL: String?
        if let image = image {
            // Cache image first
            imageUploadManager.cacheImage(image, for: messageID)
            print("💾 Image cached for message: \(messageID)")
            
            // Try to upload (optimistic approach)
            // print("📡 Attempting image upload...")
            
            // Update to .sending state
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .sending
            }
            
            mediaURL = await imageUploadManager.uploadImage(for: messageID, conversationID: conversationID)
            
            if let url = mediaURL {
                // Update message with URL
                if let index = messages.firstIndex(where: { $0.id == messageID }) {
                    messages[index].mediaURL = url
                    newMessage.mediaURL = url
                    try? localStorage.saveMessage(messages[index])
                    print("✅ Image URL assigned to message: \(url)")
                }
            } else {
                // Upload failed - stay in .staged state, will retry on reconnect
                print("⚠️ Image upload failed - staying in .staged state for retry")
                if let index = messages.firstIndex(where: { $0.id == messageID }) {
                    messages[index].status = .staged
                }
                // Don't return - still try to send text-only message if present
                if text.isEmpty {
                    return  // Image-only message, wait for retry
                }
                // Has text, continue to send text without image
                // print("   Message has text, sending text without image")
            }
        }
        
        // STAGE 3: Send to Firestore
        // OPTIMISTIC APPROACH: Try to send regardless of network status
        // Let Firebase SDK handle offline behavior (it has better detection)
        // If truly offline, Firebase will queue it automatically
        if !networkMonitor.isConnected {
            // print("⚠️ NetworkMonitor thinks we're offline, but trying anyway...")
            // print("   Firebase SDK will handle offline queueing if truly offline")
        }
        
        // Update to .sending state (if not already)
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            if messages[index].status != .sending {
                messages[index].status = .sending
            }
        }
        
        do {
            // print("📤 Sending message to Firestore:")
            // print("   ID: \(messageID)")
            // print("   MediaURL: \(newMessage.mediaURL ?? "none")")
            // print("   MediaType: \(String(describing: newMessage.mediaType))")
            
            try await messageService.sendMessage(newMessage)
            
            // STAGE 4: Mark as sent (will be confirmed by listener → .delivered/.read)
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .sent
                try? localStorage.markMessageSynced(id: messageID)
            }

            // STAGE 5: Index message into vector database (fire-and-forget)
            Task {
                await MessageIndexingService.shared.indexMessage(
                    messageID: messageID,
                    conversationID: conversationID
                )
            }

            // If message sent successfully but NetworkMonitor thinks we're offline, force a check
            if !networkMonitor.isConnected {
                print("⚠️ Message sent successfully but NetworkMonitor thinks offline - forcing check")
                networkMonitor.checkConnectionNow()
            }
            
            // Update conversation last message
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
            
        } catch {
            // Failed - mark for retry
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .failed
            }
        }
    }
    
    /// Retry sending a failed or stuck message (with lifecycle awareness)
    func retryMessage(_ message: Message) async {
        guard let messageID = message.id,
              let index = messages.firstIndex(where: { $0.id == messageID }),
              let conversationID = conversation.id,
              let currentUserID = authManager.currentUserID else {
            return
        }
        
        // Only retry if in retryable state
        guard message.status.isRetryable || message.status == .staged ||
              (message.status == .sending && message.mediaType == .image && message.mediaURL == nil) else {
            return
        }
        
        // Update status to sending
        messages[index].status = .sending
        var updatedMessage = messages[index]
        
        // Handle image upload via ImageUploadManager
        if updatedMessage.mediaType == .image && updatedMessage.mediaURL == nil {
            // print("📤 Retrying image upload for message: \(messageID)")
            
            // Check current image state
            let imageState = imageUploadManager.getState(for: messageID)
            // print("   Image state: \(imageState)")
            
            var mediaURL: String?
            
            // If cached (offline upload), call uploadImage directly
            // If failed, call retryUpload
            switch imageState {
            case .cached, .notStarted:
                // Try to load from disk if not in memory
                if let cachedImage = imageUploadManager.getCachedImage(for: messageID) {
                    // print("   Found cached image, uploading...")
                    imageUploadManager.cacheImage(cachedImage, for: messageID)
                    mediaURL = await imageUploadManager.uploadImage(for: messageID, conversationID: conversationID)
                } else {
                    // print("   ❌ No cached image found")
                }
            case .failed:
                // print("   Retrying failed upload...")
                mediaURL = await imageUploadManager.retryUpload(for: messageID, conversationID: conversationID)
            default:
                // print("   Image state not retryable: \(imageState)")
                break
            }
            
            if let url = mediaURL {
                // Upload succeeded
                // print("   ✅ Image uploaded: \(url)")
                updatedMessage.mediaURL = url
                // Re-find index after async operation
                if let currentIndex = messages.firstIndex(where: { $0.id == messageID }) {
                    messages[currentIndex].mediaURL = mediaURL
                }
            } else {
                // Upload failed
                // print("   ❌ Image upload failed")
                // Re-find index after async operation
                if let currentIndex = messages.firstIndex(where: { $0.id == messageID }) {
                    messages[currentIndex].status = .failed
                }
                return
            }
        }
        
        // Send to Firestore
        do {
            try await messageService.sendMessage(updatedMessage)

            // Mark as sent (will be confirmed by listener)
            // Re-find index after async operation
            if let currentIndex = messages.firstIndex(where: { $0.id == messageID }) {
                messages[currentIndex].status = .sent
            }
            try? localStorage.markMessageSynced(id: messageID)

            // Update conversation last message
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

        } catch {
            // Re-find index after async operation
            if let currentIndex = messages.firstIndex(where: { $0.id == messageID }) {
                messages[currentIndex].status = .failed
            }
        }
    }
    
    /// Retry all failed and pending messages
    /// Strategy: Auto-retry once on reconnect, then require manual retry (tap button)
    func retryAllFailedMessages() async {
        // print("🔄 retryAllFailedMessages() called")
        // print("   Network connected: \(networkMonitor.isConnected)")
        // print("   Total messages: \(messages.count)")
        
        guard networkMonitor.isConnected else { 
            // print("   ❌ Skipping retry - offline")
            return 
        }
        
        // Find messages that need retry (using new lifecycle states)
        let messagesToRetry = messages.filter { message in
            // Staged messages (created offline, never sent)
            if message.status == .staged {
                // print("   📋 Found staged message: \(message.id ?? "unknown")")
                return true
            }
            
            // Failed messages (only auto-retry if first attempt)
            if message.status.isRetryable {
                // Check ImageUploadManager for retry count
                if let messageID = message.id,
                   case .failed(_, let retryCount) = imageUploadManager.getState(for: messageID) {
                    // print("   ❌ Found failed message (retry \(retryCount)): \(messageID)")
                    return retryCount < 2  // Auto-retry once
                }
                // print("   ❌ Found retryable message: \(message.id ?? "unknown")")
                return true  // No image state, always retry
            }
            
            // Stuck image uploads (sending but no URL)
            if message.status == .sending && message.mediaType == .image && message.mediaURL == nil {
                // print("   ⏸️ Found stuck image upload: \(message.id ?? "unknown")")
                return true
            }
            
            return false
        }
        
        // print("   📊 Found \(messagesToRetry.count) messages to retry")
        
        // Retry each message
        for message in messagesToRetry {
            // print("   🔁 Retrying message: \(message.id ?? "unknown")")
            await retryMessage(message)
        }
        
        // print("   ✅ Retry complete")
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
            
            guard !unreadMessageIDs.isEmpty else { 
                print("📖 No unread messages to mark")
                return 
            }
            
            // print("📖 Marking \(unreadMessageIDs.count) messages as read: \(unreadMessageIDs)")
            
            do {
                try await messageService.markMessagesAsRead(
                    conversationID: conversationID,
                    messageIDs: unreadMessageIDs,
                    userID: currentUserID
                )
                
                // Immediately update local state to reflect read status
                await MainActor.run {
                    for id in unreadMessageIDs {
                        if let index = self.messages.firstIndex(where: { $0.id == id }) {
                            // Add current user to readBy if not already there
                            if !self.messages[index].readBy.contains(currentUserID) {
                                self.messages[index].readBy.append(currentUserID)
                            }
                            // Update status to .read if it's in a synced state
                            if self.messages[index].status.isSynced {
                                self.messages[index].status = .read
                            }
                        }
                    }
                }
                
                print("✅ Successfully marked messages as read")
            } catch {
                print("❌ Error marking messages as read: \(error.localizedDescription)")
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

    // MARK: - Message Polish Features

    /// Toggle a reaction on a message
    func toggleReaction(emoji: String, message: Message) async {
        guard let messageID = message.id,
              let conversationID = conversation.id,
              let currentUserID = authManager.currentUserID else {
            print("❌ Missing required IDs for reaction")
            return
        }

        // Optimistic UI update
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            var updatedMessage = messages[index]

            // Toggle reaction locally
            if var users = updatedMessage.reactions[emoji] {
                if users.contains(currentUserID) {
                    users.removeAll { $0 == currentUserID }
                    if users.isEmpty {
                        updatedMessage.reactions.removeValue(forKey: emoji)
                    } else {
                        updatedMessage.reactions[emoji] = users
                    }
                } else {
                    users.append(currentUserID)
                    updatedMessage.reactions[emoji] = users
                }
            } else {
                updatedMessage.reactions[emoji] = [currentUserID]
            }

            messages[index] = updatedMessage
        }

        // Sync to Firestore
        do {
            try await messageService.toggleReaction(
                emoji: emoji,
                messageID: messageID,
                conversationID: conversationID,
                userID: currentUserID
            )
            // print("✅ Toggled reaction: \(emoji)")
        } catch {
            print("❌ Failed to toggle reaction: \(error)")
            errorMessage = "Failed to add reaction"
        }
    }

    /// Delete a message
    func deleteMessage(_ message: Message) async {
        guard let messageID = message.id,
              let conversationID = conversation.id else {
            return
        }

        // Optimistic UI update
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            messages[index].isDeleted = true
            messages[index].deletedAt = Date()
            messages[index].text = "[Message deleted]"
        }

        // Sync to Firestore
        do {
            try await messageService.deleteMessage(
                messageID: messageID,
                conversationID: conversationID
            )
            // print("✅ Deleted message")
        } catch {
            print("❌ Failed to delete message: \(error)")
            errorMessage = "Failed to delete message"

            // Revert optimistic update
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].isDeleted = false
                messages[index].deletedAt = nil
            }
        }
    }

    /// Set the message to reply to
    @Published var replyingTo: Message?

    func setReplyTo(_ message: Message) {
        replyingTo = message
    }

    func clearReply() {
        replyingTo = nil
    }

    /// Get the message that another message is replying to
    func getReplyToMessage(for message: Message) -> Message? {
        guard let replyToID = message.replyTo else { return nil }
        return messages.first { $0.id == replyToID }
    }

    deinit {
        stopListening()
        typingTimer?.invalidate()
    }
}


