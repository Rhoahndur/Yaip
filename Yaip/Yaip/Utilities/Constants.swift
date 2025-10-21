//
//  Constants.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation

/// App-wide constants
enum Constants {
    /// Firestore collection names
    enum Collections {
        static let users = "users"
        static let conversations = "conversations"
        static let messages = "messages"
        static let decisions = "decisions"
        static let userPresence = "userPresence"
        static let userPriority = "userPriority"
        static let aiCache = "aiCache"
    }
    
    /// Pagination and limits
    enum Limits {
        static let messagesPageSize = 50
        static let conversationsPageSize = 20
        static let maxImageSizeKB = 5000 // 5MB
        static let maxImageSizeMB = 5
    }
    
    /// Cache durations (in seconds)
    enum Cache {
        static let summaryTTL = 3600 // 1 hour
        static let actionItemsTTL = 86400 // 24 hours
        static let searchTTL = 600 // 10 minutes
    }
    
    /// Rate limits
    enum RateLimits {
        static let summariesPerDay = 10
        static let searchesPerDay = 50
    }
}

