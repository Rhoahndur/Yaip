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
    
    // Computed property to check if message is from current user
    func isFromCurrentUser(_ currentUserID: String) -> Bool {
        return senderID == currentUserID
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
    }
}

/// Message delivery status
enum MessageStatus: String, Codable {
    case sending    // Optimistic UI - not yet sent
    case sent       // Saved to Firestore
    case delivered  // Other user's device received
    case read       // Other user opened chat
    case failed     // Send failed, needs retry
}

/// Type of media attached to message
enum MediaType: String, Codable {
    case image
    case video
}

