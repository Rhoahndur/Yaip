//
//  ConversationService.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore

/// Service for managing conversations in Firestore
class ConversationService {
    static let shared = ConversationService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Create a new conversation
    func createConversation(_ conversation: Conversation) async throws {
        guard let id = conversation.id else {
            throw ConversationError.invalidID
        }
        try db.collection(Constants.Collections.conversations).document(id).setData(from: conversation)
    }
    
    /// Fetch conversations for a user
    func fetchConversations(for userID: String) async throws -> [Conversation] {
        let snapshot = try await db.collection(Constants.Collections.conversations)
            .whereField("participants", arrayContains: userID)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Conversation.self)
        }
    }
    
    /// Listen to conversations in real-time
    func listenToConversations(for userID: String, completion: @escaping ([Conversation]) -> Void) -> ListenerRegistration {
        return db.collection(Constants.Collections.conversations)
            .whereField("participants", arrayContains: userID)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching conversations: \(error?.localizedDescription ?? "Unknown")")
                    completion([])
                    return
                }
                
                let conversations = documents.compactMap { doc in
                    try? doc.data(as: Conversation.self)
                }
                completion(conversations)
            }
    }
    
    /// Update last message in conversation
    func updateLastMessage(conversationID: String, lastMessage: LastMessage) async throws {
        try await db.collection(Constants.Collections.conversations)
            .document(conversationID)
            .updateData([
                "lastMessage": [
                    "text": lastMessage.text,
                    "senderID": lastMessage.senderID,
                    "timestamp": Timestamp(date: lastMessage.timestamp)
                ],
                "updatedAt": Timestamp(date: Date())
            ])
    }
    
    /// Check if conversation exists between users
    func findExistingConversation(between participants: [String]) async throws -> Conversation? {
        // For 1-on-1, check if conversation already exists
        let snapshot = try await db.collection(Constants.Collections.conversations)
            .whereField("participants", arrayContains: participants[0])
            .whereField("type", isEqualTo: ConversationType.oneOnOne.rawValue)
            .getDocuments()
        
        // Find conversation that has exactly these participants
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Conversation.self)
        }.first { conv in
            Set(conv.participants) == Set(participants)
        }
    }
    
    /// Delete a conversation
    func deleteConversation(conversationID: String) async throws {
        try await db.collection(Constants.Collections.conversations)
            .document(conversationID)
            .delete()
    }
}

enum ConversationError: LocalizedError {
    case invalidID
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidID:
            return "Conversation ID is invalid"
        case .notFound:
            return "Conversation not found"
        }
    }
}

