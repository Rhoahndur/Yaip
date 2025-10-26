//
//  AuthManager.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Manages user authentication state and operations
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    private let presenceService = PresenceService.shared
    
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }

    var currentUser: User? {
        return user
    }

    private init() {
        setupAuthStateListener()
    }

    /// Refresh current user data from Firestore
    func refreshCurrentUser() async {
        guard let userID = currentUserID else { return }
        fetchUserProfile(userID: userID)
    }
    
    /// Listen for authentication state changes
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                // User is signed in, fetch their profile
                self?.fetchUserProfile(userID: user.uid)
            } else {
                // User is signed out
                DispatchQueue.main.async {
                    self?.user = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    /// Fetch user profile from Firestore
    private func fetchUserProfile(userID: String) {
        Task {
            do {
                let snapshot = try await db.collection(Constants.Collections.users).document(userID).getDocument()
                
                if !snapshot.exists {
                    // User document doesn't exist in Firestore but Auth token exists
                    // This happens when:
                    // 1. Database was reset but Keychain still has auth token
                    // 2. User document was manually deleted
                    // SOLUTION: Sign them out and force re-authentication
                    print("❌ User document not found in Firestore for authenticated user")
                    print("❌ This likely means database was reset. Signing out...")
                    
                    // Sign out from Firebase Auth
                    try? Auth.auth().signOut()
                    
                    await MainActor.run {
                        self.user = nil
                        self.isAuthenticated = false
                    }
                    
                    print("✅ Signed out orphaned user. Please sign in again.")
                    return
                }
                
                // Use snapshot.data(as:) which properly handles @DocumentID
                do {
                    let user = try snapshot.data(as: User.self)
                    
                    await MainActor.run {
                        self.user = user
                        self.isAuthenticated = true
                    }
                    print("✅ User profile loaded successfully")
                } catch {
                    // Decoding failed (likely missing optional fields) - use fallback construction
                    
                    // Fallback: manually construct User from raw data
                    guard let data = snapshot.data(),
                          let displayName = data["displayName"] as? String,
                          let email = data["email"] as? String else {
                        print("❌ Error: Cannot decode user data")
                        await MainActor.run {
                            self.isAuthenticated = false
                        }
                        return
                    }
                    
                    let fallbackUser = User(
                        id: snapshot.documentID,
                        displayName: displayName,
                        email: email,
                        profileImageURL: data["profileImageURL"] as? String,
                        status: UserStatus(rawValue: data["status"] as? String ?? "online") ?? .online,
                        lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue(),  // Now optional
                        fcmToken: data["fcmToken"] as? String,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    
                    await MainActor.run {
                        self.user = fallbackUser
                        self.isAuthenticated = true
                    }
                    // Fallback user construction successful (no log needed)
                }
            } catch {
                print("❌ Error fetching user profile: \(error.localizedDescription)")
                print("❌ Full error: \(error)")
                await MainActor.run {
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    /// Sign up with email and password
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Create Firebase Auth user
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Create user document in Firestore
        let newUser = User(
            id: nil, // Let Firestore set the ID
            displayName: displayName,
            email: email,
            profileImageURL: nil,
            status: .online,
            lastSeen: Date(),
            fcmToken: nil,
            createdAt: Date()
        )
        
        try db.collection(Constants.Collections.users).document(result.user.uid).setData(from: newUser)
        
        // Fetch the user back to get the proper @DocumentID set
        fetchUserProfile(userID: result.user.uid)
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        print("🔑 Attempting sign in...")
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        print("✅ Firebase Auth sign in successful")
        
        // Fetch user profile (this triggers auth state listener)
        fetchUserProfile(userID: result.user.uid)
        
        // Try to set user online, but don't wait if network is slow (fire and forget)
        Task {
            try? await presenceService.setOnline(userID: result.user.uid)
            print("✅ Set user online in Firestore")
        }
        
        print("✅ Sign in complete")
    }
    
    /// Sign out
    func signOut() async throws {
        print("🚪 Sign out initiated")
        
        // Stop message listener immediately (doesn't require network)
        MessageListenerService.shared.stopListening()
        print("✅ Stopped message listeners")
        
        // Try to set user offline, but don't wait if network is down
        if let userID = currentUserID {
            Task {
                // Fire and forget - if network is down, it's fine
                try? await presenceService.setOffline(userID: userID)
                print("✅ Set user offline in Firestore")
            }
        }
        
        // Sign out from Firebase Auth (this works offline)
        try Auth.auth().signOut()
        print("✅ Signed out from Firebase Auth")
        
        await MainActor.run {
            self.user = nil
            self.isAuthenticated = false
        }
        print("✅ Sign out complete")
    }
    
    /// Reset password
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    /// Delete user account and all associated data
    func deleteAccount() async throws {
        guard let userID = currentUserID else {
            throw NSError(domain: "AuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
        }

        print("🗑️ Starting account deletion for user: \(userID)")

        // Stop message listeners
        MessageListenerService.shared.stopListening()
        print("✅ Stopped message listeners")

        // 1. Delete profile image from Firebase Storage
        if let profileImageURL = user?.profileImageURL {
            print("🗑️ Deleting profile image...")
            try? await StorageService.shared.deleteImage(url: profileImageURL)
            print("✅ Profile image deleted")
        }

        // 2. Delete all messages from conversations where user is a participant
        print("🗑️ Deleting user messages...")
        try? await deleteUserMessages(userID: userID)
        print("✅ User messages deleted")

        // 3. Delete user's conversations (or remove user from participant list)
        print("🗑️ Cleaning up conversations...")
        try? await cleanupUserConversations(userID: userID)
        print("✅ Conversations cleaned up")

        // 4. Delete user document from Firestore
        print("🗑️ Deleting user document...")
        try await db.collection(Constants.Collections.users)
            .document(userID)
            .delete()
        print("✅ User document deleted")

        // 5. Clear local storage
        print("🗑️ Clearing local storage...")
        try? await LocalStorageManager.shared.clearAll()
        print("✅ Local storage cleared")

        // 6. Clear user cache
        UserService.shared.clearCache()

        // 7. Delete Firebase Auth account (must be last)
        print("🗑️ Deleting Firebase Auth account...")
        try await Auth.auth().currentUser?.delete()
        print("✅ Firebase Auth account deleted")

        // Update state
        await MainActor.run {
            self.user = nil
            self.isAuthenticated = false
        }

        print("✅ Account deletion complete")
    }

    /// Delete all messages sent by the user
    private func deleteUserMessages(userID: String) async throws {
        // Query all messages sent by this user
        let snapshot = try await db.collectionGroup(Constants.Collections.messages)
            .whereField("senderID", isEqualTo: userID)
            .getDocuments()

        print("📝 Found \(snapshot.documents.count) messages to delete")

        // Delete each message
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }

    /// Clean up conversations where user was a participant
    private func cleanupUserConversations(userID: String) async throws {
        // Query all conversations where user is a participant
        let snapshot = try await db.collection(Constants.Collections.conversations)
            .whereField("participantIDs", arrayContains: userID)
            .getDocuments()

        print("💬 Found \(snapshot.documents.count) conversations to clean up")

        for document in snapshot.documents {
            // Check if this is a 1-on-1 conversation (2 participants)
            if let participantIDs = document.data()["participantIDs"] as? [String],
               participantIDs.count == 2 {
                // Delete the entire conversation if it's 1-on-1
                try await document.reference.delete()
                print("🗑️ Deleted 1-on-1 conversation: \(document.documentID)")
            } else {
                // For group chats, just remove the user from participants
                try await document.reference.updateData([
                    "participantIDs": FieldValue.arrayRemove([userID])
                ])
                print("👥 Removed user from group conversation: \(document.documentID)")
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

