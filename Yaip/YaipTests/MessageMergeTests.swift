import XCTest
@testable import Yaip

@MainActor
final class MessageMergeTests: XCTestCase {

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
        mockNetworkMonitor.isConnected = false // Prevent auto-retry during merge tests

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

    // MARK: - Merge Tests

    func testMergePreservesLocalStates() {
        // Local message in .staged state
        let localMsg = TestFixtures.message(id: "msg1", status: .staged)
        viewModel.messages = [localMsg]

        // Same message arrives from Firestore as .sent
        let firestoreMsg = TestFixtures.message(id: "msg1", status: .sent)

        viewModel.mergeMessages(firestoreMessages: [firestoreMsg])

        // Should keep local .staged version
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages[0].status, .staged)
    }

    func testMergeUsesFirestoreForSyncedStates() {
        // Local message already synced (.sent)
        let localMsg = TestFixtures.message(id: "msg1", status: .sent, readBy: ["currentUser"])
        viewModel.messages = [localMsg]

        // Firestore version has updated readBy (read receipt)
        let firestoreMsg = TestFixtures.message(id: "msg1", status: .read, readBy: ["currentUser", "otherUser"])

        viewModel.mergeMessages(firestoreMessages: [firestoreMsg])

        // Should use Firestore version
        XCTAssertEqual(viewModel.messages[0].status, .read)
        XCTAssertEqual(viewModel.messages[0].readBy.count, 2)
    }

    func testMergeKeepsLocalOnlyMessages() {
        // Local message not yet in Firestore
        let localOnly = TestFixtures.stagedMessage(id: "local1")
        viewModel.messages = [localOnly]

        // Firestore has different messages
        let firestoreMsg = TestFixtures.message(id: "cloud1", status: .sent)

        viewModel.mergeMessages(firestoreMessages: [firestoreMsg])

        // Should have both
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertTrue(viewModel.messages.contains { $0.id == "local1" })
        XCTAssertTrue(viewModel.messages.contains { $0.id == "cloud1" })
    }

    func testMergeSortsByTimestamp() {
        let older = TestFixtures.message(
            id: "msg1",
            timestamp: Date(timeIntervalSince1970: 1000),
            status: .sent
        )
        let newer = TestFixtures.message(
            id: "msg2",
            timestamp: Date(timeIntervalSince1970: 2000),
            status: .sent
        )

        viewModel.mergeMessages(firestoreMessages: [newer, older])

        XCTAssertEqual(viewModel.messages[0].id, "msg1")
        XCTAssertEqual(viewModel.messages[1].id, "msg2")
    }

    func testMergeDropsSyncedLocalNotInFirestore() {
        // Local message that was synced (.sent) but isn't in Firestore anymore
        let localSynced = TestFixtures.message(id: "deleted1", status: .sent)
        viewModel.messages = [localSynced]

        // Firestore doesn't include it
        viewModel.mergeMessages(firestoreMessages: [])

        // Should be dropped (Firestore is source of truth for synced messages)
        XCTAssertEqual(viewModel.messages.count, 0)
    }

    func testMergeWithEmptyFirestorePreservesLocalStaged() {
        let staged = TestFixtures.stagedMessage(id: "s1")
        viewModel.messages = [staged]

        viewModel.mergeMessages(firestoreMessages: [])

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages[0].id, "s1")
    }
}
