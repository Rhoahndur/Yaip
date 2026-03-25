import Foundation
@testable import Yaip

enum TestFixtures {

    // MARK: - Users

    static func user(
        id: String = "user1",
        displayName: String = "Test User",
        email: String = "test@example.com",
        status: UserStatus = .online
    ) -> User {
        User(
            id: id,
            displayName: displayName,
            email: email,
            profileImageURL: nil,
            status: status,
            lastSeen: nil,
            fcmToken: nil,
            createdAt: Date()
        )
    }

    static let currentUser = user(id: "currentUser", displayName: "Current User")
    static let otherUser = user(id: "otherUser", displayName: "Other User")

    // MARK: - Conversations

    static func conversation(
        id: String = "conv1",
        type: ConversationType = .oneOnOne,
        participants: [String] = ["currentUser", "otherUser"],
        name: String? = nil,
        unreadCount: [String: Int] = [:]
    ) -> Conversation {
        Conversation(
            id: id,
            type: type,
            participants: participants,
            name: name,
            imageURL: nil,
            lastMessage: nil,
            createdAt: Date(),
            updatedAt: Date(),
            unreadCount: unreadCount
        )
    }

    static func groupConversation(
        id: String = "group1",
        participants: [String] = ["currentUser", "user2", "user3"],
        name: String = "Test Group"
    ) -> Conversation {
        conversation(id: id, type: .group, participants: participants, name: name)
    }

    // MARK: - Messages

    static func message(
        id: String = "msg1",
        conversationID: String = "conv1",
        senderID: String = "currentUser",
        text: String? = "Hello",
        mediaURL: String? = nil,
        mediaType: MediaType? = nil,
        timestamp: Date = Date(),
        status: MessageStatus = .sent,
        readBy: [String] = ["currentUser"],
        reactions: [String: [String]] = [:],
        replyTo: String? = nil
    ) -> Message {
        var msg = Message(
            id: id,
            conversationID: conversationID,
            senderID: senderID,
            text: text,
            mediaURL: mediaURL,
            mediaType: mediaType,
            timestamp: timestamp,
            status: status,
            readBy: readBy
        )
        msg.reactions = reactions
        msg.replyTo = replyTo
        return msg
    }

    static func stagedMessage(
        id: String = "staged1",
        text: String = "Staged message"
    ) -> Message {
        message(id: id, text: text, status: .staged)
    }

    static func failedMessage(
        id: String = "failed1",
        text: String = "Failed message"
    ) -> Message {
        message(id: id, text: text, status: .failed)
    }

    static func imageMessage(
        id: String = "img1",
        mediaURL: String? = "https://example.com/image.jpg",
        status: MessageStatus = .sent
    ) -> Message {
        message(id: id, text: nil, mediaURL: mediaURL, mediaType: .image, status: status)
    }
}
