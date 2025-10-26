//
//  AIFeaturesViewModel.swift
//  Yaip
//
//  ViewModel for managing AI agent features
//

import Foundation
import Combine
import FirebaseFirestore

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

    // Calendar event creation
    @Published var isCreatingEvent = false
    @Published var showEventCreatedAlert = false
    @Published var showEventErrorAlert = false
    @Published var eventCreationError: String?

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

                // Get real participant names from the conversation
                let participantNames = await fetchParticipantNames()

                // Enhance with calendar availability if any provider is authorized
                if CalendarManager.shared.hasAnyProviderConnected {
                    let enrichedTimeSlots = await CalendarManager.shared.checkAvailability(
                        for: suggestion.suggestedTimes
                    )

                    // Update suggestion with calendar-aware time slots AND real participants
                    suggestion = MeetingSuggestion(
                        detectedIntent: suggestion.detectedIntent,
                        suggestedTimes: enrichedTimeSlots,
                        duration: suggestion.duration,
                        participants: participantNames
                    )
                } else {
                    // Just update participants
                    suggestion = MeetingSuggestion(
                        detectedIntent: suggestion.detectedIntent,
                        suggestedTimes: suggestion.suggestedTimes,
                        duration: suggestion.duration,
                        participants: participantNames
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

    /// Fetch participant display names from the conversation
    private func fetchParticipantNames() async -> [String] {
        do {
            // Fetch conversation from Firestore
            let db = Firestore.firestore()
            let conversationDoc = try await db.collection(Constants.Collections.conversations)
                .document(conversationID)
                .getDocument()

            guard let data = conversationDoc.data(),
                  let participantIDs = data["participantIDs"] as? [String] else {
                print("⚠️ No participants found in conversation")
                return []
            }

            print("📋 Found \(participantIDs.count) participants in conversation")

            // Fetch each participant's display name
            var names: [String] = []
            for userID in participantIDs {
                let userDoc = try await db.collection(Constants.Collections.users)
                    .document(userID)
                    .getDocument()

                if let userData = userDoc.data(),
                   let displayName = userData["displayName"] as? String {
                    names.append(displayName)
                } else {
                    // Fallback to "User" if name not found
                    names.append("User")
                }
            }

            print("✅ Fetched participant names: \(names.joined(separator: ", "))")
            return names

        } catch {
            print("❌ Error fetching participant names: \(error)")
            return []
        }
    }

    func selectTimeSlot(_ timeSlot: TimeSlot) {
        print("📅 Selected time slot: \(timeSlot.date.formatted()) at \(timeSlot.startTime)")

        isCreatingEvent = true
        eventCreationError = nil

        Task {
            let success = await createCalendarEvent(for: timeSlot)

            if success {
                await sendConfirmationMessage(for: timeSlot)
                showEventCreatedAlert = true
            } else {
                showEventErrorAlert = true
            }

            isCreatingEvent = false
            // Don't auto-close - let user dismiss the alert manually
        }
    }

    private func createCalendarEvent(for timeSlot: TimeSlot) async -> Bool {
        guard let suggestion = meetingSuggestion else {
            print("⚠️ No meeting suggestion available")
            eventCreationError = "No meeting information available"
            return false
        }

        // Check if Apple Calendar is authorized
        guard AppleCalendarService.shared.isAuthorized else {
            print("⚠️ Calendar access not authorized")
            eventCreationError = "Calendar access not granted. Please enable calendar access in Settings."
            return false
        }

        // Combine date and time into start/end dates
        let startDate = combineDateAndTime(date: timeSlot.date, time: timeSlot.startTime)
        let endDate = combineDateAndTime(date: timeSlot.date, time: timeSlot.endTime)

        // Create calendar event using EventKit
        do {
            let eventID = try await AppleCalendarService.shared.createEvent(
                title: suggestion.detectedIntent,
                startDate: startDate,
                endDate: endDate,
                notes: "Scheduled via Yaip\nParticipants: \(suggestion.participants.joined(separator: ", "))"
            )
            print("✅ Calendar event created: \(eventID)")
            return true
        } catch {
            print("❌ Failed to create calendar event: \(error)")
            eventCreationError = error.localizedDescription
            return false
        }
    }

    private func sendConfirmationMessage(for timeSlot: TimeSlot) async {
        guard let suggestion = meetingSuggestion else { return }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let startDate = combineDateAndTime(date: timeSlot.date, time: timeSlot.startTime)

        let confirmationText = """
        📅 Meeting scheduled: \(suggestion.detectedIntent)
        🗓 \(formatter.string(from: startDate))
        ⏱ Duration: \(suggestion.duration) minutes
        👥 Participants: \(suggestion.participants.joined(separator: ", "))
        """

        // TODO: Send this as a message to the conversation
        print("💬 Confirmation message: \(confirmationText)")
    }

    /// Combine date and time string into a single Date
    private func combineDateAndTime(date: Date, time: String) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        // Parse time string (e.g., "14:00")
        let timeComponents = time.split(separator: ":")
        guard timeComponents.count == 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            return date
        }

        var components = dateComponents
        components.hour = hour
        components.minute = minute
        components.second = 0

        return calendar.date(from: components) ?? date
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
