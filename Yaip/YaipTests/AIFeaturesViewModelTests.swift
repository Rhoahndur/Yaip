import XCTest
@testable import Yaip

@MainActor
final class AIFeaturesViewModelTests: XCTestCase {

    private var viewModel: AIFeaturesViewModel!
    private var mockN8N: MockN8NService!
    private var mockAuthManager: MockAuthManager!
    private var mockMessageService: MockMessageService!
    private var mockConversationService: MockConversationService!
    private var mockCalendarManager: MockCalendarManager!
    private var mockEventCreator: MockEventCreator!

    override func setUp() {
        super.setUp()
        mockN8N = MockN8NService()
        mockAuthManager = MockAuthManager()
        mockAuthManager.currentUserID = "currentUser"
        mockMessageService = MockMessageService()
        mockConversationService = MockConversationService()
        mockCalendarManager = MockCalendarManager()
        mockEventCreator = MockEventCreator()

        viewModel = AIFeaturesViewModel(
            conversationID: "conv1",
            n8nService: mockN8N,
            authManager: mockAuthManager,
            messageService: mockMessageService,
            conversationService: mockConversationService,
            calendarManager: mockCalendarManager,
            eventCreator: mockEventCreator
        )
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Summarize Thread

    func testSummarizeThreadSuccess() async {
        let summary = TestFixtures.threadSummary()
        mockN8N.summarizeResult = summary

        viewModel.summarizeThread()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(viewModel.currentSummary?.summary, summary.summary)
        XCTAssertEqual(viewModel.currentSummary?.messageCount, summary.messageCount)
        XCTAssertTrue(viewModel.showSummary)
        XCTAssertFalse(viewModel.isLoadingSummary)
        XCTAssertNil(viewModel.summaryError)
    }

    func testSummarizeThreadError() async {
        mockN8N.errorToThrow = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "AI unavailable"])

        viewModel.summarizeThread()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertNil(viewModel.currentSummary)
        XCTAssertNotNil(viewModel.summaryError)
        XCTAssertFalse(viewModel.isLoadingSummary)
    }

    // MARK: - Action Items

    func testExtractActionItemsSuccess() async {
        let items = [
            TestFixtures.actionItem(id: "a1", task: "Fix bug"),
            TestFixtures.actionItem(id: "a2", task: "Write tests")
        ]
        mockN8N.actionItemsResult = items

        viewModel.extractActionItems()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(viewModel.actionItems.count, 2)
        XCTAssertTrue(viewModel.showActionItems)
        XCTAssertFalse(viewModel.isLoadingActionItems)
        XCTAssertNil(viewModel.actionItemsError)
    }

    func testExtractActionItemsError() async {
        mockN8N.errorToThrow = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed"])

        viewModel.extractActionItems()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(viewModel.actionItems.isEmpty)
        XCTAssertNotNil(viewModel.actionItemsError)
        XCTAssertFalse(viewModel.isLoadingActionItems)
    }

    func testToggleActionItemPendingToCompleted() {
        let item = TestFixtures.actionItem(status: .pending)
        viewModel.actionItems = [item]

        viewModel.toggleActionItem(item)

        XCTAssertEqual(viewModel.actionItems.first?.status, .completed)
    }

    func testToggleActionItemCompletedToPending() {
        let item = TestFixtures.actionItem(status: .completed)
        viewModel.actionItems = [item]

        viewModel.toggleActionItem(item)

        XCTAssertEqual(viewModel.actionItems.first?.status, .pending)
    }

    func testToggleActionItemNoOpForMissingItem() {
        let item = TestFixtures.actionItem(id: "nonexistent")
        viewModel.actionItems = [TestFixtures.actionItem(id: "other")]

        viewModel.toggleActionItem(item)

        XCTAssertEqual(viewModel.actionItems.first?.id, "other")
    }

    // MARK: - Decisions

    func testExtractDecisionsSuccess() async {
        let decisions = [
            TestFixtures.decision(id: "d1"),
            TestFixtures.decision(id: "d2")
        ]
        mockN8N.decisionsResult = decisions

        viewModel.extractDecisions()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(viewModel.decisions.count, 2)
        XCTAssertTrue(viewModel.showDecisions)
        XCTAssertFalse(viewModel.isLoadingDecisions)
        XCTAssertNil(viewModel.decisionsError)
    }

    func testExtractDecisionsError() async {
        mockN8N.errorToThrow = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed"])

        viewModel.extractDecisions()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(viewModel.decisions.isEmpty)
        XCTAssertNotNil(viewModel.decisionsError)
        XCTAssertFalse(viewModel.isLoadingDecisions)
    }

    // MARK: - Priority Detection

    func testDetectPrioritySuccess() async {
        let messages = [
            TestFixtures.priorityMessage(messageID: "p1"),
            TestFixtures.priorityMessage(messageID: "p2")
        ]
        mockN8N.priorityResult = messages

        viewModel.detectPriority()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(viewModel.priorityMessages.count, 2)
        XCTAssertTrue(viewModel.showPriority)
        XCTAssertFalse(viewModel.isLoadingPriority)
        XCTAssertNil(viewModel.priorityError)
    }

    func testDetectPriorityError() async {
        mockN8N.errorToThrow = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed"])

        viewModel.detectPriority()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(viewModel.priorityMessages.isEmpty)
        XCTAssertNotNil(viewModel.priorityError)
        XCTAssertFalse(viewModel.isLoadingPriority)
    }

    // MARK: - Search (Basic)

    func testSearchMessagesBasic() async {
        viewModel.useRAGSearch = false
        let results = [TestFixtures.searchResult(messageID: "s1")]
        mockN8N.searchResult = results

        viewModel.searchMessages(query: "test")
        try? await Task.sleep(for: .milliseconds(700))

        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertNil(viewModel.aiAnswer)
        XCTAssertFalse(viewModel.isSearching)
    }

    func testSearchMessagesRAG() async {
        viewModel.useRAGSearch = true
        let ragResult = TestFixtures.ragSearchResult()
        mockN8N.ragResult = ragResult

        viewModel.searchMessages(query: "test")
        try? await Task.sleep(for: .milliseconds(700))

        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertNotNil(viewModel.aiAnswer)
        XCTAssertFalse(viewModel.isSearching)
    }

    func testSearchMessagesRAGNoResultsClearsAIAnswer() async {
        viewModel.useRAGSearch = true
        mockN8N.ragResult = RAGSearchResult(
            results: [],
            aiAnswer: "Some answer",
            answerSources: [],
            query: "test"
        )

        viewModel.searchMessages(query: "test")
        try? await Task.sleep(for: .milliseconds(700))

        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertNil(viewModel.aiAnswer)
    }

    func testSearchMessagesEmptyQueryClears() {
        viewModel.searchResults = [TestFixtures.searchResult()]
        viewModel.aiAnswer = "old answer"

        viewModel.searchMessages(query: "")

        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertNil(viewModel.aiAnswer)
    }

    func testSearchMessagesError() async {
        viewModel.useRAGSearch = false
        mockN8N.errorToThrow = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Search failed"])

        viewModel.searchMessages(query: "test")
        try? await Task.sleep(for: .milliseconds(700))

        XCTAssertNotNil(viewModel.searchError)
        XCTAssertFalse(viewModel.isSearching)
    }

    func testClearSearch() {
        viewModel.searchQuery = "old"
        viewModel.searchResults = [TestFixtures.searchResult()]
        viewModel.ragSearchResult = TestFixtures.ragSearchResult()
        viewModel.aiAnswer = "answer"
        viewModel.searchError = "error"

        viewModel.clearSearch()

        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertNil(viewModel.ragSearchResult)
        XCTAssertNil(viewModel.aiAnswer)
        XCTAssertNil(viewModel.searchError)
    }

    // MARK: - Dismiss All Modals

    func testDismissAllModals() {
        viewModel.showSummary = true
        viewModel.showActionItems = true
        viewModel.showMeetingSuggestion = true
        viewModel.showDecisions = true
        viewModel.showPriority = true
        viewModel.showSearch = true

        viewModel.dismissAllModals()

        XCTAssertFalse(viewModel.showSummary)
        XCTAssertFalse(viewModel.showActionItems)
        XCTAssertFalse(viewModel.showMeetingSuggestion)
        XCTAssertFalse(viewModel.showDecisions)
        XCTAssertFalse(viewModel.showPriority)
        XCTAssertFalse(viewModel.showSearch)
    }

    // MARK: - Calendar Event Creation

    func testSelectTimeSlotCreatesEvent() async {
        mockEventCreator.isAuthorized = true
        let suggestion = TestFixtures.meetingSuggestion()
        viewModel.meetingSuggestion = suggestion

        let timeSlot = suggestion.suggestedTimes[0]
        viewModel.selectTimeSlot(timeSlot)
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertEqual(mockEventCreator.createdEvents.count, 1)
        XCTAssertEqual(mockEventCreator.createdEvents.first?.title, suggestion.detectedIntent)
        XCTAssertTrue(viewModel.showEventCreatedAlert)
        XCTAssertFalse(viewModel.isCreatingEvent)
    }

    func testSelectTimeSlotSendsConfirmation() async {
        mockEventCreator.isAuthorized = true
        let suggestion = TestFixtures.meetingSuggestion()
        viewModel.meetingSuggestion = suggestion

        let timeSlot = suggestion.suggestedTimes[0]
        viewModel.selectTimeSlot(timeSlot)
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertEqual(mockMessageService.sentMessages.count, 1)
        XCTAssertTrue(mockMessageService.sentMessages.first?.text?.contains("Meeting scheduled") ?? false)
    }

    func testSelectTimeSlotUnauthorizedShowsError() async {
        mockEventCreator.isAuthorized = false
        viewModel.meetingSuggestion = TestFixtures.meetingSuggestion()

        let timeSlot = viewModel.meetingSuggestion!.suggestedTimes[0]
        viewModel.selectTimeSlot(timeSlot)
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertTrue(viewModel.showEventErrorAlert)
        XCTAssertNotNil(viewModel.eventCreationError)
        XCTAssertFalse(viewModel.isCreatingEvent)
    }

    func testSelectTimeSlotHandlesCreateError() async {
        mockEventCreator.isAuthorized = true
        mockEventCreator.shouldFail = true
        viewModel.meetingSuggestion = TestFixtures.meetingSuggestion()

        let timeSlot = viewModel.meetingSuggestion!.suggestedTimes[0]
        viewModel.selectTimeSlot(timeSlot)
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertTrue(viewModel.showEventErrorAlert)
        XCTAssertFalse(viewModel.isCreatingEvent)
    }

    // MARK: - Loading State

    func testSummarizeThreadSetsLoadingState() {
        mockN8N.summarizeResult = TestFixtures.threadSummary()

        viewModel.summarizeThread()

        XCTAssertTrue(viewModel.isLoadingSummary)
    }

    func testExtractActionItemsSetsLoadingState() {
        viewModel.extractActionItems()

        XCTAssertTrue(viewModel.isLoadingActionItems)
    }

    func testExtractDecisionsSetsLoadingState() {
        viewModel.extractDecisions()

        XCTAssertTrue(viewModel.isLoadingDecisions)
    }

    func testDetectPrioritySetsLoadingState() {
        viewModel.detectPriority()

        XCTAssertTrue(viewModel.isLoadingPriority)
    }
}
