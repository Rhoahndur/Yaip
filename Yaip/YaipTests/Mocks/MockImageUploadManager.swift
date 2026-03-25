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
        if let url = uploadedURLs[messageID] {
            imageStates[messageID] = .uploaded(url: url)
            return url
        }
        imageStates[messageID] = .failed(error: "Mock upload failed", retryCount: 0)
        return nil
    }

    func retryUpload(for messageID: String, conversationID: String) async -> String? {
        uploadedURLs[messageID]
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
            if let url = uploadedURLs[id] { results[id] = url }
        }
        return results
    }

    func checkForStuckUploads() {}
}
