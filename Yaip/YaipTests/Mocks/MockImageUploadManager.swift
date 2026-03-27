import UIKit
@testable import Yaip

@MainActor
final class MockImageUploadManager: ImageUploadManagerProtocol {
    var imageStates: [String: ImageUploadManager.ImageState] = [:]
    var cachedImages: [String: UIImage] = [:]
    var uploadedURLs: [String: String] = [:]

    func getState(for messageID: String) -> ImageUploadManager.ImageState {
        imageStates[messageID] ?? .notStarted
    }

    func cacheImage(_ image: UIImage, for messageID: String) {
        cachedImages[messageID] = image
        imageStates[messageID] = .cached(image)
    }

    func uploadImage(for messageID: String, conversationID: String) async -> String? {
        resolveUpload(for: messageID, baseRetryCount: 0)
    }

    func retryUpload(for messageID: String, conversationID: String) async -> String? {
        resolveUpload(for: messageID, baseRetryCount: currentRetryCount(for: messageID) + 1)
    }

    func hasUploadableImage(for messageID: String) -> Bool {
        cachedImages[messageID] != nil
    }

    func getCachedImage(for messageID: String) -> UIImage? {
        cachedImages[messageID]
    }

    func cleanup(for messageID: String) {
        cachedImages.removeValue(forKey: messageID)
        imageStates.removeValue(forKey: messageID)
    }

    func retryAllFailed(in conversationID: String, messageIDs: [String]) async -> [String: String] {
        var results: [String: String] = [:]
        for id in messageIDs {
            if let url = resolveUpload(for: id, baseRetryCount: currentRetryCount(for: id) + 1) {
                results[id] = url
            }
        }
        return results
    }

    func checkForStuckUploads() {}

    // MARK: - Private

    @discardableResult
    private func resolveUpload(for messageID: String, baseRetryCount: Int) -> String? {
        if let url = uploadedURLs[messageID] {
            imageStates[messageID] = .uploaded(url: url)
            return url
        }
        imageStates[messageID] = .failed(error: "Mock upload failed", retryCount: baseRetryCount)
        return nil
    }

    private func currentRetryCount(for messageID: String) -> Int {
        if case .failed(_, let count) = imageStates[messageID] {
            return count
        }
        return 0
    }
}
