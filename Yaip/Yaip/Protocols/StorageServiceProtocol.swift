import UIKit

/// Contract for Firebase Storage image operations.
protocol StorageServiceProtocol {
    /// Upload an image to a custom path.
    /// - Returns: The download URL string for the uploaded image.
    func uploadImage(_ image: UIImage, path: String) async throws -> String

    /// Upload a profile image for a user. Stored at `profile_images/{userID}`.
    /// - Returns: The download URL string.
    func uploadProfileImage(_ image: UIImage, userID: String) async throws -> String

    /// Upload a chat image for a conversation. Stored at `chat_images/{conversationID}/{uuid}`.
    /// - Returns: The download URL string.
    func uploadChatImage(_ image: UIImage, conversationID: String) async throws -> String

    /// Delete an image from Firebase Storage by its download URL.
    func deleteImage(url: String) async throws
}
