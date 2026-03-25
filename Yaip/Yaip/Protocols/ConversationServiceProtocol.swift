import Foundation
import FirebaseFirestore

/// Contract for Firestore conversation operations.
///
/// Manages conversation CRUD, real-time listening, read state, and unread counts.
protocol ConversationServiceProtocol {
    /// Create a new conversation document in Firestore.
    func createConversation(_ conversation: Conversation) async throws

    /// Fetch all conversations where the user is a participant.
    func fetchConversations(for userID: String) async throws -> [Conversation]

    /// Start a real-time listener for conversations the user participates in.
    /// - Important: Caller must retain the returned `ListenerRegistration`.
    /// - Returns: A Firestore listener registration.
    func listenToConversations(for userID: String, completion: @escaping ([Conversation]) -> Void) -> ListenerRegistration

    /// Update the `lastMessage` preview field on a conversation.
    func updateLastMessage(conversationID: String, lastMessage: LastMessage) async throws

    /// Find an existing 1-on-1 conversation between two participants.
    /// - Returns: The existing conversation, or `nil` if none exists.
    func findExistingConversation(between participants: [String]) async throws -> Conversation?

    /// Delete a conversation and its subcollections.
    func deleteConversation(conversationID: String) async throws

    /// Reset the unread count for a user in a conversation to zero.
    func markAsRead(conversationID: String, userID: String) async throws

    /// Increment the unread count for the specified users in a conversation.
    func incrementUnreadCount(conversationID: String, for userIDs: [String]) async throws
}
