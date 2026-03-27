import Foundation
import FirebaseFirestore
@testable import Yaip

final class MockPresenceService: PresenceServiceProtocol {
    var userStatuses: [String: UserStatus] = [:]
    var shouldFail = false

    func setOnline(userID: String) async throws {
        if shouldFail { throw NSError(domain: "Test", code: 1) }
        userStatuses[userID] = .online
    }

    func setOffline(userID: String) async throws {
        if shouldFail { throw NSError(domain: "Test", code: 1) }
        userStatuses[userID] = .offline
    }

    func updateStatus(_ status: UserStatus, for userID: String) async throws {
        if shouldFail { throw NSError(domain: "Test", code: 1) }
        userStatuses[userID] = status
    }

    func listenToPresence(userID: String, completion: @escaping (UserStatus, Date?) -> Void) -> ListenerRegistration {
        let status = userStatuses[userID] ?? .offline
        completion(status, Date())
        return MockListenerRegistration()
    }

    func listenToMultiplePresence(userIDs: [String], completion: @escaping ([String: (UserStatus, Date?)]) -> Void) -> [ListenerRegistration] {
        var presenceMap: [String: (UserStatus, Date?)] = [:]
        for userID in userIDs {
            presenceMap[userID] = (userStatuses[userID] ?? .offline, Date())
        }
        completion(presenceMap)
        return userIDs.map { _ in MockListenerRegistration() }
    }
}
