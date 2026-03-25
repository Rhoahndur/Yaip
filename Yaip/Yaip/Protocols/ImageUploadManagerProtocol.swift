import UIKit

/// Contract for image upload lifecycle management.
///
/// Images follow a three-state lifecycle:
/// 1. `.notStarted` — image not yet cached
/// 2. `.cached(UIImage)` — image cached locally, ready for upload
/// 3. `.uploaded(String)` — uploaded to Firebase Storage, URL available
///
/// On failure, state transitions to `.failed(Error, retryCount)`.
/// Always cache before uploading to enable offline retry.
@MainActor
protocol ImageUploadManagerProtocol: AnyObject {
    /// Current upload state for all tracked images, keyed by message ID.
    var imageStates: [String: ImageUploadManager.ImageState] { get }

    /// Get the current upload state for a specific message's image.
    func getState(for messageID: String) -> ImageUploadManager.ImageState
    /// Cache an image locally before uploading. Required before calling `uploadImage`.
    func cacheImage(_ image: UIImage, for messageID: String)
    /// Upload a cached image to Firebase Storage.
    /// - Returns: The download URL, or `nil` on failure.
    func uploadImage(for messageID: String, conversationID: String) async -> String?
    /// Retry a previously failed upload.
    /// - Returns: The download URL, or `nil` on failure.
    func retryUpload(for messageID: String, conversationID: String) async -> String?
    /// Check if an image is in a state where it can be uploaded (cached or failed).
    func hasUploadableImage(for messageID: String) -> Bool
    /// Retrieve the cached `UIImage` for a message, if available.
    func getCachedImage(for messageID: String) -> UIImage?
    /// Remove all cached data and state for a message's image.
    func cleanup(for messageID: String)
    /// Retry all failed uploads for messages in a conversation.
    /// - Returns: Dictionary mapping message IDs to their new download URLs.
    func retryAllFailed(in conversationID: String, messageIDs: [String]) async -> [String: String]
    /// Check for uploads stuck in `.uploading` state and reset them.
    func checkForStuckUploads()
}
