//
//  MessageIndexingService.swift
//  Yaip
//
//  Service for indexing messages into Pinecone vector database via N8N
//  Handles automatic indexing, backfill, and offline resilience
//

import Foundation
import FirebaseFirestore

/// Service for managing message indexing into vector database
@MainActor
class MessageIndexingService {
    static let shared = MessageIndexingService()

    // Load configuration from Info.plist
    private let ingestURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "N8N_WEBHOOK_URL") as? String,
              !url.isEmpty,
              url != "$(N8N_WEBHOOK_URL)" else {
            return "https://rhoahndur.app.n8n.cloud/webhook"
        }
        return url + "/ingest_message"
    }()

    private let authToken: String = {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "N8N_AUTH_TOKEN") as? String,
              !token.isEmpty,
              token != "$(N8N_AUTH_TOKEN)" else {
            return "your_secret_token_here"
        }
        return token
    }()

    private let db = Firestore.firestore()

    // Track indexing operations to avoid duplicates
    private var indexingInProgress = Set<String>()

    // Queue for offline indexing
    private var offlineQueue: [(messageID: String, conversationID: String)] = []

    private init() {
        print("🔧 MessageIndexingService initialized")
        print("   Ingest URL: \(ingestURL)")
    }

    // MARK: - Public API

    /// Index a single message immediately after it's sent
    func indexMessage(messageID: String, conversationID: String) async {
        // Avoid duplicate indexing
        guard !indexingInProgress.contains(messageID) else {
            print("⏭️  Message \(messageID) already being indexed, skipping")
            return
        }

        indexingInProgress.insert(messageID)
        defer { indexingInProgress.remove(messageID) }

        do {
            // Fetch message data from Firestore
            let messageDoc = try await db
                .collection(Constants.Collections.conversations)
                .document(conversationID)
                .collection("messages")
                .document(messageID)
                .getDocument()

            guard let data = messageDoc.data() else {
                print("⚠️  Message \(messageID) not found in Firestore")
                return
            }

            // Extract message fields
            let text = data["text"] as? String ?? ""
            let senderID = data["senderID"] as? String ?? ""
            let senderName = data["senderName"] as? String ?? "Unknown"
            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()

            // Skip if no text (e.g., image-only messages)
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("⏭️  Message \(messageID) has no text, skipping indexing")
                return
            }

            // Send to N8N ingestion webhook
            try await sendToIngestionWebhook(
                messageID: messageID,
                conversationID: conversationID,
                text: text,
                senderID: senderID,
                senderName: senderName,
                timestamp: timestamp
            )

            print("✅ Indexed message \(messageID)")

        } catch {
            print("❌ Failed to index message \(messageID): \(error)")
            // Add to offline queue for retry
            offlineQueue.append((messageID, conversationID))
        }
    }

    /// Backfill all unindexed messages in a conversation
    func backfillConversation(conversationID: String, limit: Int? = nil) async {
        print("🔄 Starting backfill for conversation \(conversationID)")

        do {
            var query: Query = db
                .collection(Constants.Collections.conversations)
                .document(conversationID)
                .collection("messages")
                .order(by: "timestamp", descending: false)

            if let limit = limit {
                query = query.limit(to: limit)
            }

            let snapshot = try await query.getDocuments()
            print("📋 Found \(snapshot.documents.count) messages to backfill")

            var indexed = 0
            var skipped = 0
            var failed = 0

            // Process in batches of 5 with delay to avoid rate limiting
            let batchSize = 5
            for (index, doc) in snapshot.documents.enumerated() {
                let messageID = doc.documentID

                // Skip if already being indexed
                guard !indexingInProgress.contains(messageID) else {
                    skipped += 1
                    continue
                }

                await indexMessage(messageID: messageID, conversationID: conversationID)
                indexed += 1

                // Add delay between batches
                if (index + 1) % batchSize == 0 && index + 1 < snapshot.documents.count {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
                }
            }

            print("✅ Backfill complete: \(indexed) indexed, \(skipped) skipped, \(failed) failed")

        } catch {
            print("❌ Backfill failed for conversation \(conversationID): \(error)")
        }
    }

    /// Backfill all conversations (for initial setup)
    func backfillAllConversations(maxMessagesPerConversation: Int = 100) async {
        print("🚀 Starting full backfill of all conversations")

        do {
            let conversationsSnapshot = try await db
                .collection(Constants.Collections.conversations)
                .getDocuments()

            print("📁 Found \(conversationsSnapshot.documents.count) conversations")

            for convDoc in conversationsSnapshot.documents {
                let conversationID = convDoc.documentID
                await backfillConversation(conversationID: conversationID, limit: maxMessagesPerConversation)

                // Delay between conversations
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }

            print("✨ Full backfill complete")

        } catch {
            print("❌ Full backfill failed: \(error)")
        }
    }

    /// Process offline queue (call this on reconnection)
    func processOfflineQueue() async {
        guard !offlineQueue.isEmpty else {
            print("📭 Offline queue is empty")
            return
        }

        print("📤 Processing \(offlineQueue.count) messages from offline queue")

        let queueCopy = offlineQueue
        offlineQueue.removeAll()

        for (messageID, conversationID) in queueCopy {
            await indexMessage(messageID: messageID, conversationID: conversationID)
        }

        print("✅ Offline queue processed")
    }

    // MARK: - Private Helpers

    /// Send message data to N8N ingestion webhook
    private func sendToIngestionWebhook(
        messageID: String,
        conversationID: String,
        text: String,
        senderID: String,
        senderName: String,
        timestamp: Date
    ) async throws {
        guard let url = URL(string: ingestURL) else {
            throw NSError(domain: "MessageIndexingService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid ingest URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10 // 10 second timeout

        let payload: [String: Any] = [
            "messageID": messageID,
            "conversationID": conversationID,
            "text": text,
            "senderID": senderID,
            "senderName": senderName,
            "timestamp": ISO8601DateFormatter().string(from: timestamp)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "MessageIndexingService", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "MessageIndexingService", code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
    }
}
