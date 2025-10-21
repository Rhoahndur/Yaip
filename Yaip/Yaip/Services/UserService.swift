//
//  UserService.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import Foundation
import FirebaseFirestore

/// Service for user-related operations
class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    // Cache for user data to avoid repeated fetches
    private var userCache: [String: User] = [:]
    
    private init() {}
    
    /// Fetch user by ID
    func fetchUser(id: String) async throws -> User {
        // Check cache first
        if let cachedUser = userCache[id] {
            return cachedUser
        }
        
        // Fetch from Firestore
        let snapshot = try await db.collection(Constants.Collections.users)
            .document(id)
            .getDocument()
        
        guard snapshot.exists else {
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        // Use snapshot.data(as:) which properly handles @DocumentID
        let user = try snapshot.data(as: User.self)
        
        // Cache the user
        userCache[id] = user
        
        return user
    }
    
    /// Fetch multiple users by IDs
    func fetchUsers(ids: [String]) async throws -> [User] {
        var users: [User] = []
        
        for id in ids {
            do {
                let user = try await fetchUser(id: id)
                users.append(user)
            } catch {
                print("Error fetching user \(id): \(error)")
                // Continue with other users even if one fails
            }
        }
        
        return users
    }
    
    /// Search users by display name
    func searchUsers(query: String) async throws -> [User] {
        // If query is empty, return all users
        if query.isEmpty {
            let snapshot = try await db.collection(Constants.Collections.users)
                .limit(to: 50)
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: User.self)
            }
        }
        
        // Search by display name (case-insensitive)
        let snapshot = try await db.collection(Constants.Collections.users)
            .whereField("displayName", isGreaterThanOrEqualTo: query)
            .whereField("displayName", isLessThan: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: User.self)
        }
    }
    
    /// Clear user cache (useful after logout)
    func clearCache() {
        userCache.removeAll()
    }
}

