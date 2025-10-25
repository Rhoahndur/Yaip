//
//  AIFeaturesViewModel.swift
//  Yaip
//
//  ViewModel for managing AI agent features
//

import Foundation
import Combine

@MainActor
class AIFeaturesViewModel: ObservableObject {
    // MARK: - Published Properties

    // Summarization
    @Published var isLoadingSummary = false
    @Published var currentSummary: ThreadSummary?
    @Published var summaryError: String?

    // Action Items
    @Published var isLoadingActionItems = false
    @Published var actionItems: [ActionItem] = []
    @Published var actionItemsError: String?

    // Meeting Suggestions
    @Published var isLoadingMeeting = false
    @Published var meetingSuggestion: MeetingSuggestion?
    @Published var meetingError: String?

    // Decisions
    @Published var isLoadingDecisions = false
    @Published var decisions: [Decision] = []
    @Published var decisionsError: String?

    // Priority
    @Published var isLoadingPriority = false
    @Published var priorityMessages: [PriorityMessage] = []
    @Published var priorityError: String?

    // Search
    @Published var isSearching = false
    @Published var searchResults: [SearchResult] = []
    @Published var searchError: String?
    @Published var searchQuery = ""

    // General
    @Published var showSummary = false
    @Published var showActionItems = false
    @Published var showMeetingSuggestion = false
    @Published var showDecisions = false
    @Published var showPriority = false
    @Published var showSearch = false

    private let n8nService = N8NService.shared
    private let conversationID: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(conversationID: String) {
        self.conversationID = conversationID
    }

    // MARK: - Thread Summarization

    func summarizeThread(messageCount: Int = 200) {
        isLoadingSummary = true
        summaryError = nil

        Task {
            do {
                let summary = try await n8nService.summarizeThread(
                    conversationID: conversationID,
                    messageCount: messageCount
                )

                self.currentSummary = summary
                self.showSummary = true
                print("✅ Summary generated: \(summary.messageCount) messages")

            } catch {
                self.summaryError = error.localizedDescription
                print("❌ Summary error: \(error)")
            }

            self.isLoadingSummary = false
        }
    }

    // MARK: - Action Items

    func extractActionItems(dateRange: String = "7d") {
        isLoadingActionItems = true
        actionItemsError = nil

        Task {
            do {
                let items = try await n8nService.extractActionItems(
                    conversationID: conversationID,
                    dateRange: dateRange
                )

                self.actionItems = items
                self.showActionItems = true
                print("✅ Extracted \(items.count) action items")

            } catch {
                self.actionItemsError = error.localizedDescription
                print("❌ Action items error: \(error)")
            }

            self.isLoadingActionItems = false
        }
    }

    func toggleActionItem(_ item: ActionItem) {
        guard let index = actionItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        var updatedItem = item
        updatedItem.status = item.status == .completed ? .pending : .completed

        actionItems[index] = updatedItem

        // TODO: Sync status to Firestore
        print("📝 Toggled action item: \(item.task)")
    }

    // MARK: - Meeting Scheduler

    func suggestMeetingTimes(context: String = "from recent messages") {
        isLoadingMeeting = true
        meetingError = nil

        Task {
            do {
                // Get AI-generated suggestions
                var suggestion = try await n8nService.suggestMeetingTimes(
                    conversationID: conversationID,
                    context: context
                )

                // Enhance with Apple Calendar availability if authorized
                if AppleCalendarService.shared.isAuthorized {
                    let enrichedTimeSlots = AppleCalendarService.shared.checkAvailability(
                        for: suggestion.suggestedTimes
                    )

                    // Update suggestion with calendar-aware time slots
                    suggestion = MeetingSuggestion(
                        detectedIntent: suggestion.detectedIntent,
                        suggestedTimes: enrichedTimeSlots,
                        duration: suggestion.duration,
                        participants: suggestion.participants
                    )
                }

                self.meetingSuggestion = suggestion
                self.showMeetingSuggestion = true

            } catch {
                self.meetingError = error.localizedDescription
            }

            self.isLoadingMeeting = false
        }
    }

    func selectTimeSlot(_ timeSlot: TimeSlot) {
        print("📅 Selected time slot: \(timeSlot.date.formatted()) at \(timeSlot.startTime)")

        // TODO: Create calendar event
        // TODO: Send confirmation message to chat

        showMeetingSuggestion = false
    }

    // MARK: - Decision Tracking

    func extractDecisions() {
        isLoadingDecisions = true
        decisionsError = nil

        Task {
            do {
                let extractedDecisions = try await n8nService.extractDecisions(
                    conversationID: conversationID
                )

                self.decisions = extractedDecisions
                self.showDecisions = true
                print("✅ Extracted \(extractedDecisions.count) decisions")

            } catch {
                self.decisionsError = error.localizedDescription
                print("❌ Decisions error: \(error)")
            }

            self.isLoadingDecisions = false
        }
    }

    // MARK: - Priority Detection

    func detectPriority() {
        isLoadingPriority = true
        priorityError = nil

        Task {
            do {
                let priority = try await n8nService.detectPriorityMessages(
                    conversationID: conversationID
                )

                self.priorityMessages = priority
                self.showPriority = true
                print("✅ Detected \(priority.count) priority messages")

            } catch {
                self.priorityError = error.localizedDescription
                print("❌ Priority detection error: \(error)")
            }

            self.isLoadingPriority = false
        }
    }

    // MARK: - Smart Search

    func searchMessages(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        searchQuery = query
        isSearching = true
        searchError = nil

        Task {
            // Debounce search
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Check if query hasn't changed
            guard query == self.searchQuery else {
                self.isSearching = false
                return
            }

            do {
                let results = try await n8nService.searchMessages(
                    conversationID: conversationID,
                    query: query
                )

                self.searchResults = results
                print("✅ Found \(results.count) search results")

            } catch {
                self.searchError = error.localizedDescription
                print("❌ Search error: \(error)")
            }

            self.isSearching = false
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        searchError = nil
    }

    // MARK: - Helpers

    func dismissAllModals() {
        showSummary = false
        showActionItems = false
        showMeetingSuggestion = false
        showDecisions = false
        showPriority = false
        showSearch = false
    }
}
