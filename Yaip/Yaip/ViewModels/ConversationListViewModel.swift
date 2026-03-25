//
//  ConversationListViewModel.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// ViewModel for managing the conversation list.
///
/// Provides real-time conversation listening, 1-on-1 and group conversation creation,
/// unread filtering, and mark-all-as-read. Uses `ListenerBag` for lifecycle-safe
/// Firestore listener management.
@MainActor
class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showUnreadOnly: Bool = false

    private let listenerBag = ListenerBag()
    let conversationService: ConversationServiceProtocol
    let authManager: AuthManagerProtocol
    private let localStorage: LocalStorageManagerProtocol

    init(
        conversationService: ConversationServiceProtocol = ConversationService.shared,
        authManager: AuthManagerProtocol = AuthManager.shared,
        localStorage: LocalStorageManagerProtocol = LocalStorageManager.shared
    ) {
        self.conversationService = conversationService
        self.authManager = authManager
        self.localStorage = localStorage
    }

    /// Filtered conversations based on unread status
    var filteredConversations: [Conversation] {
        guard showUnreadOnly else { return conversations }
        guard let currentUserID = authManager.currentUserID else { return conversations }

        return conversations.filter { conversation in
            let unreadCount = conversation.unreadCount[currentUserID] ?? 0
            return unreadCount > 0
        }
    }
    
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
        
        let convListener = conversationService.listenToConversations(for: userID) { [weak self] conversations in
            Task { @MainActor in
                guard let self = self else { return }
                
                let filteredConversations = conversations.excludingSelfChats()
                self.conversations = filteredConversations
                self.isLoading = false
                
                // Save to local storage
                for conversation in filteredConversations {
                    do {
                        try self.localStorage.saveConversation(conversation)
                    } catch {
                        AppLogger.logSilentFailure(error, context: "saveConversation(listener)", category: .storage)
                    }
                }
            }
        }
        listenerBag.store(convListener, key: "conversations")
    }
    
    /// Stop listening to conversations
    func stopListening() {
        listenerBag.removeAll()
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
    
    /// Create a new 1-on-1 conversation with another user.
    ///
    /// Checks for an existing conversation first to avoid duplicates.
    /// - Throws: `ConversationError.cannotChatWithSelf` if trying to chat with yourself.
    /// - Returns: The existing or newly created conversation.
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
        AnalyticsService.logConversationCreated(type: "oneOnOne", participantCount: 2)
        return conversation
    }

    /// Create a new group conversation with the specified name and participants.
    ///
    /// Automatically adds the current user to the participant list if not already included.
    /// - Returns: The newly created group conversation.
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
        AnalyticsService.logConversationCreated(type: "group", participantCount: allParticipants.count)
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

    /// Toggle filter to show only unread conversations
    func toggleFilterUnread() {
        showUnreadOnly.toggle()
    }

    /// Mark all conversations as read for the current user
    func markAllAsRead() async {
        guard let currentUserID = authManager.currentUserID else { return }

        for conversation in conversations {
            guard let conversationID = conversation.id else { continue }
            let unreadCount = conversation.unreadCount[currentUserID] ?? 0

            if unreadCount > 0 {
                do {
                    try await conversationService.markAsRead(
                        conversationID: conversationID,
                        userID: currentUserID
                    )
                } catch {
                    AppLogger.logSilentFailure(error, context: "markAllAsRead", category: .messages)
                }
            }
        }
    }

    deinit {
        stopListening()
    }
}

