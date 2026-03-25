import XCTest
@testable import Yaip

@MainActor
final class ConversationListViewModelTests: XCTestCase {

    private var viewModel: ConversationListViewModel!
    private var mockConversationService: MockConversationService!
    private var mockAuthManager: MockAuthManager!
    private var mockLocalStorage: MockLocalStorageManager!

    override func setUp() {
        super.setUp()
        mockConversationService = MockConversationService()
        mockAuthManager = MockAuthManager()
        mockLocalStorage = MockLocalStorageManager()

        viewModel = ConversationListViewModel(
            conversationService: mockConversationService,
            authManager: mockAuthManager,
            localStorage: mockLocalStorage
        )
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Filtering

    func testFilteredConversationsReturnsAllWhenNotFiltering() {
        viewModel.conversations = [
            TestFixtures.conversation(id: "c1"),
            TestFixtures.conversation(id: "c2")
        ]
        viewModel.showUnreadOnly = false

        XCTAssertEqual(viewModel.filteredConversations.count, 2)
    }

    func testFilteredConversationsShowsOnlyUnread() {
        viewModel.conversations = [
            TestFixtures.conversation(id: "c1", unreadCount: ["currentUser": 3]),
            TestFixtures.conversation(id: "c2", unreadCount: ["currentUser": 0])
        ]
        viewModel.showUnreadOnly = true

        XCTAssertEqual(viewModel.filteredConversations.count, 1)
        XCTAssertEqual(viewModel.filteredConversations[0].id, "c1")
    }

    func testFilteredConversationsHandlesNoUnreadCount() {
        viewModel.conversations = [
            TestFixtures.conversation(id: "c1", unreadCount: [:])
        ]
        viewModel.showUnreadOnly = true

        XCTAssertEqual(viewModel.filteredConversations.count, 0)
    }

    // MARK: - Self-Chat Exclusion

    func testExcludingSelfChatsFilters() {
        let selfChat = TestFixtures.conversation(
            id: "self",
            type: .oneOnOne,
            participants: ["currentUser", "currentUser"]
        )
        let normalChat = TestFixtures.conversation(id: "normal")

        let result = [selfChat, normalChat].excludingSelfChats()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "normal")
    }

    func testExcludingSelfChatsKeepsGroupChats() {
        let groupWithSelf = TestFixtures.groupConversation(
            id: "g1",
            participants: ["currentUser", "currentUser", "other"]
        )

        let result = [groupWithSelf].excludingSelfChats()

        XCTAssertEqual(result.count, 1)
    }

    // MARK: - Toggle Filter

    func testToggleFilterUnread() {
        XCTAssertFalse(viewModel.showUnreadOnly)
        viewModel.toggleFilterUnread()
        XCTAssertTrue(viewModel.showUnreadOnly)
        viewModel.toggleFilterUnread()
        XCTAssertFalse(viewModel.showUnreadOnly)
    }
}
