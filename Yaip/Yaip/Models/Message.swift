//
//  Message.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// Message model representing a single chat message
struct Message: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var conversationID: String
    var senderID: String
    var text: String?
    var mediaURL: String?
    var mediaType: MediaType?
    var timestamp: Date
    var status: MessageStatus
    var readBy: [String] // User IDs who have read this message

    // Polish features
    var reactions: [String: [String]] = [:] // emoji -> [userIDs]
    var replyTo: String? // messageID this is replying to
    var isDeleted: Bool = false
    var deletedAt: Date?

    // Computed property to check if message is from current user
    func isFromCurrentUser(_ currentUserID: String) -> Bool {
        return senderID == currentUserID
    }

    // Get total reaction count
    var totalReactions: Int {
        reactions.values.reduce(0) { $0 + $1.count }
    }

    // Check if user reacted with specific emoji
    func userReacted(with emoji: String, userID: String) -> Bool {
        reactions[emoji]?.contains(userID) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case id
        case conversationID
        case senderID
        case text
        case mediaURL
        case mediaType
        case timestamp
        case status
        case readBy
        case reactions
        case replyTo
        case isDeleted
        case deletedAt
    }
}

/// Message delivery status with clear lifecycle stages
enum MessageStatus: String, Codable {
    // Local states (before network operations)
    case staged     // Created, saved locally, ready to send
    case sending    // Currently uploading/sending to Firestore
    case failed     // Send failed, needs retry
    
    // Network states (confirmed by Firestore)
    case sent       // Successfully saved to Firestore
    case delivered  // Other user's device received (confirmed by listener)
    case read       // Other user opened chat (confirmed by listener)
    
    /// Is this a local state (not confirmed by Firestore)?
    var isLocal: Bool {
        switch self {
        case .staged, .sending, .failed:
            return true
        case .sent, .delivered, .read:
            return false
        }
    }
    
    /// Can this message be retried?
    var isRetryable: Bool {
        return self == .failed
    }
    
    /// Is this a final state (confirmed by Firestore)?
    var isSynced: Bool {
        switch self {
        case .sent, .delivered, .read:
            return true
        case .staged, .sending, .failed:
            return false
        }
    }
}

/// Type of media attached to message
enum MediaType: String, Codable {
    case image
    case video
}

