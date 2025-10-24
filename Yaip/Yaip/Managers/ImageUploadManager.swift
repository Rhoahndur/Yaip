//
//  ImageUploadManager.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/23/25.
//

import Foundation
import UIKit
import Combine

/// Manages image upload lifecycle with a proper state machine
/// Prevents race conditions and provides a single source of truth for image states
@MainActor
class ImageUploadManager: ObservableObject {
    static let shared = ImageUploadManager()
    
    /// Image upload state for each message
    enum ImageState: Equatable {
        case notStarted
        case cached(UIImage)                    // Image saved locally, ready to upload
        case uploading(progress: Double)        // Uploading to Firebase Storage
        case uploaded(url: String)              // Successfully uploaded
        case failed(error: String, retryCount: Int) // Failed (retryable)
        
        var isRetryable: Bool {
            if case .failed = self { return true }
            return false
        }
        
        var isFinal: Bool {
            if case .uploaded = self { return true }
            return false
        }
    }
    
    /// Track state for each message ID
    @Published private(set) var imageStates: [String: ImageState] = [:]
    
    private let localStorage = LocalStorageManager.shared
    private let storageService = StorageService.shared
    private let networkMonitor = NetworkMonitor.shared
    
    // Track active uploads to prevent duplicates
    private var activeUploads: Set<String> = []
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get current state for a message
    func getState(for messageID: String) -> ImageState {
        return imageStates[messageID] ?? .notStarted
    }
    
    /// Cache image locally and return the state
    func cacheImage(_ image: UIImage, for messageID: String) {
        // Save to disk
        localStorage.saveImage(image, forMessageID: messageID)
        
        // Update state
        imageStates[messageID] = .cached(image)
    }
    
    /// Upload image to Firebase Storage
    /// Returns the uploaded URL or nil if failed
    /// Uses optimistic approach - tries upload regardless of network status
    func uploadImage(for messageID: String, conversationID: String) async -> String? {
        // Check if already uploading
        guard !activeUploads.contains(messageID) else {
            print("   ⏸️ Upload already in progress")
            return nil
        }
        
        // OPTIMISTIC: Try upload regardless of network status
        // Firebase Storage SDK will handle offline behavior better than our check
        if !networkMonitor.isConnected {
            print("   ⚠️ NetworkMonitor says offline, but trying upload anyway...")
        }
        
        // Get cached image
        guard case .cached(let image) = imageStates[messageID] else {
            // Try to load from disk if not in memory
            if let diskImage = localStorage.loadImage(forMessageID: messageID) {
                imageStates[messageID] = .cached(diskImage)
                return await uploadImage(for: messageID, conversationID: conversationID)
            }
            
            return nil
        }
        
        // Mark as uploading
        activeUploads.insert(messageID)
        imageStates[messageID] = .uploading(progress: 0.0)
        
        do {
            // Upload to Firebase Storage
            let url = try await storageService.uploadChatImage(image, conversationID: conversationID)
            
            // Update state to uploaded
            imageStates[messageID] = .uploaded(url: url)
            
            // Clean up
            activeUploads.remove(messageID)
            
            // Delete local cache after successful upload
            localStorage.deleteImage(forMessageID: messageID)
            
            return url
            
        } catch {
            // Get current retry count
            let retryCount: Int
            if case .failed(_, let count) = imageStates[messageID] {
                retryCount = count + 1
            } else {
                retryCount = 1
            }
            
            // Update state to failed
            imageStates[messageID] = .failed(error: error.localizedDescription, retryCount: retryCount)
            
            // Clean up
            activeUploads.remove(messageID)
            
            return nil
        }
    }
    
    /// Retry a failed upload (max 3 attempts)
    func retryUpload(for messageID: String, conversationID: String) async -> String? {
        guard case .failed(_, let retryCount) = imageStates[messageID] else {
            return nil
        }
        
        // Max 3 retries
        guard retryCount < 3 else {
            return nil
        }
        
        // Try to load cached image from disk
        if let diskImage = localStorage.loadImage(forMessageID: messageID) {
            imageStates[messageID] = .cached(diskImage)
            return await uploadImage(for: messageID, conversationID: conversationID)
        } else {
            return nil
        }
    }
    
    /// Check if message has an uploadable image
    func hasUploadableImage(for messageID: String) -> Bool {
        let state = getState(for: messageID)
        switch state {
        case .cached, .failed:
            return true
        default:
            return false
        }
    }
    
    /// Get cached image (from memory or disk)
    func getCachedImage(for messageID: String) -> UIImage? {
        // Check memory first
        if case .cached(let image) = imageStates[messageID] {
            return image
        }
        
        // Check disk
        if let diskImage = localStorage.loadImage(forMessageID: messageID) {
            return diskImage
        }
        
        return nil
    }
    
    /// Clean up completed or abandoned uploads
    func cleanup(for messageID: String) {
        // Remove from state tracking
        imageStates.removeValue(forKey: messageID)
        
        // Remove from active uploads
        activeUploads.remove(messageID)
        
        // Delete local cache
        localStorage.deleteImage(forMessageID: messageID)
    }
    
    /// Retry all failed uploads for a conversation
    func retryAllFailed(in conversationID: String, messageIDs: [String]) async -> [String: String] {
        var uploadedURLs: [String: String] = [:]
        
        for messageID in messageIDs {
            if case .failed = imageStates[messageID] {
                if let url = await retryUpload(for: messageID, conversationID: conversationID) {
                    uploadedURLs[messageID] = url
                }
            }
        }
        
        return uploadedURLs
    }
    
    /// Check for stuck uploads and mark as failed
    func checkForStuckUploads() {
        for (messageID, state) in imageStates {
            if case .uploading = state {
                // If actively uploading but not in activeUploads, it's stuck
                if !activeUploads.contains(messageID) {
                    imageStates[messageID] = .failed(error: "Upload timed out", retryCount: 0)
                }
            }
        }
    }
}

