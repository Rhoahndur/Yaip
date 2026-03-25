import Foundation

/// Reactions, deletion, and reply management.
extension ChatViewModel {

    /// Toggle a reaction emoji on a message using optimistic UI.
    ///
    /// Updates the UI immediately, then syncs to Firestore. If the user already
    /// reacted with this emoji, the reaction is removed; otherwise it's added.
    func toggleReaction(emoji: String, message: Message) async {
        guard let messageID = message.id,
              let conversationID = conversation.id,
              let currentUserID = authManager.currentUserID else {
            print("❌ Missing required IDs for reaction")
            return
        }

        // Optimistic UI update
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            var updatedMessage = messages[index]

            if var users = updatedMessage.reactions[emoji] {
                if users.contains(currentUserID) {
                    users.removeAll { $0 == currentUserID }
                    if users.isEmpty {
                        updatedMessage.reactions.removeValue(forKey: emoji)
                    } else {
                        updatedMessage.reactions[emoji] = users
                    }
                } else {
                    users.append(currentUserID)
                    updatedMessage.reactions[emoji] = users
                }
            } else {
                updatedMessage.reactions[emoji] = [currentUserID]
            }

            messages[index] = updatedMessage
        }

        // Sync to Firestore
        do {
            try await messageService.toggleReaction(
                emoji: emoji,
                messageID: messageID,
                conversationID: conversationID,
                userID: currentUserID
            )
            AnalyticsService.logReactionAdded(emoji: emoji)
        } catch {
            print("❌ Failed to toggle reaction: \(error)")
            errorMessage = L10n.Error.failedToAddReaction
        }
    }

    /// Soft-delete a message using optimistic UI.
    ///
    /// Sets `isDeleted = true` and replaces text immediately, then syncs to Firestore.
    /// Reverts the optimistic update if the Firestore write fails.
    func deleteMessage(_ message: Message) async {
        guard let messageID = message.id,
              let conversationID = conversation.id else {
            return
        }

        // Optimistic UI update
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            messages[index].isDeleted = true
            messages[index].deletedAt = Date()
            messages[index].text = L10n.Chat.messageDeleted
        }

        // Sync to Firestore
        do {
            try await messageService.deleteMessage(
                messageID: messageID,
                conversationID: conversationID
            )
            AnalyticsService.log(.messageDeleted)
        } catch {
            print("❌ Failed to delete message: \(error)")
            errorMessage = L10n.Error.failedToDeleteMessage

            // Revert optimistic update
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].isDeleted = false
                messages[index].deletedAt = nil
            }
        }
    }

    /// Set the message to reply to
    func setReplyTo(_ message: Message) {
        replyingTo = message
    }

    /// Clear the current reply
    func clearReply() {
        replyingTo = nil
    }

    /// Get the message that another message is replying to
    func getReplyToMessage(for message: Message) -> Message? {
        guard let replyToID = message.replyTo else { return nil }
        return messages.first { $0.id == replyToID }
    }
}
