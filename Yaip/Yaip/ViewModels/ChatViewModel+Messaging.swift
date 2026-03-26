import Foundation
import FirebaseFirestore

/// Message sending, retry, merge, listening, and read receipt logic.
extension ChatViewModel {

    /// Start listening to messages
    func startListening() {
        guard let conversationID = conversation.id else { return }

        isLoading = true

        // Load from local storage first
        Task {
            do {
                let localMessages = try localStorage.fetchMessages(conversationID: conversationID)
                self.messages = localMessages
            } catch {
                print("Error loading local messages: \(error)")
            }
        }

        // Listen to conversation updates (name, participants, etc.)
        setupConversationListener()

        // Listen to messages
        let msgListener = messageService.listenToMessages(conversationID: conversationID) { [weak self] firestoreMessages in
            Task { @MainActor in
                guard let self = self else { return }
                self.mergeMessages(firestoreMessages: firestoreMessages)
            }
        }
        listenerBag.store(msgListener, key: "messages")

        // Listen to typing indicator for other user
        if conversation.type == .oneOnOne,
           let currentUserID = authManager.currentUserID,
           let otherUserID = conversation.participants.first(where: { $0 != currentUserID }) {

            let typListener = messageService.listenToTypingStatus(
                conversationID: conversationID,
                otherUserID: otherUserID
            ) { [weak self] isTyping in
                Task { @MainActor in
                    self?.otherUserIsTyping = isTyping
                }
            }
            listenerBag.store(typListener, key: "typing")
        }
    }

    /// Stop listening to messages
    func stopListening() {
        listenerBag.removeAll()
    }

    /// Lifecycle-aware merge of Firestore messages with local state.
    ///
    /// Merge strategy:
    /// - Messages in local states (`.staged`, `.sending`, `.failed`) are preserved over Firestore versions,
    ///   because the local version has the most up-to-date lifecycle info.
    /// - Messages in synced states (`.sent`, `.delivered`, `.read`) use the Firestore version as source of truth.
    /// - Local-only messages (not yet in Firestore) are appended if still in a local state.
    /// - Result is sorted by timestamp ascending.
    ///
    /// Also triggers auto-retry for pending messages and auto-marks new messages as read.
    func mergeMessages(firestoreMessages: [Message]) {
        let oldMessages = self.messages

        var mergedMessages: [Message] = []
        let firestoreIDs = Set(firestoreMessages.compactMap { $0.id })

        // Create lookup dictionary for local messages
        var localByID: [String: Message] = [:]
        for msg in oldMessages {
            if let id = msg.id {
                localByID[id] = msg
            }
        }

        // Add Firestore messages (but respect local states)
        for firestoreMsg in firestoreMessages {
            guard let id = firestoreMsg.id else { continue }

            if let localMsg = localByID[id] {
                // Keep local version if it's in a local state (.staged, .sending, .failed)
                if localMsg.status.isLocal {
                    mergedMessages.append(localMsg)
                    continue
                }
                // For synced states, use Firestore version (source of truth)
                mergedMessages.append(firestoreMsg)
                continue
            }

            mergedMessages.append(firestoreMsg)
        }

        // Keep local messages that aren't in Firestore yet
        let localOnlyMessages = oldMessages.filter { localMsg in
            guard let id = localMsg.id else { return false }
            return !firestoreIDs.contains(id) && localMsg.status.isLocal
        }
        mergedMessages.append(contentsOf: localOnlyMessages)

        // Sort by timestamp
        mergedMessages.sort { $0.timestamp < $1.timestamp }

        self.messages = mergedMessages
        self.isLoading = false

        // Auto-retry pending messages if we're online
        let pendingCount = mergedMessages.filter { $0.status.isLocal }.count
        if pendingCount > 0 && self.networkMonitor.isConnected {
            print("🔄 Auto-retrying \(pendingCount) pending messages...")
            Task {
                await self.retryAllFailedMessages()
            }
        }

        // If we received messages but NetworkMonitor thinks we're offline, force a check
        if !firestoreMessages.isEmpty && !self.networkMonitor.isConnected {
            print("⚠️ Received messages but NetworkMonitor thinks offline - forcing check")
            self.networkMonitor.checkConnectionNow()
        }

        // Save Firestore messages to local storage
        for message in firestoreMessages {
            if message.mediaType == .image {
                print("📥 Received image message from Firestore:")
            }

            try? self.localStorage.saveMessage(message)
            if message.mediaURL != nil, let id = message.id {
                self.localStorage.deleteImage(forMessageID: id)
            }
        }

        // Auto-mark new unread messages as read
        guard let userID = self.authManager.currentUserID else { return }

        let newMessages = firestoreMessages.filter { newMsg in
            !oldMessages.contains(where: { $0.id == newMsg.id })
        }

        let unreadFromOthers = newMessages.filter { msg in
            msg.senderID != userID && !msg.readBy.contains(userID)
        }

        if !unreadFromOthers.isEmpty {
            print("📖 Auto-marking \(unreadFromOthers.count) new messages as read")
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                await MainActor.run {
                    self.markAsRead()
                }
            }
        }
    }

    /// Send a message through the full lifecycle: staged → sending → sent.
    ///
    /// Lifecycle stages:
    /// 1. **Staged**: Message created locally, added to UI optimistically, saved to SwiftData.
    /// 2. **Image upload** (if present): Image cached locally, then uploaded to Firebase Storage.
    /// 3. **Sending**: Message sent to Firestore. Firebase SDK handles offline queuing.
    /// 4. **Sent**: Firestore write confirmed. Local storage marked as synced.
    /// 5. **Indexing**: Message indexed into vector database for AI search.
    ///
    /// On failure at any stage, message status is set to `.failed` for retry.
    /// - Important: Never blocks on network status — follows the optimistic network approach.
    func sendMessage() async {
        guard let currentUserID = authManager.currentUserID,
              let conversationID = conversation.id else {
            return
        }

        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = selectedImage

        guard !text.isEmpty || image != nil else { return }

        // Clear inputs immediately
        messageText = ""
        selectedImage = nil

        // Stop typing indicator (non-blocking)
        Task {
            await updateTypingStatus(false)
        }

        // STAGE 1: Create message in .staged state
        let messageID = UUID().uuidString
        var newMessage = Message(
            id: nil,
            conversationID: conversationID,
            senderID: currentUserID,
            text: text.isEmpty ? nil : text,
            mediaURL: nil,
            mediaType: image != nil ? .image : nil,
            timestamp: Date(),
            status: .staged,
            readBy: [currentUserID]
        )
        newMessage.id = messageID

        // Add to UI immediately (optimistic)
        messages.append(newMessage)

        do {
            try localStorage.saveMessage(newMessage)
        } catch {
            AppLogger.logSilentFailure(error, context: "saveMessage(staged)", category: .storage)
        }

        // STAGE 2: Handle image upload (if present)
        var mediaURL: String?
        if let image = image {
            imageUploadManager.cacheImage(image, for: messageID)
            print("💾 Image cached for message: \(messageID)")

            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .sending
            }

            mediaURL = await imageUploadManager.uploadImage(for: messageID, conversationID: conversationID)

            if let url = mediaURL {
                if let index = messages.firstIndex(where: { $0.id == messageID }) {
                    messages[index].mediaURL = url
                    newMessage.mediaURL = url
                    do {
                        try localStorage.saveMessage(messages[index])
                    } catch {
                        AppLogger.logSilentFailure(error, context: "saveMessage(imageURL)", category: .storage)
                    }
                    print("✅ Image URL assigned to message: \(url)")
                }
            } else {
                print("⚠️ Image upload failed - staying in .staged state for retry")
                if let index = messages.firstIndex(where: { $0.id == messageID }) {
                    messages[index].status = .staged
                }
                if text.isEmpty {
                    return
                }
            }
        }

        // STAGE 3: Send to Firestore (optimistic approach)
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            if messages[index].status != .sending {
                messages[index].status = .sending
            }
        }

        do {
            try await messageService.sendMessage(newMessage)

            // STAGE 4: Mark as sent
            AnalyticsService.logMessageSent(conversationID: conversationID, hasImage: image != nil)

            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .sent
                do {
                    try localStorage.markMessageSynced(id: messageID)
                } catch {
                    AppLogger.logSilentFailure(error, context: "markMessageSynced(send)", category: .sync)
                }
            }

            // STAGE 5: Index message into vector database
            Task {
                await MessageIndexingService.shared.indexMessage(
                    messageID: messageID,
                    conversationID: conversationID
                )
            }

            if !networkMonitor.isConnected {
                print("⚠️ Message sent successfully but NetworkMonitor thinks offline - forcing check")
                networkMonitor.checkConnectionNow()
            }

            try await updateConversationAfterSend(
                conversationID: conversationID,
                text: text,
                currentUserID: currentUserID
            )

        } catch {
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .failed
            }
        }
    }

    /// Retry sending a failed or stuck message.
    ///
    /// Handles image re-upload if the image was cached but not yet uploaded.
    /// Only retries messages in `.failed`, `.staged`, or stuck `.sending` (image with no URL) states.
    func retryMessage(_ message: Message) async {
        guard let messageID = message.id,
              let index = messages.firstIndex(where: { $0.id == messageID }),
              let conversationID = conversation.id,
              let currentUserID = authManager.currentUserID else {
            return
        }

        guard message.status.isRetryable || message.status == .staged ||
              (message.status == .sending && message.mediaType == .image && message.mediaURL == nil) else {
            return
        }

        messages[index].status = .sending
        var updatedMessage = messages[index]

        // Handle image upload via ImageUploadManager
        if updatedMessage.mediaType == .image && updatedMessage.mediaURL == nil {
            let imageState = imageUploadManager.getState(for: messageID)

            var mediaURL: String?

            switch imageState {
            case .cached, .notStarted:
                if let cachedImage = imageUploadManager.getCachedImage(for: messageID) {
                    imageUploadManager.cacheImage(cachedImage, for: messageID)
                    mediaURL = await imageUploadManager.uploadImage(for: messageID, conversationID: conversationID)
                }
            case .failed:
                mediaURL = await imageUploadManager.retryUpload(for: messageID, conversationID: conversationID)
            default:
                break
            }

            if let url = mediaURL {
                updatedMessage.mediaURL = url
                if let currentIndex = messages.firstIndex(where: { $0.id == messageID }) {
                    messages[currentIndex].mediaURL = mediaURL
                }
            } else {
                if let currentIndex = messages.firstIndex(where: { $0.id == messageID }) {
                    messages[currentIndex].status = .failed
                }
                return
            }
        }

        // Send to Firestore
        do {
            try await messageService.sendMessage(updatedMessage)

            if let currentIndex = messages.firstIndex(where: { $0.id == messageID }) {
                messages[currentIndex].status = .sent
            }
            AnalyticsService.logMessageRetried(conversationID: conversationID)
            do {
                try localStorage.markMessageSynced(id: messageID)
            } catch {
                AppLogger.logSilentFailure(error, context: "markMessageSynced(retry)", category: .sync)
            }

            let lastMessageText = updatedMessage.text ?? "📷 Photo"
            let lastMessage = LastMessage(
                text: lastMessageText,
                senderID: currentUserID,
                timestamp: updatedMessage.timestamp
            )
            try await conversationService.updateLastMessage(
                conversationID: conversationID,
                lastMessage: lastMessage
            )

        } catch {
            if let currentIndex = messages.firstIndex(where: { $0.id == messageID }) {
                messages[currentIndex].status = .failed
            }
        }
    }

    /// Retry all failed and pending messages in this conversation.
    ///
    /// Called automatically on network reconnection and when the view appears.
    /// Skips retry if not connected. Limits image upload retries to 2 attempts.
    func retryAllFailedMessages() async {
        guard networkMonitor.isConnected else { return }

        let messagesToRetry = messages.filter { message in
            if message.status == .staged { return true }

            if message.status.isRetryable {
                if let messageID = message.id,
                   case .failed(_, let retryCount) = imageUploadManager.getState(for: messageID) {
                    return retryCount < 2
                }
                return true
            }

            if message.status == .sending && message.mediaType == .image && message.mediaURL == nil {
                return true
            }

            return false
        }

        for message in messagesToRetry {
            await retryMessage(message)
        }
    }

    /// Mark all messages as read
    func markAsRead() {
        guard let currentUserID = authManager.currentUserID,
              let conversationID = conversation.id else {
            return
        }

        Task {
            let unreadMessageIDs = messages
                .filter { !$0.readBy.contains(currentUserID) }
                .compactMap { $0.id }

            guard !unreadMessageIDs.isEmpty else {
                print("📖 No unread messages to mark")
                do {
                    try await conversationService.markAsRead(
                        conversationID: conversationID,
                        userID: currentUserID
                    )
                } catch {
                    AppLogger.logSilentFailure(error, context: "markAsRead(reset)", category: .messages)
                }
                return
            }

            do {
                try await messageService.markMessagesAsRead(
                    conversationID: conversationID,
                    messageIDs: unreadMessageIDs,
                    userID: currentUserID
                )

                try await conversationService.markAsRead(
                    conversationID: conversationID,
                    userID: currentUserID
                )

                await MainActor.run {
                    for id in unreadMessageIDs {
                        if let index = self.messages.firstIndex(where: { $0.id == id }) {
                            if !self.messages[index].readBy.contains(currentUserID) {
                                self.messages[index].readBy.append(currentUserID)
                            }
                            if self.messages[index].status.isSynced {
                                self.messages[index].status = .read
                            }
                        }
                    }
                }

                print("✅ Successfully marked messages as read")
            } catch {
                print("❌ Error marking messages as read: \(error.localizedDescription)")
            }
        }
    }

    /// Setup listener for conversation updates (name, participants, etc.)
    func setupConversationListener() {
        guard let conversationID = conversation.id else { return }

        let convListener = Firestore.firestore()
            .collection(Constants.Collections.conversations)
            .document(conversationID)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                Task { @MainActor in
                    guard let self = self else { return }

                    if let error = error {
                        print("❌ Error listening to conversation updates: \(error)")
                        return
                    }

                    guard let document = documentSnapshot,
                          document.exists,
                          let data = document.data() else {
                        print("⚠️ Conversation document doesn't exist")
                        return
                    }

                    let name = data["name"] as? String
                    let participants = data["participants"] as? [String] ?? self.conversation.participants
                    let imageURL = data["imageURL"] as? String
                    let type = (data["type"] as? String).flatMap { ConversationType(rawValue: $0) } ?? self.conversation.type

                    self.conversation = Conversation(
                        id: conversationID,
                        type: type,
                        participants: participants,
                        name: name,
                        imageURL: imageURL,
                        lastMessage: self.conversation.lastMessage,
                        createdAt: self.conversation.createdAt,
                        updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        unreadCount: self.conversation.unreadCount
                    )

                    print("✅ Conversation updated: name=\(name ?? "nil"), participants=\(participants.count)")

                    if type == .group {
                        await self.loadParticipantNames()
                    }
                }
            }
        listenerBag.store(convListener, key: "conversation")
    }

    /// Update conversation metadata after successfully sending a message.
    private func updateConversationAfterSend(
        conversationID: String,
        text: String,
        currentUserID: String
    ) async throws {
        let lastMessageText = text.isEmpty ? "📷 Photo" : text
        let lastMessage = LastMessage(
            text: lastMessageText,
            senderID: currentUserID,
            timestamp: Date()
        )
        try await conversationService.updateLastMessage(
            conversationID: conversationID,
            lastMessage: lastMessage
        )

        let otherParticipants = conversation.participants.filter { $0 != currentUserID }
        if !otherParticipants.isEmpty {
            do {
                try await conversationService.incrementUnreadCount(
                    conversationID: conversationID,
                    for: otherParticipants
                )
            } catch {
                AppLogger.logSilentFailure(error, context: "incrementUnreadCount", category: .messages)
            }
        }
    }
}
