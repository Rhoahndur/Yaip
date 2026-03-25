import Foundation
import FirebaseFirestore

/// Contract for user data operations with in-memory caching.
///
/// Provides user CRUD, real-time listeners, search, and cache management.
protocol UserServiceProtocol {
    /// Fetch a user by ID, using the in-memory cache unless `forceRefresh` is true.
    func fetchUser(id: String, forceRefresh: Bool) async throws -> User

    /// Listen for real-time changes to a user document.
    /// - Returns: A Firestore listener registration.
    func listenToUser(id: String, onChange: @escaping (User) -> Void) -> ListenerRegistration

    /// Fetch multiple users by their IDs in a single batch.
    func fetchUsers(ids: [String]) async throws -> [User]

    /// Update a user's display name and/or photo URL.
    func updateProfile(userID: String, displayName: String?, photoURL: String?) async throws

    /// Update only the display name for a user.
    func updateDisplayName(userID: String, displayName: String) async throws

    /// Update only the profile photo URL for a user.
    func updateProfilePhoto(userID: String, photoURL: String) async throws

    /// Search for users by display name prefix. Used for new-conversation user picker.
    func searchUsers(query: String) async throws -> [User]

    /// Clear the entire in-memory user cache.
    func clearCache()

    /// Remove a specific user from the cache, forcing a fresh fetch next time.
    func invalidateCache(for userID: String)
}
