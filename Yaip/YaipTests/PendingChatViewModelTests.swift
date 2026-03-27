import XCTest
import UIKit
@testable import Yaip

@MainActor
final class PendingChatViewModelTests: XCTestCase {

    private var viewModel: PendingChatViewModel!
    private var mockConversationService: MockConversationService!
    private var mockMessageService: MockMessageService!
    private var mockStorageService: MockStorageService!
    private var mockAuthManager: MockAuthManager!

    override func setUp() {
        super.setUp()
        mockConversationService = MockConversationService()
        mockMessageService = MockMessageService()
        mockStorageService = MockStorageService()
        mockAuthManager = MockAuthManager()
        mockAuthManager.currentUserID = "currentUser"

        viewModel = PendingChatViewModel(
            pendingConversation: TestFixtures.pendingConversation(),
            conversationService: mockConversationService,
            messageService: mockMessageService,
            storageService: mockStorageService,
            authManager: mockAuthManager
        )
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Display Name

    func testDisplayNameReturnsGroupName() {
        let vm = PendingChatViewModel(
            pendingConversation: TestFixtures.pendingConversation(
                type: .group,
                participants: ["currentUser", "user2", "user3"],
                name: "Project Team"
            ),
            conversationService: mockConversationService,
            messageService: mockMessageService,
            storageService: mockStorageService,
            authManager: mockAuthManager
        )
        XCTAssertEqual(vm.displayName, "Project Team")
    }

    func testDisplayNameReturnsNewChatForOneOnOne() {
        XCTAssertEqual(viewModel.displayName, "New Chat")
    }

    // MARK: - Send First Message

    func testSendFirstMessageCreatesConversation() async {
        viewModel.messageText = "Hello!"
        await viewModel.sendFirstMessage()

        XCTAssertEqual(mockConversationService.createdConversations.count, 1)
    }

    func testSendFirstMessageSendsMessage() async {
        viewModel.messageText = "Hello!"
        await viewModel.sendFirstMessage()

        XCTAssertEqual(mockMessageService.sentMessages.count, 1)
        XCTAssertEqual(mockMessageService.sentMessages.first?.text, "Hello!")
    }

    func testSendFirstMessageUpdatesLastMessage() async {
        viewModel.messageText = "Hello!"
        await viewModel.sendFirstMessage()

        XCTAssertEqual(mockConversationService.updatedLastMessages.count, 1)
        XCTAssertEqual(mockConversationService.updatedLastMessages.first?.lastMessage.text, "Hello!")
    }

    func testSendFirstMessageSetsConversationCreated() async {
        viewModel.messageText = "Hello!"
        await viewModel.sendFirstMessage()

        XCTAssertTrue(viewModel.conversationCreated)
        XCTAssertNotNil(viewModel.createdConversation)
    }

    func testSendFirstMessageClearsInput() async {
        viewModel.messageText = "Hello!"
        await viewModel.sendFirstMessage()

        XCTAssertEqual(viewModel.messageText, "")
        XCTAssertNil(viewModel.selectedImage)
        XCTAssertFalse(viewModel.isCreating)
    }

    func testSendFirstMessageWithImageUploads() async {
        viewModel.messageText = "Check this out"
        viewModel.selectedImage = UIImage()
        await viewModel.sendFirstMessage()

        XCTAssertEqual(mockStorageService.uploadedImages.count, 1)
        XCTAssertEqual(mockMessageService.sentMessages.first?.mediaType, .image)
        XCTAssertNotNil(mockMessageService.sentMessages.first?.mediaURL)
    }

    func testSendFirstMessageIgnoresEmptyText() async {
        viewModel.messageText = "   "
        await viewModel.sendFirstMessage()

        XCTAssertEqual(mockConversationService.createdConversations.count, 0)
        XCTAssertEqual(mockMessageService.sentMessages.count, 0)
    }

    func testSendFirstMessageRequiresAuth() async {
        mockAuthManager.currentUserID = nil
        viewModel.messageText = "Hello!"
        await viewModel.sendFirstMessage()

        XCTAssertEqual(viewModel.errorMessage, "User not authenticated")
        XCTAssertEqual(mockConversationService.createdConversations.count, 0)
    }

    func testSendFirstMessageHandlesConversationError() async {
        mockConversationService.shouldFail = true
        viewModel.messageText = "Hello!"
        await viewModel.sendFirstMessage()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isCreating)
        XCTAssertFalse(viewModel.conversationCreated)
    }

    func testSendFirstMessageHandlesMessageError() async {
        mockMessageService.shouldFail = true
        viewModel.messageText = "Hello!"
        await viewModel.sendFirstMessage()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isCreating)
    }

    func testSendFirstMessageHandlesImageUploadError() async {
        mockStorageService.shouldFail = true
        viewModel.messageText = "Photo"
        viewModel.selectedImage = UIImage()
        await viewModel.sendFirstMessage()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isCreating)
    }

    func testSendFirstMessageSetsCorrectSenderID() async {
        viewModel.messageText = "Hello!"
        await viewModel.sendFirstMessage()

        XCTAssertEqual(mockMessageService.sentMessages.first?.senderID, "currentUser")
    }

    func testSendFirstMessageTrimsWhitespace() async {
        viewModel.messageText = "  Hello!  "
        await viewModel.sendFirstMessage()

        XCTAssertEqual(mockMessageService.sentMessages.first?.text, "Hello!")
    }
}
