//
//  MessageService.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore

/// Service for managing messages in Firestore
class MessageService {
    static let shared = MessageService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Send a message
    func sendMessage(_ message: Message) async throws {
        guard let conversationID = message.conversationID as String?,
              let messageID = message.id else {
            throw MessageError.invalidData
        }
        
        try db.collection(Constants.Collections.conversations)
            .document(conversationID)
            .collection(Constants.Collections.messages)
            .document(messageID)
            .setData(from: message)
    }
    
    /// Fetch messages for a conversation
    func fetchMessages(conversationID: String, limit: Int = 50) async throws -> [Message] {
        let snapshot = try await db.collection(Constants.Collections.conversations)
            .document(conversationID)
            .collection(Constants.Collections.messages)
            .order(by: "timestamp", descending: false)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Message.self)
        }
    }
    
    /// Listen to messages in real-time
    func listenToMessages(conversationID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        return db.collection(Constants.Collections.conversations)
            .document(conversationID)
            .collection(Constants.Collections.messages)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown")")
                    completion([])
                    return
                }
                
                let messages = documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }
                completion(messages)
            }
    }
    
    /// Mark messages as read
    func markMessagesAsRead(conversationID: String, messageIDs: [String], userID: String) async throws {
        let batch = db.batch()
        
        for messageID in messageIDs {
            let ref = db.collection(Constants.Collections.conversations)
                .document(conversationID)
                .collection(Constants.Collections.messages)
                .document(messageID)
            
            batch.updateData([
                "readBy": FieldValue.arrayUnion([userID]),
                "status": MessageStatus.read.rawValue
            ], forDocument: ref)
        }
        
        try await batch.commit()
    }
    
    /// Get read status for a message
    func getReadReceipts(conversationID: String, messageID: String) async throws -> [String: Date] {
        let doc = try await db.collection(Constants.Collections.conversations)
            .document(conversationID)
            .collection(Constants.Collections.messages)
            .document(messageID)
            .getDocument()
        
        guard let data = doc.data() else {
            return [:]
        }
        
        var receipts: [String: Date] = [:]
        
        if let readBy = data["readBy"] as? [String] {
            // For now, just mark them all as read at message timestamp
            // In future, store actual read timestamps
            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            for userID in readBy {
                receipts[userID] = timestamp
            }
        }
        
        return receipts
    }
    
    /// Update typing status
    func updateTypingStatus(conversationID: String, userID: String, isTyping: Bool) async throws {
        try await db.collection(Constants.Collections.conversations)
            .document(conversationID)
            .collection("presence")
            .document(userID)
            .setData([
                "isTyping": isTyping,
                "timestamp": Timestamp(date: Date())
            ])
    }
    
    /// Listen to typing status
    func listenToTypingStatus(conversationID: String, otherUserID: String, completion: @escaping (Bool) -> Void) -> ListenerRegistration {
        return db.collection(Constants.Collections.conversations)
            .document(conversationID)
            .collection("presence")
            .document(otherUserID)
            .addSnapshotListener { snapshot, _ in
                guard let data = snapshot?.data(),
                      let isTyping = data["isTyping"] as? Bool else {
                    completion(false)
                    return
                }
                completion(isTyping)
            }
    }
}

enum MessageError: LocalizedError {
    case invalidData
    case sendFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid message data"
        case .sendFailed:
            return "Failed to send message"
        }
    }
}

