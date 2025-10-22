//
//  Conversation.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore

/// Conversation model representing a chat (1-on-1 or group)
struct Conversation: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var type: ConversationType
    var participants: [String] // User IDs
    var name: String? // For groups only
    var imageURL: String?
    var lastMessage: LastMessage?
    var createdAt: Date
    var updatedAt: Date
    var unreadCount: [String: Int] // [userID: count]
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case participants
        case name
        case imageURL
        case lastMessage
        case createdAt
        case updatedAt
        case unreadCount
    }
}

/// Type of conversation
enum ConversationType: String, Codable {
    case oneOnOne
    case group
}

/// Last message preview for conversation list
struct LastMessage: Codable, Equatable, Hashable {
    var text: String
    var senderID: String
    var timestamp: Date
}

/// Pending conversation (not yet saved to Firestore)
/// Used when user selects recipients but hasn't sent first message yet
struct PendingConversation: Identifiable {
    let id: String = UUID().uuidString
    let type: ConversationType
    let participants: [String]
    let name: String? // For groups only
    
    /// Convert to a real Conversation when ready to save
    func toConversation() -> Conversation {
        return Conversation(
            id: self.id,
            type: self.type,
            participants: self.participants,
            name: self.name,
            imageURL: nil,
            lastMessage: nil,
            createdAt: Date(),
            updatedAt: Date(),
            unreadCount: [:]
        )
    }
}

