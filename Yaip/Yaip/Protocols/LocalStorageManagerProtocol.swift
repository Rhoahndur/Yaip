import UIKit

/// Contract for SwiftData local persistence.
///
/// Provides offline-first storage for messages, conversations, and cached images.
/// All methods run on `@MainActor` because SwiftData's `ModelContext` is not thread-safe.
@MainActor
protocol LocalStorageManagerProtocol {
    /// Save or update a message in local storage.
    func saveMessage(_ message: Message) throws
    /// Fetch all locally stored messages for a conversation, sorted by timestamp.
    func fetchMessages(conversationID: String) throws -> [Message]
    /// Delete a message from local storage by ID.
    func deleteMessage(id: String) throws
    /// Get all messages with `.staged` or `.failed` status that need to be sent.
    func getPendingMessages() throws -> [Message]
    /// Mark a message as synced with Firestore (updates status to `.sent`).
    func markMessageSynced(id: String) throws

    /// Save or update a conversation in local storage.
    func saveConversation(_ conversation: Conversation) throws
    /// Fetch all locally stored conversations.
    func fetchConversations() throws -> [Conversation]
    /// Delete a conversation from local storage by ID.
    func deleteConversation(id: String) throws

    /// Cache an image to disk for offline upload retry. Stored at `{documents}/images/{messageID}.jpg`.
    func saveImage(_ image: UIImage, forMessageID messageID: String)
    /// Load a cached image from disk by message ID.
    func loadImage(forMessageID messageID: String) -> UIImage?
    /// Delete a cached image from disk.
    func deleteImage(forMessageID messageID: String)

    /// Delete all local data (messages, conversations, images). Used on sign-out.
    func clearAll() throws
}
