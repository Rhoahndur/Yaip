import XCTest
@testable import Yaip

@MainActor
final class ChatViewModelSendTests: XCTestCase {

    private var viewModel: ChatViewModel!
    private var mockMessageService: MockMessageService!
    private var mockConversationService: MockConversationService!
    private var mockAuthManager: MockAuthManager!
    private var mockLocalStorage: MockLocalStorageManager!
    private var mockImageUploadManager: MockImageUploadManager!
    private var mockNetworkMonitor: MockNetworkMonitor!

    override func setUp() {
        super.setUp()
        mockMessageService = MockMessageService()
        mockConversationService = MockConversationService()
        mockAuthManager = MockAuthManager()
        mockLocalStorage = MockLocalStorageManager()
        mockImageUploadManager = MockImageUploadManager()
        mockNetworkMonitor = MockNetworkMonitor()

        viewModel = ChatViewModel(
            conversation: TestFixtures.conversation(),
            messageService: mockMessageService,
            conversationService: mockConversationService,
            authManager: mockAuthManager,
            localStorage: mockLocalStorage,
            imageUploadManager: mockImageUploadManager,
            networkMonitor: mockNetworkMonitor
        )
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Send Message Lifecycle

    func testSendMessageAppendsToMessages() async {
        viewModel.messageText = "Hello world"
        await viewModel.sendMessage()

        XCTAssertEqual(viewModel.messages.count, 1)
    }

    func testSendMessageClearsInput() async {
        viewModel.messageText = "Hello"
        await viewModel.sendMessage()

        XCTAssertEqual(viewModel.messageText, "")
        XCTAssertNil(viewModel.selectedImage)
    }

    func testSendMessageCallsFirestore() async {
        viewModel.messageText = "Hello"
        await viewModel.sendMessage()

        XCTAssertEqual(mockMessageService.sentMessages.count, 1)
        XCTAssertEqual(mockMessageService.sentMessages[0].text, "Hello")
    }

    func testSendMessageSavesToLocalStorage() async {
        viewModel.messageText = "Test"
        await viewModel.sendMessage()

        XCTAssertEqual(mockLocalStorage.savedMessages.count, 1)
    }

    func testSendMessageUpdatesConversationLastMessage() async {
        viewModel.messageText = "Last msg"
        await viewModel.sendMessage()

        XCTAssertEqual(mockConversationService.updatedLastMessages.count, 1)
        XCTAssertEqual(mockConversationService.updatedLastMessages[0].lastMessage.text, "Last msg")
    }

    func testSendEmptyMessageDoesNothing() async {
        viewModel.messageText = "   "
        await viewModel.sendMessage()

        XCTAssertEqual(viewModel.messages.count, 0)
        XCTAssertEqual(mockMessageService.sentMessages.count, 0)
    }

    func testSendMessageMarksAsSentOnSuccess() async {
        viewModel.messageText = "Success"
        await viewModel.sendMessage()

        XCTAssertEqual(viewModel.messages[0].status, .sent)
    }

    func testSendMessageMarksAsFailedOnError() async {
        mockMessageService.shouldFail = true
        viewModel.messageText = "Fail"
        await viewModel.sendMessage()

        XCTAssertEqual(viewModel.messages[0].status, .failed)
    }

    func testSendWithoutAuthDoesNothing() async {
        mockAuthManager.currentUserID = nil
        viewModel.messageText = "Test"
        await viewModel.sendMessage()

        XCTAssertEqual(viewModel.messages.count, 0)
    }

    // MARK: - Retry Tests

    func testRetryFailedMessage() async {
        let failedMsg = TestFixtures.failedMessage(id: "f1", text: "Retry me")
        viewModel.messages = [failedMsg]

        await viewModel.retryMessage(failedMsg)

        XCTAssertEqual(mockMessageService.sentMessages.count, 1)
    }

    func testRetryAllSkipsWhenOffline() async {
        mockNetworkMonitor.isConnected = false
        viewModel.messages = [TestFixtures.stagedMessage()]

        await viewModel.retryAllFailedMessages()

        XCTAssertEqual(mockMessageService.sentMessages.count, 0)
    }

    func testRetryAllRetriesStagedMessages() async {
        mockNetworkMonitor.isConnected = true
        let staged = TestFixtures.stagedMessage(id: "s1")
        viewModel.messages = [staged]

        await viewModel.retryAllFailedMessages()

        XCTAssertEqual(mockMessageService.sentMessages.count, 1)
    }
}
