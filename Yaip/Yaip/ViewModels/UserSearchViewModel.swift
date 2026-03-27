//
//  UserSearchViewModel.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import Combine

/// ViewModel for searching and selecting users
@MainActor
class UserSearchViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userService: UserServiceProtocol
    private let authManager: AuthManagerProtocol
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        userService: UserServiceProtocol = UserService.shared,
        authManager: AuthManagerProtocol = AuthManager.shared
    ) {
        self.userService = userService
        self.authManager = authManager
        setupSearchDebounce()
    }

    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.searchTask?.cancel()
                self?.searchTask = Task {
                    if !searchText.isEmpty {
                        await self?.searchUsers(query: searchText)
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// Search for users by display name
    func searchUsers(query: String) async {
        guard !query.isEmpty else {
            await fetchAllUsers()
            return
        }

        isLoading = true

        do {
            let currentUserID = authManager.currentUserID
            let searchResults = try await userService.searchUsers(query: query)
                .filter { $0.id != currentUserID }

            if Task.isCancelled { return }

            self.users = searchResults
            self.isLoading = false
        } catch {
            if !Task.isCancelled {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    /// Fetch all users (for initial display / add-participant sheets)
    func fetchAllUsers() async {
        isLoading = true

        do {
            let currentUserID = authManager.currentUserID
            let allUsers = try await userService.searchUsers(query: "")
                .filter { $0.id != currentUserID }

            self.users = allUsers
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}

