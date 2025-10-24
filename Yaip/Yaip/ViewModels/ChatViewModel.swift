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
    private let imageUploadManager = ImageUploadManager.shared
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
                
                // Auto-retry pending messages if we're online
                let pendingCount = mergedMessages.filter { $0.status.isLocal }.count
                if pendingCount > 0 && self.networkMonitor.isConnected {
                    Task {
                        // Small delay to let UI settle
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        await self.retryAllFailedMessages()
                    }
                }
                
                // Save Firestore messages to local storage
                for message in firestoreMessages {
                    // Log image messages
                    if message.mediaType == .image {
                        print("📥 Received image message from Firestore:")
                        print("   ID: \(message.id ?? "unknown")")
                        print("   MediaURL: \(message.mediaURL ?? "none")")
                        print("   Status: \(message.status)")
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
    
    /// Stop listening to messages
    nonisolated func stopListening() {
        messageListener?.remove()
        typingListener?.remove()
        messageListener = nil
        typingListener = nil
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
            
            // Try to upload if online
            if networkMonitor.isConnected {
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
                    // Upload failed - mark as failed
                    if let index = messages.firstIndex(where: { $0.id == messageID }) {
                        messages[index].status = .failed
                    }
                    return
                }
            } else {
                // Offline - stay in .staged state for later processing
                return
            }
        }
        
        // STAGE 3: Send to Firestore
        // Update to .sending state (if not already)
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            if messages[index].status != .sending {
                messages[index].status = .sending
            }
        }
        
        do {
            print("📤 Sending message to Firestore:")
            print("   ID: \(messageID)")
            print("   MediaURL: \(newMessage.mediaURL ?? "none")")
            print("   MediaType: \(String(describing: newMessage.mediaType))")
            
            try await messageService.sendMessage(newMessage)
            
            // STAGE 4: Mark as sent (will be confirmed by listener → .delivered/.read)
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .sent
                try? localStorage.markMessageSynced(id: messageID)
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
            if let mediaURL = await imageUploadManager.retryUpload(for: messageID, conversationID: conversationID) {
                // Upload succeeded
                updatedMessage.mediaURL = mediaURL
                messages[index].mediaURL = mediaURL
            } else {
                // Upload failed
                messages[index].status = .failed
                return
            }
        }
        
        // Send to Firestore
        do {
            try await messageService.sendMessage(updatedMessage)
            
            // Mark as sent (will be confirmed by listener)
            messages[index].status = .sent
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
            messages[index].status = .failed
        }
    }
    
    /// Retry all failed and pending messages
    /// Strategy: Auto-retry once on reconnect, then require manual retry (tap button)
    func retryAllFailedMessages() async {
        guard networkMonitor.isConnected else { return }
        
        // Find messages that need retry (using new lifecycle states)
        let messagesToRetry = messages.filter { message in
            // Staged messages (created offline, never sent)
            if message.status == .staged {
                return true
            }
            
            // Failed messages (only auto-retry if first attempt)
            if message.status.isRetryable {
                // Check ImageUploadManager for retry count
                if let messageID = message.id,
                   case .failed(_, let retryCount) = imageUploadManager.getState(for: messageID) {
                    return retryCount < 2  // Auto-retry once
                }
                return true  // No image state, always retry
            }
            
            // Stuck image uploads (sending but no URL)
            if message.status == .sending && message.mediaType == .image && message.mediaURL == nil {
                return true
            }
            
            return false
        }
        
        // Retry each message
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
            
            guard !unreadMessageIDs.isEmpty else { 
                print("📖 No unread messages to mark")
                return 
            }
            
            print("📖 Marking \(unreadMessageIDs.count) messages as read: \(unreadMessageIDs)")
            
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
    
    deinit {
        stopListening()
        typingTimer?.invalidate()
    }
}


