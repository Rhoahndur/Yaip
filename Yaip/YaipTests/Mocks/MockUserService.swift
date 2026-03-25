import Foundation
import FirebaseFirestore
@testable import Yaip

final class MockUserService: UserServiceProtocol {
    var users: [String: User] = [:]
    var shouldFail = false

    func fetchUser(id: String, forceRefresh: Bool) async throws -> User {
        if shouldFail { throw NSError(domain: "Test", code: 1) }
        guard let user = users[id] else { throw NSError(domain: "Test", code: 404) }
        return user
    }

    func listenToUser(id: String, onChange: @escaping (User) -> Void) -> ListenerRegistration {
        if let user = users[id] { onChange(user) }
        return MockListenerRegistration()
    }

    func fetchUsers(ids: [String]) async throws -> [User] {
        ids.compactMap { users[$0] }
    }

    func updateProfile(userID: String, displayName: String?, photoURL: String?) async throws {}
    func updateDisplayName(userID: String, displayName: String) async throws {}
    func updateProfilePhoto(userID: String, photoURL: String) async throws {}

    func searchUsers(query: String) async throws -> [User] {
        users.values.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
    }

    func clearCache() {}
    func invalidateCache(for userID: String) {}
}
