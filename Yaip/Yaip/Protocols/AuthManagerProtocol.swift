import Foundation

/// Contract for authentication state and operations.
///
/// Provides access to the current user, authentication status, and auth lifecycle methods.
/// Conforms to `AnyObject` because implementations are reference types observed by SwiftUI.
protocol AuthManagerProtocol: AnyObject {
    /// The currently authenticated user model, or `nil` if not signed in.
    var user: User? { get }
    /// Whether a user is currently authenticated.
    var isAuthenticated: Bool { get }
    /// Whether an auth operation is in progress.
    var isLoading: Bool { get }
    /// The Firebase UID of the current user, or `nil`.
    var currentUserID: String? { get }
    /// Alias for `user` — the current authenticated user.
    var currentUser: User? { get }

    /// Re-fetch the current user's profile from Firestore.
    func refreshCurrentUser()
    /// Create a new account with email/password and set the display name.
    func signUp(email: String, password: String, displayName: String) async throws
    /// Sign in with email and password.
    func signIn(email: String, password: String) async throws
    /// Sign out the current user and clean up local state.
    func signOut() async throws
    /// Send a password reset email.
    func resetPassword(email: String) async throws
    /// Permanently delete the current user's account and data.
    func deleteAccount() async throws
    /// Whether a newly signed-up user still needs to complete profile setup.
    var needsProfileSetup: Bool { get }
    /// Mark the onboarding profile setup step as complete.
    func completeProfileSetup()
}
