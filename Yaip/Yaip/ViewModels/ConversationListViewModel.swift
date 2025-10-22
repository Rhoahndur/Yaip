//
//  ConversationListViewModel.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// ViewModel for managing the conversation list
@MainActor
class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    nonisolated(unsafe) private var listener: ListenerRegistration?
    let conversationService = ConversationService.shared // Made public for NewChatView access
    let authManager = AuthManager.shared
    private let localStorage = LocalStorageManager.shared
    
    /// Start listening to conversations in real-time
    func startListening() {
        guard let userID = authManager.currentUserID else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        
        // Load from local storage first
        Task {
            do {
                let localConversations = try localStorage.fetchConversations()
                self.conversations = localConversations
            } catch {
                print("Error loading local conversations: \(error)")
            }
        }
        
        listener = conversationService.listenToConversations(for: userID) { [weak self] conversations in
            Task { @MainActor in
                guard let self = self else { return }
                
                // Filter out conversations where user is talking to themselves
                let filteredConversations = conversations.filter { conversation in
                    if conversation.type == .group {
                        return true // Keep all group chats
                    }
                    // For 1-on-1, make sure it's not with yourself
                    let uniqueParticipants = Set(conversation.participants)
                    return uniqueParticipants.count > 1
                }
                
                self.conversations = filteredConversations
                self.isLoading = false
                
                // Save to local storage
                for conversation in filteredConversations {
                    try? self.localStorage.saveConversation(conversation)
                }
            }
        }
    }
    
    /// Stop listening to conversations
    nonisolated func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    /// Fetch conversations once (without listener)
    func fetchConversations() async {
        guard let userID = authManager.currentUserID else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        
        do {
            let conversations = try await conversationService.fetchConversations(for: userID)
            
            // Filter out conversations where user is talking to themselves
            let filteredConversations = conversations.filter { conversation in
                if conversation.type == .group {
                    return true // Keep all group chats
                }
                // For 1-on-1, make sure it's not with yourself
                let uniqueParticipants = Set(conversation.participants)
                return uniqueParticipants.count > 1
            }
            
            self.conversations = filteredConversations
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    /// Create a new 1-on-1 conversation
    func createOneOnOneConversation(with otherUser: User) async throws -> Conversation {
        guard let currentUserID = authManager.currentUserID,
              let otherUserID = otherUser.id else {
            throw ConversationError.invalidID
        }
        
        // Prevent creating conversation with yourself
        guard currentUserID != otherUserID else {
            throw ConversationError.cannotChatWithSelf
        }
        
        let participants = [currentUserID, otherUserID]
        
        // Check if conversation already exists
        if let existing = try await conversationService.findExistingConversation(between: participants) {
            return existing
        }
        
        // Create new conversation
        let conversationID = UUID().uuidString
        let conversation = Conversation(
            id: nil, // Let Firestore set it
            type: .oneOnOne,
            participants: participants,
            name: nil, // Don't store name for 1-on-1 (compute dynamically)
            imageURL: nil,
            lastMessage: nil,
            createdAt: Date(),
            updatedAt: Date(),
            unreadCount: [:]
        )
        
        // Set the ID in the service when creating
        var conversationToCreate = conversation
        conversationToCreate.id = conversationID
        try await conversationService.createConversation(conversationToCreate)
        return conversation
    }
    
    /// Create a new group conversation
    func createGroupConversation(name: String, participants: [String]) async throws -> Conversation {
        guard let currentUserID = authManager.currentUserID else {
            throw ConversationError.invalidID
        }
        
        var allParticipants = participants
        if !allParticipants.contains(currentUserID) {
            allParticipants.append(currentUserID)
        }
        
        let conversationID = UUID().uuidString
        let conversation = Conversation(
            id: nil, // Let Firestore set it
            type: .group,
            participants: allParticipants,
            name: name,
            imageURL: nil,
            lastMessage: nil,
            createdAt: Date(),
            updatedAt: Date(),
            unreadCount: [:]
        )
        
        var conversationToCreate = conversation
        conversationToCreate.id = conversationID
        try await conversationService.createConversation(conversationToCreate)
        return conversation
    }
    
    /// Delete a conversation
    func deleteConversation(_ conversation: Conversation) async {
        guard let conversationID = conversation.id else { return }
        
        do {
            try await conversationService.deleteConversation(conversationID: conversationID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    deinit {
        stopListening()
    }
}

