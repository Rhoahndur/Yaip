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
        print("📤 Starting image upload to path: \(path)")
        
        // Resize and compress image
        print("🖼️ Resizing image...")
        let resizedImage = image.resized(maxDimension: 1024)
        
        print("📦 Compressing image...")
        guard let imageData = resizedImage.compressed(maxSizeKB: 500) else {
            print("❌ Image compression failed")
            throw StorageError.compressionFailed
        }
        print("✅ Image compressed to \(imageData.count) bytes")
        
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        print("⬆️ Uploading to Firebase Storage...")
        // Upload
        do {
            _ = try await ref.putDataAsync(imageData, metadata: metadata)
            print("✅ Upload successful!")
        } catch {
            print("❌ Upload failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
        
        // Get download URL
        print("🔗 Getting download URL...")
        let downloadURL = try await ref.downloadURL()
        print("✅ Image uploaded successfully: \(downloadURL.absoluteString)")
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

