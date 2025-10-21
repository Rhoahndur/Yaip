//
//  StorageService.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseStorage
import UIKit

/// Service for uploading and managing media files in Firebase Storage
class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()
    
    private init() {}
    
    /// Upload image to Firebase Storage
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        // Resize and compress image
        let resizedImage = image.resized(maxDimension: 1024)
        guard let imageData = resizedImage.compressed(maxSizeKB: 500) else {
            throw StorageError.compressionFailed
        }
        
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        
        // Get download URL
        let downloadURL = try await ref.downloadURL()
        return downloadURL.absoluteString
    }
    
    /// Upload profile image
    func uploadProfileImage(_ image: UIImage, userID: String) async throws -> String {
        let path = "profile_images/\(userID)/\(UUID().uuidString).jpg"
        return try await uploadImage(image, path: path)
    }
    
    /// Upload chat message image
    func uploadChatImage(_ image: UIImage, conversationID: String) async throws -> String {
        let path = "chat_images/\(conversationID)/\(UUID().uuidString).jpg"
        return try await uploadImage(image, path: path)
    }
    
    /// Delete image from storage
    func deleteImage(url: String) async throws {
        let ref = storage.reference(forURL: url)
        try await ref.delete()
    }
}

enum StorageError: LocalizedError {
    case compressionFailed
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        }
    }
}

