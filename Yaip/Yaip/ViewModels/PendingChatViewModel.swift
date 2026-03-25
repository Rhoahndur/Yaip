//
//  PendingChatViewModel.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/22/25.
//

import Foundation
import FirebaseFirestore
import Combine
import UIKit

/// ViewModel for pending conversations (not yet saved to Firestore)
@MainActor
class PendingChatViewModel: ObservableObject {
    @Published var messageText = ""
    @Published var selectedImage: UIImage?
    @Published var messages: [Message] = [] // Empty until conversation is created
    @Published var conversationCreated = false
    @Published var createdConversation: Conversation?
    @Published var isCreating = false
    @Published var errorMessage: String?
    
    let pendingConversation: PendingConversation
    private let conversationService: ConversationServiceProtocol
    private let messageService: MessageServiceProtocol
    private let storageService: StorageServiceProtocol
    private let authManager: AuthManagerProtocol

    var displayName: String {
        if let name = pendingConversation.name {
            return name
        }
        
        // For 1-on-1, show "New Chat" for now
        // We'll fetch the other user's name asynchronously
        if pendingConversation.type == .oneOnOne {
            // Try to get other user's name
            if let currentUserID = authManager.currentUserID,
               let _ = pendingConversation.participants.first(where: { $0 != currentUserID }) {
                // In a real app, we'd fetch this. For now, just show "New Chat"
                return "New Chat"
            }
        }
        
        return "New Chat"
    }
    
    init(
        pendingConversation: PendingConversation,
        conversationService: ConversationServiceProtocol = ConversationService.shared,
        messageService: MessageServiceProtocol = MessageService.shared,
        storageService: StorageServiceProtocol = StorageService.shared,
        authManager: AuthManagerProtocol = AuthManager.shared
    ) {
        self.pendingConversation = pendingConversation
        self.conversationService = conversationService
        self.messageService = messageService
        self.storageService = storageService
        self.authManager = authManager
    }
    
    /// Send the first message and create the conversation
    func sendFirstMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty || selectedImage != nil else {
            print("⚠️ Cannot send empty message")
            return
        }
        
        guard let currentUserID = authManager.currentUserID else {
            errorMessage = "User not authenticated"
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        do {
            // 1. Upload image if present
            var mediaURL: String?
            if let image = selectedImage {
                print("🖼️ Uploading image...")
                mediaURL = try await storageService.uploadImage(
                    image,
                    path: "chat_images/\(pendingConversation.id)/\(UUID().uuidString).jpg"
                )
                print("✅ Image uploaded: \(mediaURL ?? "nil")")
            }
            
            // 2. Create the conversation in Firestore
            print("📝 Creating conversation in Firestore...")
            let conversation = pendingConversation.toConversation()
            try await conversationService.createConversation(conversation)
            print("✅ Conversation created: \(conversation.id ?? "no-id")")
            
            // 3. Send the first message
            print("📤 Sending first message...")
            let message = Message(
                id: UUID().uuidString,
                conversationID: conversation.id!,
                senderID: currentUserID,
                text: messageText.trimmingCharacters(in: .whitespaces),
                mediaURL: mediaURL,
                mediaType: selectedImage != nil ? .image : nil,
                timestamp: Date(),
                status: .sent,
                readBy: [currentUserID]
            )
            
            try await messageService.sendMessage(message)
            print("✅ First message sent!")
            
            // 4. Update conversation's lastMessage field
            let lastMessage = LastMessage(
                text: message.text ?? "📷 Photo",
                senderID: currentUserID,
                timestamp: message.timestamp
            )
            try await conversationService.updateLastMessage(
                conversationID: conversation.id!,
                lastMessage: lastMessage
            )
            print("✅ Updated lastMessage in conversation")
            
            // 5. Update state to show we've created the conversation
            await MainActor.run {
                self.createdConversation = conversation
                self.conversationCreated = true
                self.messageText = ""
                self.selectedImage = nil
                self.isCreating = false
            }
            
        } catch {
            print("❌ Error creating conversation and sending message: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isCreating = false
            }
        }
    }
}


