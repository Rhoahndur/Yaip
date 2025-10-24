//
//  MessageService.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore
import Combine

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
        
        // Create a copy with status set to .sent (it's now on the server)
        var messageToSave = message
        messageToSave.status = .sent
        
        print("💾 Saving message to Firestore with status: .sent")
        
        try db.collection(Constants.Collections.conversations)
            .document(conversationID)
            .collection(Constants.Collections.messages)
            .document(messageID)
            .setData(from: messageToSave)
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
        // Get conversation to know how many participants
        let conversationDoc = try await db.collection(Constants.Collections.conversations)
            .document(conversationID)
            .getDocument()
        
        guard let conversationData = conversationDoc.data(),
              let participants = conversationData["participants"] as? [String] else {
            print("⚠️ Could not get conversation participants")
            return
        }
        
        let batch = db.batch()
        
        for messageID in messageIDs {
            let messageRef = db.collection(Constants.Collections.conversations)
                .document(conversationID)
                .collection(Constants.Collections.messages)
                .document(messageID)
            
            // Get current message to check sender and readBy
            let messageDoc = try await messageRef.getDocument()
            guard let messageData = messageDoc.data(),
                  let senderID = messageData["senderID"] as? String else {
                continue
            }
            
            let currentReadBy = (messageData["readBy"] as? [String]) ?? []
            
            // Add current user to readBy
            var newReadBy = currentReadBy
            if !newReadBy.contains(userID) {
                newReadBy.append(userID)
            }
            
            // Determine new status based on who has read it
            let newStatus: MessageStatus
            
            // Count how many participants (excluding sender) have read it
            let nonSenderParticipants = participants.filter { $0 != senderID }
            let nonSenderReaders = newReadBy.filter { $0 != senderID }
            
            if nonSenderReaders.count >= nonSenderParticipants.count {
                // Everyone (except sender) has read it
                newStatus = .read
            } else if !newReadBy.isEmpty && newReadBy.contains(where: { $0 != senderID }) {
                // At least one person (not sender) has seen it
                newStatus = .delivered
            } else {
                // Keep current status
                let currentStatus = messageData["status"] as? String ?? MessageStatus.sent.rawValue
                newStatus = MessageStatus(rawValue: currentStatus) ?? .sent
            }
            
            print("📖 Marking message \(messageID) as read by \(userID)")
            print("   ReadBy: \(newReadBy.count)/\(participants.count) participants")
            print("   Status: \(newStatus)")
            
            batch.updateData([
                "readBy": FieldValue.arrayUnion([userID]),
                "status": newStatus.rawValue
            ], forDocument: messageRef)
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

