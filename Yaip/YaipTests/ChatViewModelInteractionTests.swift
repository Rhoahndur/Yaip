import XCTest
@testable import Yaip

@MainActor
final class ChatViewModelInteractionTests: XCTestCase {

    private var viewModel: ChatViewModel!
    private var mockMessageService: MockMessageService!
    private var mockAuthManager: MockAuthManager!

    override func setUp() {
        super.setUp()
        mockMessageService = MockMessageService()
        mockAuthManager = MockAuthManager()

        viewModel = ChatViewModel(
            conversation: TestFixtures.conversation(),
            messageService: mockMessageService,
            conversationService: MockConversationService(),
            authManager: mockAuthManager,
            localStorage: MockLocalStorageManager(),
            imageUploadManager: MockImageUploadManager(),
            networkMonitor: MockNetworkMonitor()
        )
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Reactions

    func testToggleReactionAddsReaction() async {
        let msg = TestFixtures.message(id: "msg1", reactions: [:])
        viewModel.messages = [msg]

        await viewModel.toggleReaction(emoji: "👍", message: msg)

        XCTAssertEqual(viewModel.messages[0].reactions["👍"], ["currentUser"])
        XCTAssertEqual(mockMessageService.toggledReactions.count, 1)
    }

    func testToggleReactionRemovesExisting() async {
        let msg = TestFixtures.message(id: "msg1", reactions: ["👍": ["currentUser"]])
        viewModel.messages = [msg]

        await viewModel.toggleReaction(emoji: "👍", message: msg)

        XCTAssertNil(viewModel.messages[0].reactions["👍"])
    }

    func testToggleReactionFailureShowsError() async {
        mockMessageService.shouldFail = true
        let msg = TestFixtures.message(id: "msg1")
        viewModel.messages = [msg]

        await viewModel.toggleReaction(emoji: "👍", message: msg)

        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Delete

    func testDeleteMessageOptimisticallyMarksDeleted() async {
        let msg = TestFixtures.message(id: "msg1")
        viewModel.messages = [msg]

        await viewModel.deleteMessage(msg)

        XCTAssertTrue(viewModel.messages[0].isDeleted)
        XCTAssertEqual(viewModel.messages[0].text, "[Message deleted]")
    }

    func testDeleteMessageRevertsOnFailure() async {
        mockMessageService.shouldFail = true
        let msg = TestFixtures.message(id: "msg1", text: "Original")
        viewModel.messages = [msg]

        await viewModel.deleteMessage(msg)

        XCTAssertFalse(viewModel.messages[0].isDeleted)
    }

    func testDeleteMessageCallsService() async {
        let msg = TestFixtures.message(id: "msg1")
        viewModel.messages = [msg]

        await viewModel.deleteMessage(msg)

        XCTAssertEqual(mockMessageService.deletedMessages.count, 1)
        XCTAssertEqual(mockMessageService.deletedMessages[0].messageID, "msg1")
    }

    // MARK: - Reply

    func testSetReplyTo() {
        let msg = TestFixtures.message(id: "msg1")
        viewModel.setReplyTo(msg)

        XCTAssertEqual(viewModel.replyingTo?.id, "msg1")
    }

    func testClearReply() {
        viewModel.setReplyTo(TestFixtures.message())
        viewModel.clearReply()

        XCTAssertNil(viewModel.replyingTo)
    }

    func testGetReplyToMessage() {
        let parent = TestFixtures.message(id: "parent")
        let reply = TestFixtures.message(id: "reply", replyTo: "parent")
        viewModel.messages = [parent, reply]

        let result = viewModel.getReplyToMessage(for: reply)

        XCTAssertEqual(result?.id, "parent")
    }

    func testGetReplyToMessageReturnsNilWhenNoReply() {
        let msg = TestFixtures.message(id: "msg1")
        viewModel.messages = [msg]

        let result = viewModel.getReplyToMessage(for: msg)

        XCTAssertNil(result)
    }
}
