import Foundation
@testable import Yaip

enum MockN8NError: LocalizedError {
    case resultNotConfigured(String)
    var errorDescription: String? {
        switch self {
        case .resultNotConfigured(let method):
            return "MockN8NService.\(method) called without setting its result property"
        }
    }
}

final class MockN8NService: N8NServiceProtocol {
    var summarizeResult: ThreadSummary?
    var actionItemsResult: [ActionItem] = []
    var meetingResult: MeetingSuggestion?
    var decisionsResult: [Decision] = []
    var priorityResult: [PriorityMessage] = []
    var searchResult: [SearchResult] = []
    var ragResult: RAGSearchResult?
    var errorToThrow: Error?

    func summarizeThread(conversationID: String, messageCount: Int) async throws -> ThreadSummary {
        if let error = errorToThrow { throw error }
        guard let result = summarizeResult else { throw MockN8NError.resultNotConfigured("summarizeResult") }
        return result
    }

    func extractActionItems(conversationID: String, dateRange: String) async throws -> [ActionItem] {
        if let error = errorToThrow { throw error }
        return actionItemsResult
    }

    func suggestMeetingTimes(conversationID: String, context: String) async throws -> MeetingSuggestion {
        if let error = errorToThrow { throw error }
        guard let result = meetingResult else { throw MockN8NError.resultNotConfigured("meetingResult") }
        return result
    }

    func extractDecisions(conversationID: String) async throws -> [Decision] {
        if let error = errorToThrow { throw error }
        return decisionsResult
    }

    func detectPriorityMessages(conversationID: String) async throws -> [PriorityMessage] {
        if let error = errorToThrow { throw error }
        return priorityResult
    }

    func searchMessages(conversationID: String, query: String) async throws -> [SearchResult] {
        if let error = errorToThrow { throw error }
        return searchResult
    }

    func ragSearch(conversationID: String, query: String) async throws -> RAGSearchResult {
        if let error = errorToThrow { throw error }
        guard let result = ragResult else { throw MockN8NError.resultNotConfigured("ragResult") }
        return result
    }
}
