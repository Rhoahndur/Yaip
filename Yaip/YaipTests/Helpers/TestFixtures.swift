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

    // MARK: - AI Models

    static func threadSummary(
        summary: String = "Test summary of the conversation.",
        messageCount: Int = 50,
        confidence: Double = 0.95
    ) -> ThreadSummary {
        ThreadSummary(
            summary: summary,
            messageCount: messageCount,
            confidence: confidence,
            timestamp: Date()
        )
    }

    static func actionItem(
        id: String = "action1",
        task: String = "Review the PR",
        assignee: String? = "Test User",
        priority: ActionItem.Priority = .high,
        status: ActionItem.TaskStatus = .pending,
        messageID: String = "msg1",
        context: String = "Discussed in standup"
    ) -> ActionItem {
        ActionItem(
            id: id,
            task: task,
            assignee: assignee,
            deadline: nil,
            priority: priority,
            status: status,
            messageID: messageID,
            context: context
        )
    }

    static func meetingSuggestion(
        detectedIntent: String = "Team Standup",
        duration: Int = 30,
        participants: [String] = ["Alice", "Bob"]
    ) -> MeetingSuggestion {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return MeetingSuggestion(
            detectedIntent: detectedIntent,
            suggestedTimes: [
                TimeSlot(date: tomorrow, startTime: "10:00", endTime: "10:30", available: participants, conflicts: []),
                TimeSlot(date: tomorrow, startTime: "14:00", endTime: "14:30", available: participants, conflicts: [])
            ],
            duration: duration,
            participants: participants
        )
    }

    static func timeSlot(
        startTime: String = "10:00",
        endTime: String = "10:30"
    ) -> TimeSlot {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return TimeSlot(date: tomorrow, startTime: startTime, endTime: endTime, available: ["Alice"], conflicts: [])
    }

    static func decision(
        id: String = "dec1",
        decision: String = "Use Swift concurrency",
        decisionMaker: String = "Tech Lead",
        impact: Decision.Impact = .high,
        category: Decision.Category = .technical,
        messageID: String = "msg1"
    ) -> Decision {
        Decision(
            id: id,
            decision: decision,
            decisionMaker: decisionMaker,
            reasoning: "Modern approach with better safety",
            impact: impact,
            category: category,
            context: "Architecture discussion",
            timestamp: Date(),
            messageID: messageID
        )
    }

    static func priorityMessage(
        messageID: String = "msg1",
        priorityScore: Int = 8,
        reason: String = "Urgent deadline mentioned",
        excerpt: String = "We need this done by Friday"
    ) -> PriorityMessage {
        PriorityMessage(
            messageID: messageID,
            priorityScore: priorityScore,
            reason: reason,
            excerpt: excerpt
        )
    }

    static func searchResult(
        messageID: String = "msg1",
        text: String = "Found message text",
        senderName: String = "Test User",
        relevanceScore: Double = 0.9,
        matchType: SearchResult.MatchType = .keyword
    ) -> SearchResult {
        SearchResult(
            messageID: messageID,
            text: text,
            senderName: senderName,
            timestamp: Date(),
            relevanceScore: relevanceScore,
            matchType: matchType
        )
    }

    static func ragSearchResult(
        query: String = "test query",
        aiAnswer: String? = "Based on the conversation, the answer is...",
        results: [SearchResult]? = nil
    ) -> RAGSearchResult {
        RAGSearchResult(
            results: results ?? [searchResult()],
            aiAnswer: aiAnswer,
            answerSources: ["msg1"],
            query: query
        )
    }

    // MARK: - Pending Conversations

    static func pendingConversation(
        type: ConversationType = .oneOnOne,
        participants: [String] = ["currentUser", "otherUser"],
        name: String? = nil
    ) -> PendingConversation {
        PendingConversation(
            type: type,
            participants: participants,
            name: name
        )
    }
}
