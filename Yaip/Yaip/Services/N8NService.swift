//
//  N8NService.swift
//  Yaip
//
//  Service for communicating with N8N AI agent workflows
//

import Foundation

/// Service for N8N webhook-based AI agent communication
class N8NService {
    static let shared = N8NService()

    // Load configuration from Info.plist (values come from Config.xcconfig)
    private let baseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "N8N_WEBHOOK_URL") as? String,
              !url.isEmpty,
              url != "$(N8N_WEBHOOK_URL)" else {
            print("⚠️ N8N_WEBHOOK_URL not configured in Config.xcconfig")
            return "https://your-n8n-instance.com/webhook"
        }
        return url
    }()

    private let authToken: String = {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "N8N_AUTH_TOKEN") as? String,
              !token.isEmpty,
              token != "$(N8N_AUTH_TOKEN)" else {
            print("⚠️ N8N_AUTH_TOKEN not configured in Config.xcconfig")
            return "your_secret_token_here"
        }
        return token
    }()

    private init() {
        print("🔧 N8N Service initialized")
        print("   Webhook URL: \(baseURL)")
        print("   Auth Token: \(authToken.prefix(10))***")
    }

    // MARK: - Thread Summarization

    /// Generate a summary of conversation messages
    func summarizeThread(conversationID: String, messageCount: Int = 200) async throws -> ThreadSummary {
        let request = AIRequest(
            feature: "summarize",
            conversationID: conversationID,
            userID: AuthManager.shared.currentUserID ?? "",
            parameters: [
                "messageCount": messageCount
            ]
        )

        // PRODUCTION: Call real N8N webhook
        do {
            print("📤 Calling N8N webhook for thread summary...")
            print("   URL: \(baseURL)/summarize")
            print("   Conversation ID: \(conversationID)")
            print("   Message Count: \(messageCount)")

            let response = try await callWebhook(request: request, responseType: ThreadSummaryResponse.self)

            print("✅ Received summary from N8N")
            print("   Success: \(response.success)")
            print("   Message Count: \(response.messageCount)")

            return ThreadSummary(
                summary: response.summary,
                messageCount: response.messageCount,
                confidence: response.confidence,
                timestamp: ISO8601DateFormatter().date(from: response.timestamp) ?? Date()
            )
        } catch {
            print("❌ N8N webhook error: \(error)")
            print("   Falling back to mock data...")

            // Fallback to mock if N8N fails (for testing)
            return try await mockSummarizeThread(conversationID: conversationID, messageCount: messageCount)
        }
    }

    // MARK: - Action Item Extraction

    /// Extract action items from conversation
    func extractActionItems(conversationID: String, dateRange: String = "7d") async throws -> [ActionItem] {
        let request = AIRequest(
            feature: "extract_actions",
            conversationID: conversationID,
            userID: AuthManager.shared.currentUserID ?? "",
            parameters: [
                "dateRange": dateRange
            ]
        )

        // PRODUCTION: Call real N8N webhook
        do {
            print("📤 Calling N8N webhook for action items...")
            print("   URL: \(baseURL)/extract_actions")
            print("   Conversation ID: \(conversationID)")

            let response = try await callWebhook(request: request, responseType: ActionItemsResponse.self)

            print("✅ Received action items from N8N")
            print("   Success: \(response.success)")
            print("   Items found: \(response.actionItems.count)")

            // Convert response to ActionItem models
            let actionItems = response.actionItems.map { item in
                ActionItem(
                    id: UUID().uuidString,
                    task: item.task,
                    assignee: item.assignee,
                    deadline: parseDate(item.deadline),
                    priority: parsePriority(item.priority),
                    status: .pending,
                    messageID: conversationID,
                    context: item.context
                )
            }

            return actionItems
        } catch {
            print("❌ N8N webhook error: \(error)")
            print("   Falling back to mock data...")

            // Fallback to mock if N8N fails (for testing)
            return try await mockExtractActionItems(conversationID: conversationID)
        }
    }

    // Helper to parse priority string
    private func parsePriority(_ priorityString: String?) -> ActionItem.Priority {
        guard let priority = priorityString?.lowercased() else { return .medium }
        switch priority {
        case "high": return .high
        case "low": return .low
        default: return .medium
        }
    }

    // Helper to parse date string
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateStr = dateString, !dateStr.isEmpty else { return nil }

        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateStr) {
            return date
        }

        let regularFormatter = DateFormatter()
        regularFormatter.dateFormat = "yyyy-MM-dd"
        return regularFormatter.date(from: dateStr)
    }

    // MARK: - Meeting Scheduler

    /// Detect scheduling intent and suggest meeting times
    func suggestMeetingTimes(conversationID: String, context: String) async throws -> MeetingSuggestion {
        let request = AIRequest(
            feature: "schedule_meeting",
            conversationID: conversationID,
            userID: AuthManager.shared.currentUserID ?? "",
            parameters: [
                "context": context
            ]
        )

        // PRODUCTION: Call real N8N webhook
        do {
            print("📤 Calling N8N webhook for meeting suggestions...")
            print("   URL: \(baseURL)/schedule_meeting")
            print("   Conversation ID: \(conversationID)")

            let response = try await callWebhook(request: request, responseType: MeetingSuggestionResponse.self)

            print("✅ Received meeting suggestions from N8N")
            print("   Success: \(response.success)")
            print("   Has intent: \(response.hasMeetingIntent)")
            print("   Suggested times: \(response.suggestedTimes.count)")

            // Convert response to MeetingSuggestion model
            let timeSlots = response.suggestedTimes.map { timeData in
                TimeSlot(
                    date: parseISODate(timeData.date) ?? Date(),
                    startTime: timeData.startTime,
                    endTime: timeData.endTime,
                    available: response.participants,
                    conflicts: []
                )
            }

            return MeetingSuggestion(
                detectedIntent: response.detectedIntent,
                suggestedTimes: timeSlots,
                duration: response.duration,
                participants: response.participants
            )
        } catch {
            print("❌ N8N webhook error: \(error)")
            print("   Falling back to mock data...")

            // Fallback to mock if N8N fails (for testing)
            return try await mockSuggestMeetingTimes()
        }
    }

    // Helper to parse ISO date string
    private func parseISODate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.date(from: dateString)
    }

    // MARK: - Decision Tracking

    /// Extract decisions from conversation
    func extractDecisions(conversationID: String) async throws -> [Decision] {
        let request = AIRequest(
            feature: "track_decisions",
            conversationID: conversationID,
            userID: AuthManager.shared.currentUserID ?? "",
            parameters: [:]
        )

        // PRODUCTION: Call real N8N webhook
        do {
            print("📤 Calling N8N webhook for decision tracking...")
            print("   URL: \(baseURL)/track_decisions")
            print("   Conversation ID: \(conversationID)")

            let response = try await callWebhook(request: request, responseType: DecisionTrackingResponse.self)

            print("✅ Received decisions from N8N")
            print("   Success: \(response.success)")
            print("   Decisions found: \(response.decisions.count)")

            // Convert response to Decision models
            let decisions = response.decisions.map { item in
                Decision(
                    id: UUID().uuidString,
                    decision: item.decision,
                    decisionMaker: item.decisionMaker,
                    reasoning: item.reasoning,
                    impact: parseImpact(item.impact),
                    category: parseCategory(item.category),
                    context: item.context,
                    timestamp: parseISODate(item.timestamp) ?? Date(),
                    messageID: conversationID
                )
            }

            return decisions
        } catch {
            print("❌ N8N webhook error: \(error)")
            print("   Falling back to mock data...")

            // Fallback to mock if N8N fails (for testing)
            return try await mockExtractDecisions()
        }
    }

    // Helper to parse impact string
    private func parseImpact(_ impactString: String?) -> Decision.Impact {
        guard let impact = impactString?.lowercased() else { return .medium }
        switch impact {
        case "high": return .high
        case "low": return .low
        default: return .medium
        }
    }

    // Helper to parse category string
    private func parseCategory(_ categoryString: String?) -> Decision.Category {
        guard let category = categoryString?.lowercased() else { return .other }
        switch category {
        case "technical": return .technical
        case "business": return .business
        case "process": return .process
        default: return .other
        }
    }

    // MARK: - Priority Detection

    /// Score messages for priority
    func detectPriorityMessages(conversationID: String) async throws -> [PriorityMessage] {
        let request = AIRequest(
            feature: "detect_priority",
            conversationID: conversationID,
            userID: AuthManager.shared.currentUserID ?? "",
            parameters: [:]
        )

        // TODO: Replace with real N8N webhook call
        return try await mockDetectPriority()
    }

    // MARK: - Smart Search

    /// Semantic search across messages
    func searchMessages(conversationID: String, query: String) async throws -> [SearchResult] {
        let request = AIRequest(
            feature: "search",
            conversationID: conversationID,
            userID: AuthManager.shared.currentUserID ?? "",
            parameters: [
                "query": query
            ]
        )

        // TODO: Replace with real N8N webhook call
        return try await mockSearchMessages(query: query)
    }

    // MARK: - Generic Webhook Call

    /// Generic method to call N8N webhook
    private func callWebhook<T: Codable>(request: AIRequest, responseType: T.Type) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(request.feature)") else {
            print("❌ Invalid URL: \(baseURL)/\(request.feature)")
            throw N8NError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(authToken, forHTTPHeaderField: "Authorization")
        urlRequest.timeoutInterval = 30 // 30 second timeout

        // Encode request body
        let requestBody: [String: Any] = [
            "conversationID": request.conversationID,
            "userID": request.userID,
            "parameters": request.parameters
        ]

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("📡 Sending request to N8N...")
        print("   Headers: Authorization: Bearer ***")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw N8NError.invalidResponse
        }

        print("📥 Received response: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response body: \(errorString)")
            }
            throw N8NError.httpError(statusCode: httpResponse.statusCode)
        }

        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response body: \(responseString.prefix(200))...")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Mock Implementations (Remove when N8N is connected)

extension N8NService {

    private func mockSummarizeThread(conversationID: String, messageCount: Int) async throws -> ThreadSummary {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        return ThreadSummary(
            summary: """
            ## Key Discussion Points

            • **Product Launch**: Team agreed to move launch date to Q4 2025
            • **Budget Allocation**: Marketing budget increased to $50K
            • **Technical Blockers**: API integration needs completion by next week
            • **Action Items**: 3 tasks assigned to team members

            ## Decisions Made

            ✅ Using microservices architecture
            ✅ Hiring 2 additional engineers

            ## Open Questions

            ❓ Final pricing tier structure
            ❓ Beta test participant selection

            **Tone**: Professional, collaborative with some urgency around launch timeline.
            """,
            messageCount: messageCount,
            confidence: 0.92,
            timestamp: Date()
        )
    }

    private func mockExtractActionItems(conversationID: String) async throws -> [ActionItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        return [
            ActionItem(
                id: UUID().uuidString,
                task: "Complete API integration testing",
                assignee: "Sarah Chen",
                deadline: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                priority: .high,
                status: .pending,
                messageID: "msg-123",
                context: "Need to finish before Q4 launch"
            ),
            ActionItem(
                id: UUID().uuidString,
                task: "Review marketing budget proposal",
                assignee: "Mike Johnson",
                deadline: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                priority: .medium,
                status: .pending,
                messageID: "msg-456",
                context: "Final approval needed from leadership"
            ),
            ActionItem(
                id: UUID().uuidString,
                task: "Schedule beta test kickoff meeting",
                assignee: nil,
                deadline: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                priority: .low,
                status: .pending,
                messageID: "msg-789",
                context: "Coordinate with all stakeholders"
            )
        ]
    }

    private func mockSuggestMeetingTimes() async throws -> MeetingSuggestion {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        return MeetingSuggestion(
            detectedIntent: "Team wants to schedule Q4 planning meeting",
            suggestedTimes: [
                TimeSlot(
                    date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                    startTime: "14:00",
                    endTime: "15:00",
                    available: ["Sarah Chen", "Mike Johnson", "You"],
                    conflicts: []
                ),
                TimeSlot(
                    date: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
                    startTime: "10:00",
                    endTime: "11:00",
                    available: ["Sarah Chen", "Mike Johnson", "You"],
                    conflicts: []
                ),
                TimeSlot(
                    date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                    startTime: "15:00",
                    endTime: "16:00",
                    available: ["Sarah Chen", "Mike Johnson", "You", "Emma Davis"],
                    conflicts: []
                )
            ],
            duration: 60,
            participants: ["Sarah Chen", "Mike Johnson", "Emma Davis"]
        )
    }

    private func mockExtractDecisions() async throws -> [Decision] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000)

        return [
            Decision(
                id: UUID().uuidString,
                decision: "Move to microservices architecture for better scalability",
                decisionMaker: "Sarah Chen",
                reasoning: "Current monolith is hitting performance limits. Team agreed microservices will help with scaling and team autonomy.",
                impact: .high,
                category: .technical,
                context: "Discussed during architecture review meeting. All senior engineers agreed.",
                timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                messageID: "msg-decision-1"
            ),
            Decision(
                id: UUID().uuidString,
                decision: "Hire 2 additional backend engineers for Q4 launch",
                decisionMaker: "Mike Johnson",
                reasoning: "Need more bandwidth for Q4 launch. Current team is stretched thin and at risk of burnout.",
                impact: .high,
                category: .business,
                context: "Budget approved by leadership. HR to start recruitment immediately.",
                timestamp: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                messageID: "msg-decision-2"
            ),
            Decision(
                id: UUID().uuidString,
                decision: "Change standup time from 9am to 10am",
                decisionMaker: "Team consensus",
                reasoning: "Team members in different timezones were having trouble joining at 9am.",
                impact: .low,
                category: .process,
                context: "Proposed by remote team members, no objections from anyone.",
                timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                messageID: "msg-decision-3"
            )
        ]
    }

    private func mockDetectPriority() async throws -> [PriorityMessage] {
        try await Task.sleep(nanoseconds: 1_000_000_000)

        return [
            PriorityMessage(
                messageID: "msg-priority-1",
                priorityScore: 9,
                reason: "Direct mention with urgent keyword and deadline",
                excerpt: "@You - Need your approval ASAP for budget increase"
            ),
            PriorityMessage(
                messageID: "msg-priority-2",
                priorityScore: 7,
                reason: "Blocker requiring your action",
                excerpt: "Can't proceed with deployment until you review the PR"
            )
        ]
    }

    private func mockSearchMessages(query: String) async throws -> [SearchResult] {
        try await Task.sleep(nanoseconds: 800_000_000)

        return [
            SearchResult(
                messageID: "msg-search-1",
                text: "Let's discuss the Q4 budget allocation. We need to finalize numbers by EOW.",
                senderName: "Sarah Chen",
                timestamp: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                relevanceScore: 0.94,
                matchType: .semantic
            ),
            SearchResult(
                messageID: "msg-search-2",
                text: "Budget increase approved! Marketing gets additional $50K for Q4.",
                senderName: "Mike Johnson",
                timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                relevanceScore: 0.87,
                matchType: .keyword
            )
        ]
    }
}

// MARK: - Models

struct AIRequest: Encodable {
    let feature: String
    let conversationID: String
    let userID: String
    let parameters: [String: Any]

    enum CodingKeys: String, CodingKey {
        case feature, conversationID, userID, parameters
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(feature, forKey: .feature)
        try container.encode(conversationID, forKey: .conversationID)
        try container.encode(userID, forKey: .userID)

        // Convert [String: Any] to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: parameters)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        try container.encode(jsonString, forKey: .parameters)
    }
}

// N8N Response wrapper
struct ThreadSummaryResponse: Codable {
    let success: Bool
    let summary: String
    let messageCount: Int
    let confidence: Double
    let timestamp: String
}

struct ThreadSummary: Codable {
    let summary: String
    let messageCount: Int
    let confidence: Double
    let timestamp: Date
}

// N8N Action Items Response
struct ActionItemsResponse: Codable {
    let success: Bool
    let actionItems: [ActionItemData]
    let timestamp: String
    let conversationID: String
}

struct ActionItemData: Codable {
    let task: String
    let assignee: String?
    let deadline: String?
    let priority: String
    let context: String
}

// N8N Meeting Suggestions Response
struct MeetingSuggestionResponse: Codable {
    let success: Bool
    let hasMeetingIntent: Bool
    let detectedIntent: String
    let suggestedTimes: [TimeSlotData]
    let duration: Int
    let participants: [String]
    let timestamp: String
    let conversationID: String
}

struct TimeSlotData: Codable {
    let date: String
    let startTime: String
    let endTime: String
    let dayOfWeek: String?
}

// N8N Decision Tracking Response
struct DecisionTrackingResponse: Codable {
    let success: Bool
    let decisions: [DecisionData]
    let timestamp: String
    let conversationID: String
}

struct DecisionData: Codable {
    let decision: String
    let decisionMaker: String
    let timestamp: String
    let reasoning: String
    let impact: String
    let category: String
    let context: String
}

struct ActionItem: Codable, Identifiable {
    let id: String
    var task: String
    var assignee: String?
    var deadline: Date?
    var priority: Priority
    var status: TaskStatus
    var messageID: String
    var context: String

    enum Priority: String, Codable {
        case low, medium, high
    }

    enum TaskStatus: String, Codable {
        case pending, inProgress, completed
    }
}

struct MeetingSuggestion: Codable {
    let detectedIntent: String
    let suggestedTimes: [TimeSlot]
    let duration: Int // minutes
    let participants: [String]
}

struct TimeSlot: Codable, Identifiable {
    var id: String { "\(date.timeIntervalSince1970)-\(startTime)" }
    let date: Date
    let startTime: String
    let endTime: String
    let available: [String]
    let conflicts: [String]
}

struct Decision: Codable, Identifiable {
    let id: String
    let decision: String
    let decisionMaker: String
    let reasoning: String
    let impact: Impact
    let category: Category
    let context: String
    let timestamp: Date
    let messageID: String

    enum Impact: String, Codable {
        case low, medium, high
    }

    enum Category: String, Codable {
        case technical, business, process, other
    }
}

struct PriorityMessage: Codable, Identifiable {
    var id: String { messageID }
    let messageID: String
    let priorityScore: Int // 0-10
    let reason: String
    let excerpt: String
}

struct SearchResult: Codable, Identifiable {
    var id: String { messageID }
    let messageID: String
    let text: String
    let senderName: String
    let timestamp: Date
    let relevanceScore: Double
    let matchType: MatchType

    enum MatchType: String, Codable {
        case keyword, semantic, hybrid
    }
}

enum N8NError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid N8N webhook URL"
        case .invalidResponse:
            return "Invalid response from N8N"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode N8N response"
        }
    }
}
