//
//  LocalStorageManager.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import SwiftData
import UIKit

/// Manager for local persistence using SwiftData
@MainActor
class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private var modelContainer: ModelContainer
    private var modelContext: ModelContext
    
    private init() {
        do {
            let schema = Schema([
                LocalMessage.self,
                LocalConversation.self
            ])
            
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Messages
    
    /// Save message locally
    func saveMessage(_ message: Message) throws {
        let localMessage = LocalMessage(from: message)
        modelContext.insert(localMessage)
        try modelContext.save()
    }
    
    /// Fetch local messages for conversation
    func fetchMessages(conversationID: String) throws -> [Message] {
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { $0.conversationID == conversationID },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        
        let localMessages = try modelContext.fetch(descriptor)
        return localMessages.map { $0.toMessage() }
    }
    
    /// Delete message locally
    func deleteMessage(id: String) throws {
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { $0.id == id }
        )
        
        if let localMessage = try modelContext.fetch(descriptor).first {
            modelContext.delete(localMessage)
            try modelContext.save()
        }
    }
    
    /// Get pending messages (not synced)
    func getPendingMessages() throws -> [Message] {
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { !$0.isSynced }
        )
        
        let localMessages = try modelContext.fetch(descriptor)
        return localMessages.map { $0.toMessage() }
    }
    
    /// Mark message as synced
    func markMessageSynced(id: String) throws {
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { $0.id == id }
        )
        
        if let localMessage = try modelContext.fetch(descriptor).first {
            localMessage.isSynced = true
            try modelContext.save()
        }
    }
    
    // MARK: - Conversations
    
    /// Save conversation locally
    func saveConversation(_ conversation: Conversation) throws {
        let localConversation = LocalConversation(from: conversation)
        modelContext.insert(localConversation)
        try modelContext.save()
    }
    
    /// Fetch local conversations
    func fetchConversations() throws -> [Conversation] {
        let descriptor = FetchDescriptor<LocalConversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        let localConversations = try modelContext.fetch(descriptor)
        return localConversations.map { $0.toConversation() }
    }
    
    /// Delete conversation locally
    func deleteConversation(id: String) throws {
        let descriptor = FetchDescriptor<LocalConversation>(
            predicate: #Predicate { $0.id == id }
        )
        
        if let localConversation = try modelContext.fetch(descriptor).first {
            modelContext.delete(localConversation)
            try modelContext.save()
        }
    }
    
    // MARK: - Image Caching
    
    /// Save image locally for later upload
    func saveImage(_ image: UIImage, forMessageID messageID: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to data")
            return
        }
        
        let fileURL = getImageCacheURL(forMessageID: messageID)
        
        do {
            try imageData.write(to: fileURL)
            print("✅ Cached image for message: \(messageID)")
        } catch {
            print("❌ Failed to cache image: \(error.localizedDescription)")
        }
    }
    
    /// Load cached image for message
    func loadImage(forMessageID messageID: String) -> UIImage? {
        let fileURL = getImageCacheURL(forMessageID: messageID)
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    /// Delete cached image
    func deleteImage(forMessageID messageID: String) {
        let fileURL = getImageCacheURL(forMessageID: messageID)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    /// Get file URL for cached image
    private func getImageCacheURL(forMessageID messageID: String) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let imageDir = cacheDir.appendingPathComponent("PendingImages", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: imageDir.path) {
            try? FileManager.default.createDirectory(at: imageDir, withIntermediateDirectories: true)
        }
        
        return imageDir.appendingPathComponent("\(messageID).jpg")
    }
    
    // MARK: - Cleanup
    
    /// Clear all local data
    func clearAll() throws {
        try modelContext.delete(model: LocalMessage.self)
        try modelContext.delete(model: LocalConversation.self)
        try modelContext.save()
        
        // Clear image cache
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let imageDir = cacheDir.appendingPathComponent("PendingImages", isDirectory: true)
        try? FileManager.default.removeItem(at: imageDir)
    }
}

// MARK: - SwiftData Models

@Model
final class LocalMessage {
    @Attribute(.unique) var id: String
    var conversationID: String
    var senderID: String
    var text: String?
    var mediaURL: String?
    var mediaType: String?
    var timestamp: Date
    var status: String
    var readBy: [String]
    var isSynced: Bool
    
    init(id: String, conversationID: String, senderID: String, text: String?, mediaURL: String?, mediaType: String?, timestamp: Date, status: String, readBy: [String], isSynced: Bool) {
        self.id = id
        self.conversationID = conversationID
        self.senderID = senderID
        self.text = text
        self.mediaURL = mediaURL
        self.mediaType = mediaType
        self.timestamp = timestamp
        self.status = status
        self.readBy = readBy
        self.isSynced = isSynced
    }
    
    convenience init(from message: Message) {
        self.init(
            id: message.id ?? UUID().uuidString,
            conversationID: message.conversationID,
            senderID: message.senderID,
            text: message.text,
            mediaURL: message.mediaURL,
            mediaType: message.mediaType?.rawValue,
            timestamp: message.timestamp,
            status: message.status.rawValue,
            readBy: message.readBy,
            isSynced: true
        )
    }
    
    func toMessage() -> Message {
        var message = Message(
            id: nil,
            conversationID: conversationID,
            senderID: senderID,
            text: text,
            mediaURL: mediaURL,
            mediaType: mediaType != nil ? MediaType(rawValue: mediaType!) : nil,
            timestamp: timestamp,
            status: MessageStatus(rawValue: status) ?? .sent,
            readBy: readBy
        )
        message.id = id
        return message
    }
}

@Model
final class LocalConversation {
    @Attribute(.unique) var id: String
    var type: String
    var participants: [String]
    var name: String?
    var imageURL: String?
    var lastMessageText: String?
    var lastMessageSenderID: String?
    var lastMessageTimestamp: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String, type: String, participants: [String], name: String?, imageURL: String?, lastMessageText: String?, lastMessageSenderID: String?, lastMessageTimestamp: Date?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.type = type
        self.participants = participants
        self.name = name
        self.imageURL = imageURL
        self.lastMessageText = lastMessageText
        self.lastMessageSenderID = lastMessageSenderID
        self.lastMessageTimestamp = lastMessageTimestamp
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    convenience init(from conversation: Conversation) {
        self.init(
            id: conversation.id ?? UUID().uuidString,
            type: conversation.type.rawValue,
            participants: conversation.participants,
            name: conversation.name,
            imageURL: conversation.imageURL,
            lastMessageText: conversation.lastMessage?.text,
            lastMessageSenderID: conversation.lastMessage?.senderID,
            lastMessageTimestamp: conversation.lastMessage?.timestamp,
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt
        )
    }
    
    func toConversation() -> Conversation {
        var conversation = Conversation(
            id: nil,
            type: ConversationType(rawValue: type) ?? .oneOnOne,
            participants: participants,
            name: name,
            imageURL: imageURL,
            lastMessage: lastMessageText != nil && lastMessageSenderID != nil && lastMessageTimestamp != nil
                ? LastMessage(text: lastMessageText!, senderID: lastMessageSenderID!, timestamp: lastMessageTimestamp!)
                : nil,
            createdAt: createdAt,
            updatedAt: updatedAt,
            unreadCount: [:]
        )
        conversation.id = id
        return conversation
    }
}

