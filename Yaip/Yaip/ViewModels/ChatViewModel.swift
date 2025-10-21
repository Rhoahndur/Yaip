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
        messageListener = messageService.listenToMessages(conversationID: conversationID) { [weak self] messages in
            Task { @MainActor in
                guard let self = self else { return }
                
                let oldMessages = self.messages
                self.messages = messages
                self.isLoading = false
                
                // Save to local storage
                for message in messages {
                    try? self.localStorage.saveMessage(message)
                }
                
                // Auto-mark new unread messages as read (if we're viewing the chat)
                guard let userID = self.authManager.currentUserID else { return }
                
                let newMessages = messages.filter { newMsg in
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
        guard let currentUserID = authManager.currentUserID,
              let conversationID = conversation.id else {
            return
        }
        
        // Ensure we have either text or image
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = selectedImage
        
        guard !text.isEmpty || image != nil else {
            return
        }
        
        // Clear inputs immediately
        messageText = ""
        selectedImage = nil
        
        // Stop typing indicator
        await updateTypingStatus(false)
        
        // Upload image if present
        var mediaURL: String?
        var mediaType: MediaType?
        
        if let image = image {
            isUploadingImage = true
            do {
                mediaURL = try await storageService.uploadChatImage(image, conversationID: conversationID)
                mediaType = .image
            } catch {
                print("Error uploading image: \(error)")
                errorMessage = "Failed to upload image"
                isUploadingImage = false
                return
            }
            isUploadingImage = false
        }
        
        // Create message
        let messageID = UUID().uuidString
        var newMessage = Message(
            id: nil,
            conversationID: conversationID,
            senderID: currentUserID,
            text: text.isEmpty ? nil : text,
            mediaURL: mediaURL,
            mediaType: mediaType,
            timestamp: Date(),
            status: .sending,
            readBy: [currentUserID]
        )
        newMessage.id = messageID
        
        // Optimistic update - add to UI immediately
        messages.append(newMessage)
        
        // Save locally first
        try? localStorage.saveMessage(newMessage)
        
        // Send to Firestore
        do {
            try await messageService.sendMessage(newMessage)
            
            // Mark as synced
            try? localStorage.markMessageSynced(id: messageID)
            
            // Update message status to sent
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .sent
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
            
        } catch {
            print("Error sending message: \(error.localizedDescription)")
            // Update message status to failed
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .failed
            }
            errorMessage = "Failed to send message"
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

