import Foundation
import FirebaseFirestore
@testable import Yaip

final class MockConversationService: ConversationServiceProtocol {
    var createdConversations: [Conversation] = []
    var fetchedConversations: [Conversation] = []
    var shouldFail = false
    var updatedLastMessages: [(conversationID: String, lastMessage: LastMessage)] = []
    var markedReadIDs: [(conversationID: String, userID: String)] = []
    var incrementedUnreadCounts: [(conversationID: String, userIDs: [String])] = []

    func createConversation(_ conversation: Conversation) async throws {
        if shouldFail { throw ConversationError.invalidID }
        createdConversations.append(conversation)
    }

    func fetchConversations(for userID: String) async throws -> [Conversation] {
        fetchedConversations
    }

    func listenToConversations(for userID: String, completion: @escaping ([Conversation]) -> Void) -> ListenerRegistration {
        completion(fetchedConversations)
        return MockListenerRegistration()
    }

    func updateLastMessage(conversationID: String, lastMessage: LastMessage) async throws {
        if shouldFail { throw ConversationError.invalidID }
        updatedLastMessages.append((conversationID, lastMessage))
    }

    func findExistingConversation(between participants: [String]) async throws -> Conversation? {
        nil
    }

    func deleteConversation(conversationID: String) async throws {
        if shouldFail { throw ConversationError.invalidID }
    }

    func markAsRead(conversationID: String, userID: String) async throws {
        if shouldFail { throw ConversationError.invalidID }
        markedReadIDs.append((conversationID, userID))
    }

    func incrementUnreadCount(conversationID: String, for userIDs: [String]) async throws {
        if shouldFail { throw ConversationError.invalidID }
        incrementedUnreadCounts.append((conversationID, userIDs))
    }
}
