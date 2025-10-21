//
//  PresenceService.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore

/// Service for managing user presence and online status
class PresenceService {
    static let shared = PresenceService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Update user's online status
    func updateStatus(_ status: UserStatus, for userID: String) async throws {
        try await db.collection(Constants.Collections.users)
            .document(userID)
            .updateData([
                "status": status.rawValue,
                "lastSeen": FieldValue.serverTimestamp()
            ])
    }
    
    /// Set user to online
    func setOnline(userID: String) async throws {
        try await updateStatus(.online, for: userID)
    }
    
    /// Set user to offline
    func setOffline(userID: String) async throws {
        try await updateStatus(.offline, for: userID)
    }
    
    /// Listen to user's online status
    func listenToPresence(userID: String, completion: @escaping (UserStatus, Date?) -> Void) -> ListenerRegistration {
        return db.collection(Constants.Collections.users)
            .document(userID)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data() else {
                    completion(.offline, nil)
                    return
                }
                
                let statusString = data["status"] as? String ?? "offline"
                let status = UserStatus(rawValue: statusString) ?? .offline
                let lastSeen = (data["lastSeen"] as? Timestamp)?.dateValue()
                
                completion(status, lastSeen)
            }
    }
    
    /// Listen to multiple users' presence
    func listenToMultiplePresence(userIDs: [String], completion: @escaping ([String: (UserStatus, Date?)]) -> Void) -> [ListenerRegistration] {
        var listeners: [ListenerRegistration] = []
        var presenceData: [String: (UserStatus, Date?)] = [:]
        
        for userID in userIDs {
            let listener = listenToPresence(userID: userID) { status, lastSeen in
                presenceData[userID] = (status, lastSeen)
                completion(presenceData)
            }
            listeners.append(listener)
        }
        
        return listeners
    }
}

