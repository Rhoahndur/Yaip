//
//  PresenceService.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore
import FirebaseDatabase

/// Service for managing user presence and online status
class PresenceService {
    static let shared = PresenceService()
    private let db = Firestore.firestore()
    private let realtimeDB = Database.database().reference()

    // Heartbeat timer
    private var heartbeatTimer: Timer?
    private var currentUserID: String?

    // Configuration
    private let heartbeatInterval: TimeInterval = 30 // 30 seconds
    private let offlineThreshold: TimeInterval = 120 // 2 minutes

    private init() {}

    /// Set user to online with automatic disconnect handling
    func setOnline(userID: String) async throws {
        currentUserID = userID

        // Update Firestore
        try await db.collection(Constants.Collections.users)
            .document(userID)
            .updateData([
                "status": UserStatus.online.rawValue,
                "lastSeen": FieldValue.serverTimestamp(),
                "lastHeartbeat": FieldValue.serverTimestamp()
            ])

        // Setup Firebase Realtime Database presence (for automatic disconnect detection)
        let presenceRef = realtimeDB.child("presence").child(userID)

        // When connection is lost, automatically set to offline
        try await presenceRef.onDisconnectUpdateChildValues([
            "status": "offline",
            "lastSeen": ServerValue.timestamp()
        ])

        // Set online in Realtime DB
        try await presenceRef.setValue([
            "status": "online",
            "lastSeen": ServerValue.timestamp()
        ])

        // Mirror changes from Realtime DB to Firestore
        setupRealtimeDBSync(userID: userID)

        // Start heartbeat
        startHeartbeat(userID: userID)

        print("✅ User \(userID) set to ONLINE with disconnect detection")
    }

    /// Set user to offline
    func setOffline(userID: String) async throws {
        // Stop heartbeat
        stopHeartbeat()

        // Update Firestore
        try await db.collection(Constants.Collections.users)
            .document(userID)
            .updateData([
                "status": UserStatus.offline.rawValue,
                "lastSeen": FieldValue.serverTimestamp()
            ])

        // Update Realtime DB
        let presenceRef = realtimeDB.child("presence").child(userID)
        try await presenceRef.setValue([
            "status": "offline",
            "lastSeen": ServerValue.timestamp()
        ])

        // Cancel disconnect handler
        try await presenceRef.onDisconnectRemoveValue()

        print("✅ User \(userID) set to OFFLINE")
    }

    /// Update user's online status
    func updateStatus(_ status: UserStatus, for userID: String) async throws {
        try await db.collection(Constants.Collections.users)
            .document(userID)
            .updateData([
                "status": status.rawValue,
                "lastSeen": FieldValue.serverTimestamp(),
                "lastHeartbeat": FieldValue.serverTimestamp()
            ])

        // Also update Realtime DB for consistency
        let presenceRef = realtimeDB.child("presence").child(userID)
        try await presenceRef.updateChildValues([
            "status": status.rawValue,
            "lastSeen": ServerValue.timestamp()
        ])
    }

    /// Start heartbeat timer to update lastHeartbeat periodically
    private func startHeartbeat(userID: String) {
        stopHeartbeat() // Clear any existing timer

        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.sendHeartbeat(userID: userID)
            }
        }

        print("💓 Started heartbeat for user \(userID) (interval: \(heartbeatInterval)s)")
    }

    /// Stop heartbeat timer
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        print("💔 Stopped heartbeat")
    }

    /// Send heartbeat to keep connection alive
    private func sendHeartbeat(userID: String) async {
        do {
            try await db.collection(Constants.Collections.users)
                .document(userID)
                .updateData([
                    "lastHeartbeat": FieldValue.serverTimestamp()
                ])
            // print("💓 Heartbeat sent for \(userID)")
        } catch {
            print("❌ Heartbeat failed: \(error)")
        }
    }

    /// Sync Realtime DB presence to Firestore
    private func setupRealtimeDBSync(userID: String) {
        let presenceRef = realtimeDB.child("presence").child(userID)

        presenceRef.observe(.value) { [weak self] snapshot in
            guard let data = snapshot.value as? [String: Any],
                  let status = data["status"] as? String else {
                return
            }

            // Update Firestore when Realtime DB changes (e.g., on disconnect)
            Task {
                do {
                    try await self?.db.collection(Constants.Collections.users)
                        .document(userID)
                        .updateData([
                            "status": status,
                            "lastSeen": FieldValue.serverTimestamp()
                        ])
                } catch {
                    print("❌ Failed to sync presence to Firestore: \(error)")
                }
            }
        }
    }
    
    /// Listen to user's online status with smart inference
    func listenToPresence(userID: String, completion: @escaping (UserStatus, Date?) -> Void) -> ListenerRegistration {
        return db.collection(Constants.Collections.users)
            .document(userID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data() else {
                    completion(.offline, nil)
                    return
                }

                let statusString = data["status"] as? String ?? "offline"
                var status = UserStatus(rawValue: statusString) ?? .offline
                let lastSeen = (data["lastSeen"] as? Timestamp)?.dateValue()
                let lastHeartbeat = (data["lastHeartbeat"] as? Timestamp)?.dateValue()

                // Smart status inference: If status is "online" or "away" but last heartbeat is old, mark as offline
                if (status == .online || status == .away),
                   let heartbeat = lastHeartbeat,
                   Date().timeIntervalSince(heartbeat) > (self?.offlineThreshold ?? 120) {
                    print("⚠️ User \(userID) appears stale (last heartbeat: \(heartbeat.formatted())), marking as offline")
                    status = .offline
                }

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

