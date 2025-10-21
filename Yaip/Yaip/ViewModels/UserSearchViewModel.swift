//
//  UserSearchViewModel.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// ViewModel for searching and selecting users
@MainActor
class UserSearchViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let authManager = AuthManager.shared
    private var searchTask: Task<Void, Never>?
    
    init() {
        // Setup search debouncing
        setupSearchDebounce()
    }
    
    private func setupSearchDebounce() {
        // Debounce search to avoid too many Firestore queries
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                Task {
                    // Only search if there's text, otherwise keep showing all users
                    if !searchText.isEmpty {
                        await self?.searchUsers(query: searchText)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Search for users by display name
    func searchUsers(query: String) async {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            // If query is empty, fetch all users instead of clearing
            await fetchAllUsers()
            return
        }
        
        searchTask = Task {
            isLoading = true
            
            do {
                // Search users whose displayName starts with the query
                let snapshot = try await db.collection(Constants.Collections.users)
                    .whereField("displayName", isGreaterThanOrEqualTo: query)
                    .whereField("displayName", isLessThan: query + "\u{f8ff}")
                    .limit(to: 20)
                    .getDocuments()
                
                if Task.isCancelled { return }
                
                let currentUserID = authManager.currentUserID
                let searchResults = snapshot.documents.compactMap { doc in
                    try? doc.data(as: User.self)
                }.filter { user in
                    // Filter out current user
                    user.id != currentUserID
                }
                
                self.users = searchResults
                self.isLoading = false
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Fetch all users (for testing/demo purposes)
    func fetchAllUsers() async {
        isLoading = true
        
        do {
            let snapshot = try await db.collection(Constants.Collections.users)
                .limit(to: 50)
                .getDocuments()
            
            let currentUserID = authManager.currentUserID
            let allUsers = snapshot.documents.compactMap { doc in
                try? doc.data(as: User.self)
            }.filter { user in
                user.id != currentUserID
            }
            
            self.users = allUsers
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}

