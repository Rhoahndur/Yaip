import Foundation
import FirebaseFirestore

/// Contract for user presence and online status management.
///
/// Tracks whether users are online, away, or offline, and provides real-time listeners.
protocol PresenceServiceProtocol {
    /// Set a user's status to `.online` and update `lastSeen` to now.
    func setOnline(userID: String) async throws

    /// Set a user's status to `.offline` and update `lastSeen` to now.
    func setOffline(userID: String) async throws

    /// Update a user's status to a specific value (`.online`, `.away`, `.offline`).
    func updateStatus(_ status: UserStatus, for userID: String) async throws

    /// Listen for real-time changes to a single user's presence.
    /// - Returns: A Firestore listener registration.
    func listenToPresence(userID: String, completion: @escaping (UserStatus, Date?) -> Void) -> ListenerRegistration

    /// Listen for real-time presence changes for multiple users simultaneously.
    /// - Returns: Array of listener registrations — caller must remove all when done.
    func listenToMultiplePresence(userIDs: [String], completion: @escaping ([String: (UserStatus, Date?)]) -> Void) -> [ListenerRegistration]
}
