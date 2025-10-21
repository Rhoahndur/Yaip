//
//  User.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore

/// User model representing a registered user in the app
struct User: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var displayName: String
    var email: String
    var profileImageURL: String?
    var status: UserStatus
    var lastSeen: Date?  // Optional - might be null for newly created users
    var fcmToken: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case email
        case profileImageURL
        case status
        case lastSeen
        case fcmToken
        case createdAt
    }
}

/// User online/offline status
enum UserStatus: String, Codable {
    case online
    case offline
    case away
}

