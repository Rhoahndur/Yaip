import XCTest
@testable import Yaip

final class MessageStatusTests: XCTestCase {

    // MARK: - isLocal

    func testStagedIsLocal() {
        XCTAssertTrue(MessageStatus.staged.isLocal)
    }

    func testSendingIsLocal() {
        XCTAssertTrue(MessageStatus.sending.isLocal)
    }

    func testFailedIsLocal() {
        XCTAssertTrue(MessageStatus.failed.isLocal)
    }

    func testSentIsNotLocal() {
        XCTAssertFalse(MessageStatus.sent.isLocal)
    }

    func testDeliveredIsNotLocal() {
        XCTAssertFalse(MessageStatus.delivered.isLocal)
    }

    func testReadIsNotLocal() {
        XCTAssertFalse(MessageStatus.read.isLocal)
    }

    // MARK: - isSynced

    func testSentIsSynced() {
        XCTAssertTrue(MessageStatus.sent.isSynced)
    }

    func testDeliveredIsSynced() {
        XCTAssertTrue(MessageStatus.delivered.isSynced)
    }

    func testReadIsSynced() {
        XCTAssertTrue(MessageStatus.read.isSynced)
    }

    func testStagedIsNotSynced() {
        XCTAssertFalse(MessageStatus.staged.isSynced)
    }

    // MARK: - isRetryable

    func testFailedIsRetryable() {
        XCTAssertTrue(MessageStatus.failed.isRetryable)
    }

    func testStagedIsNotRetryable() {
        XCTAssertFalse(MessageStatus.staged.isRetryable)
    }

    func testSentIsNotRetryable() {
        XCTAssertFalse(MessageStatus.sent.isRetryable)
    }

    // MARK: - Message computed properties

    func testIsFromCurrentUser() {
        let msg = TestFixtures.message(senderID: "user1")
        XCTAssertTrue(msg.isFromCurrentUser("user1"))
        XCTAssertFalse(msg.isFromCurrentUser("user2"))
    }

    func testTotalReactions() {
        let msg = TestFixtures.message(reactions: [
            "👍": ["u1", "u2"],
            "❤️": ["u3"]
        ])
        XCTAssertEqual(msg.totalReactions, 3)
    }

    func testUserReactedTrue() {
        let msg = TestFixtures.message(reactions: ["👍": ["u1", "u2"]])
        XCTAssertTrue(msg.userReacted(with: "👍", userID: "u1"))
    }

    func testUserReactedFalse() {
        let msg = TestFixtures.message(reactions: ["👍": ["u1"]])
        XCTAssertFalse(msg.userReacted(with: "👍", userID: "u2"))
    }

    func testUserReactedMissingEmoji() {
        let msg = TestFixtures.message(reactions: ["👍": ["u1"]])
        XCTAssertFalse(msg.userReacted(with: "❤️", userID: "u1"))
    }
}
