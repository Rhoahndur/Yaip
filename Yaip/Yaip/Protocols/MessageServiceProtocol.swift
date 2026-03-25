import Foundation
import FirebaseFirestore

/// Contract for Firestore message operations.
///
/// Covers the full message lifecycle: send, fetch, listen, read receipts,
/// typing indicators, reactions, deletion, and replies.
protocol MessageServiceProtocol {
    /// Send a message to Firestore. The message must have a valid `conversationID`.
    /// - Throws: Firestore write errors.
    func sendMessage(_ message: Message) async throws

    /// Fetch messages for a conversation, ordered by timestamp.
    /// - Parameters:
    ///   - conversationID: The conversation to fetch from.
    ///   - limit: Maximum number of messages to return.
    /// - Returns: Array of messages sorted by timestamp ascending.
    func fetchMessages(conversationID: String, limit: Int) async throws -> [Message]

    /// Start a real-time listener for messages in a conversation.
    /// - Important: Caller must retain the returned `ListenerRegistration` and call `remove()` when done.
    /// - Returns: A Firestore listener registration.
    func listenToMessages(conversationID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration

    /// Mark specific messages as read by a user. Updates both `readBy` array and `status` field.
    func markMessagesAsRead(conversationID: String, messageIDs: [String], userID: String) async throws

    /// Fetch read receipt timestamps for a specific message.
    /// - Returns: Dictionary mapping user IDs to the time they read the message.
    func getReadReceipts(conversationID: String, messageID: String) async throws -> [String: Date]

    /// Update the typing indicator for the current user in a conversation.
    func updateTypingStatus(conversationID: String, userID: String, isTyping: Bool) async throws

    /// Listen for typing status changes from another user.
    /// - Returns: A Firestore listener registration.
    func listenToTypingStatus(conversationID: String, otherUserID: String, completion: @escaping (Bool) -> Void) -> ListenerRegistration

    /// Toggle a reaction emoji on a message. Adds if not present, removes if already added.
    func toggleReaction(emoji: String, messageID: String, conversationID: String, userID: String) async throws

    /// Soft-delete a message by setting `isDeleted = true` and clearing its text.
    func deleteMessage(messageID: String, conversationID: String) async throws

    /// Send a reply to an existing message. Sets the `replyTo` field on the new message.
    func sendReply(to messageID: String, text: String, conversationID: String, senderID: String) async throws
}
