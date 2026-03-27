import Foundation

/// Contract for N8N webhook-based AI agent communication.
protocol N8NServiceProtocol {
    func summarizeThread(conversationID: String, messageCount: Int) async throws -> ThreadSummary
    func extractActionItems(conversationID: String, dateRange: String) async throws -> [ActionItem]
    func suggestMeetingTimes(conversationID: String, context: String) async throws -> MeetingSuggestion
    func extractDecisions(conversationID: String) async throws -> [Decision]
    func detectPriorityMessages(conversationID: String) async throws -> [PriorityMessage]
    func searchMessages(conversationID: String, query: String) async throws -> [SearchResult]
    func ragSearch(conversationID: String, query: String) async throws -> RAGSearchResult
}
