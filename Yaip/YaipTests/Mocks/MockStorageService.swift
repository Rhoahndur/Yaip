import UIKit
@testable import Yaip

final class MockStorageService: StorageServiceProtocol {
    var uploadedImages: [(image: UIImage, path: String)] = []
    var shouldFail = false
    var uploadedURL = "https://example.com/mock-image.jpg"

    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        if shouldFail { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"]) }
        uploadedImages.append((image, path))
        return uploadedURL
    }

    func uploadProfileImage(_ image: UIImage, userID: String) async throws -> String {
        try await uploadImage(image, path: "profile_images/\(userID)/\(UUID().uuidString).jpg")
    }

    func uploadChatImage(_ image: UIImage, conversationID: String) async throws -> String {
        try await uploadImage(image, path: "chat_images/\(conversationID)/\(UUID().uuidString).jpg")
    }

    func deleteImage(url: String) async throws {
        if shouldFail { throw NSError(domain: "Test", code: 1) }
    }
}
