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
                
                // Smart merge: Keep Firestore messages + pending local messages
                var mergedMessages: [Message] = []
                let firestoreIDs = Set(firestoreMessages.compactMap { $0.id })
                
                // Add all Firestore messages (source of truth for synced messages)
                mergedMessages.append(contentsOf: firestoreMessages)
                
                // Keep local pending/failed messages that haven't synced yet
                let pendingLocal = oldMessages.filter { localMsg in
                    guard let id = localMsg.id else { return false }
                    // Keep if not in Firestore and still pending/failed
                    let isPending = !firestoreIDs.contains(id) && 
                                   (localMsg.status == .sending || localMsg.status == .failed)
                    
                    if isPending {
                        print("📌 Keeping pending message \(id): text='\(localMsg.text ?? "nil")', hasMedia=\(localMsg.mediaType != nil), status=\(localMsg.status)")
                    }
                    
                    return isPending
                }
                mergedMessages.append(contentsOf: pendingLocal)
                
                print("🔀 Merge complete: Firestore=\(firestoreMessages.count), Pending=\(pendingLocal.count), Total=\(mergedMessages.count)")
                
                // Sort by timestamp
                mergedMessages.sort { $0.timestamp < $1.timestamp }
                
                self.messages = mergedMessages
                self.isLoading = false
                
                // Auto-retry pending messages if we're online
                if !pendingLocal.isEmpty {
                    print("📶 Pending messages found. Network status: \(self.networkMonitor.isConnected ? "ONLINE ✅" : "OFFLINE ❌")")
                    
                    if self.networkMonitor.isConnected {
                        print("🔄 Network online + pending messages detected - triggering auto-retry")
                        Task {
                            // Small delay to let UI settle
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            await self.retryAllFailedMessages()
                        }
                    } else {
                        print("⚠️ Not retrying - device is offline")
                    }
                }
                
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
    
    /// Send a message (simplified with ImageUploadManager)
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
        
        // Create message
        let messageID = UUID().uuidString
        var newMessage = Message(
            id: nil,
            conversationID: conversationID,
            senderID: currentUserID,
            text: text.isEmpty ? nil : text,
            mediaURL: nil,
            mediaType: image != nil ? .image : nil,
            timestamp: Date(),
            status: .sending,
            readBy: [currentUserID]
        )
        newMessage.id = messageID
        
        // Add to UI immediately (optimistic)
        messages.append(newMessage)
        
        // Save locally
        try? localStorage.saveMessage(newMessage)
        
        // Handle image via ImageUploadManager
        var mediaURL: String?
        if let image = image {
            // Cache image first
            imageUploadManager.cacheImage(image, for: messageID)
            
            // Try to upload if online
            if networkMonitor.isConnected {
                mediaURL = await imageUploadManager.uploadImage(for: messageID, conversationID: conversationID)
                
                if let url = mediaURL {
                    // Update message with URL
                    if let index = messages.firstIndex(where: { $0.id == messageID }) {
                        messages[index].mediaURL = url
                        newMessage.mediaURL = url
                        try? localStorage.saveMessage(messages[index])
                    }
                } else {
                    // Upload failed - mark as failed
                    if let index = messages.firstIndex(where: { $0.id == messageID }) {
                        messages[index].status = .failed
                    }
                    return
                }
            } else {
                // Offline - keep in .sending state for later retry
                return
            }
        }
        
        // Send to Firestore
        do {
            try await messageService.sendMessage(newMessage)
            
            // Mark as synced
            try? localStorage.markMessageSynced(id: messageID)
            
            // Update status
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .sent
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
    
    /// Retry sending a failed or stuck message (simplified with ImageUploadManager)
    func retryMessage(_ message: Message) async {
        guard let messageID = message.id,
              let index = messages.firstIndex(where: { $0.id == messageID }),
              let conversationID = conversation.id,
              let currentUserID = authManager.currentUserID else {
            return
        }
        
        // Only retry if failed or stuck
        let shouldRetry = message.status == .failed || 
                         (message.status == .sending && message.mediaType == .image && message.mediaURL == nil)
        
        guard shouldRetry else { return }
        
        // Update status to sending
        messages[index].status = .sending
        var updatedMessage = messages[index]
        
        // Handle image retry via ImageUploadManager
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
            
            // Mark as synced
            try? localStorage.markMessageSynced(id: messageID)
            
            // Update status
            messages[index].status = .sent
            
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
    
    /// Retry all failed messages and stuck pending messages
    /// Strategy: Auto-retry once on reconnect, then require manual retry (tap button)
    func retryAllFailedMessages() async {
        guard networkMonitor.isConnected else { return }
        
        // Find messages that need retry
        let messagesToRetry = messages.filter { message in
            // Only auto-retry if this is the first attempt (retryCount < 2)
            if message.status == .failed {
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


