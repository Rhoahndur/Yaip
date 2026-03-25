import Foundation
@testable import Yaip

final class MockAuthManager: AuthManagerProtocol {
    var user: User?
    var isAuthenticated: Bool = true
    var isLoading: Bool = false
    var currentUserID: String? = "currentUser"
    var currentUser: User? { user }

    func refreshCurrentUser() {}
    func signUp(email: String, password: String, displayName: String) async throws {}
    func signIn(email: String, password: String) async throws {}
    func signOut() async throws {}
    func resetPassword(email: String) async throws {}
    func deleteAccount() async throws {}
}
