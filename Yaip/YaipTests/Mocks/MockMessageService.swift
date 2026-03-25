import Foundation
import FirebaseFirestore
@testable import Yaip

final class MockMessageService: MessageServiceProtocol {
    var sentMessages: [Message] = []
    var shouldFail = false
    var fetchedMessages: [Message] = []
    var markedReadIDs: [(conversationID: String, messageIDs: [String], userID: String)] = []
    var deletedMessages: [(messageID: String, conversationID: String)] = []
    var toggledReactions: [(emoji: String, messageID: String, conversationID: String, userID: String)] = []

    func sendMessage(_ message: Message) async throws {
        if shouldFail { throw MessageError.sendFailed }
        sentMessages.append(message)
    }

    func fetchMessages(conversationID: String, limit: Int) async throws -> [Message] {
        fetchedMessages
    }

    func listenToMessages(conversationID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        completion(fetchedMessages)
        return MockListenerRegistration()
    }

    func markMessagesAsRead(conversationID: String, messageIDs: [String], userID: String) async throws {
        if shouldFail { throw MessageError.sendFailed }
        markedReadIDs.append((conversationID, messageIDs, userID))
    }

    func getReadReceipts(conversationID: String, messageID: String) async throws -> [String: Date] {
        [:]
    }

    func updateTypingStatus(conversationID: String, userID: String, isTyping: Bool) async throws {}

    func listenToTypingStatus(conversationID: String, otherUserID: String, completion: @escaping (Bool) -> Void) -> ListenerRegistration {
        MockListenerRegistration()
    }

    func toggleReaction(emoji: String, messageID: String, conversationID: String, userID: String) async throws {
        if shouldFail { throw MessageError.sendFailed }
        toggledReactions.append((emoji, messageID, conversationID, userID))
    }

    func deleteMessage(messageID: String, conversationID: String) async throws {
        if shouldFail { throw MessageError.sendFailed }
        deletedMessages.append((messageID, conversationID))
    }

    func sendReply(to messageID: String, text: String, conversationID: String, senderID: String) async throws {
        if shouldFail { throw MessageError.sendFailed }
    }
}

final class MockListenerRegistration: NSObject, ListenerRegistration {
    func remove() {}
}
