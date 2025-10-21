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
    
    private init() {
        setupAuthStateListener()
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
                    // User document doesn't exist - create it from Firebase Auth data
                    print("⚠️ User document not found in Firestore, creating it...")
                    
                    if let authUser = Auth.auth().currentUser {
                        let newUser = User(
                            id: nil, // Let Firestore set the ID
                            displayName: authUser.displayName ?? "User",
                            email: authUser.email ?? "",
                            profileImageURL: authUser.photoURL?.absoluteString,
                            status: .online,
                            lastSeen: Date(),
                            fcmToken: nil,
                            createdAt: Date()
                        )
                        
                        // Save to Firestore
                        try db.collection(Constants.Collections.users).document(authUser.uid).setData(from: newUser)
                        
                        await MainActor.run {
                            self.user = newUser
                            self.isAuthenticated = true
                        }
                        return
                    }
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
                    print("❌ Decoding error: \(error)")
                    
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
                        lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue() ?? Date(),
                        fcmToken: data["fcmToken"] as? String,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    
                    await MainActor.run {
                        self.user = fallbackUser
                        self.isAuthenticated = true
                    }
                    print("✅ Used fallback user construction")
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
        
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        fetchUserProfile(userID: result.user.uid)
        
        // Set user online
        try? await presenceService.setOnline(userID: result.user.uid)
    }
    
    /// Sign out
    func signOut() throws {
        // Set user offline and stop message listener before signing out
        if let userID = currentUserID {
            Task {
                try? await presenceService.setOffline(userID: userID)
                await MessageListenerService.shared.stopListening()
            }
        }
        
        try Auth.auth().signOut()
        DispatchQueue.main.async {
            self.user = nil
            self.isAuthenticated = false
        }
    }
    
    /// Reset password
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

