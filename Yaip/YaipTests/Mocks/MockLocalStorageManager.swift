import UIKit
@testable import Yaip

@MainActor
final class MockLocalStorageManager: LocalStorageManagerProtocol {
    var savedMessages: [Message] = []
    var savedConversations: [Conversation] = []
    var syncedMessageIDs: [String] = []
    var shouldFail = false

    func saveMessage(_ message: Message) throws {
        if shouldFail { throw NSError(domain: "Test", code: 1) }
        if let index = savedMessages.firstIndex(where: { $0.id == message.id }) {
            savedMessages[index] = message
        } else {
            savedMessages.append(message)
        }
    }

    func fetchMessages(conversationID: String) throws -> [Message] {
        savedMessages.filter { $0.conversationID == conversationID }
    }

    func deleteMessage(id: String) throws {
        savedMessages.removeAll { $0.id == id }
    }

    func getPendingMessages() throws -> [Message] {
        savedMessages.filter { $0.status == .staged || $0.status == .failed }
    }

    func markMessageSynced(id: String) throws {
        if shouldFail { throw NSError(domain: "Test", code: 1) }
        syncedMessageIDs.append(id)
    }

    func saveConversation(_ conversation: Conversation) throws {
        if let index = savedConversations.firstIndex(where: { $0.id == conversation.id }) {
            savedConversations[index] = conversation
        } else {
            savedConversations.append(conversation)
        }
    }

    func fetchConversations() throws -> [Conversation] { savedConversations }
    func deleteConversation(id: String) throws { savedConversations.removeAll { $0.id == id } }

    func saveImage(_ image: UIImage, forMessageID messageID: String) {}
    func loadImage(forMessageID messageID: String) -> UIImage? { nil }
    func deleteImage(forMessageID messageID: String) {}
    func clearAll() throws { savedMessages.removeAll(); savedConversations.removeAll() }
}
