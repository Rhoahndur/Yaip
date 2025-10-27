//
//  NewChatView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI

struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UserSearchViewModel()
    @StateObject private var conversationViewModel = ConversationListViewModel()
    
    @State private var selectedUsers: Set<User> = []
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var isGroupChatMode = false
    @State private var groupName = ""
    @State private var navigateToPendingChat = false
    @State private var pendingConversation: PendingConversation?
    @State private var showUserProfile = false
    @State private var selectedUserForProfile: User?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat type picker
                Picker("Chat Type", selection: $isGroupChatMode) {
                    Text("Direct Message").tag(false)
                    Text("Group Chat").tag(true)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: isGroupChatMode) { oldValue, newValue in
                    // Clear selection when switching modes
                    selectedUsers.removeAll()
                    groupName = ""
                }
                
                // Group name input (only for group chats)
                if isGroupChatMode {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField("Group Name", text: $groupName)
                                .textFieldStyle(.roundedBorder)
                            
                            // Visual indicator
                            if selectedUsers.count >= 2 {
                                if groupName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.orange)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Show validation hint - always visible in group mode
                        if selectedUsers.count >= 2 && groupName.trimmingCharacters(in: .whitespaces).isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("Type a group name above to enable Create button")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search users by name", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                    
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                
                // Selected users (for group chat later)
                if !selectedUsers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(selectedUsers), id: \.id) { user in
                                HStack(spacing: 4) {
                                    Text(user.displayName)
                                        .font(.caption)
                                    
                                    Button {
                                        selectedUsers.remove(user)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                // User list
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.users.isEmpty && !viewModel.searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No users found")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else if viewModel.users.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Search for users to start a chat")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.users) { user in
                            UserRow(
                                user: user,
                                isSelected: selectedUsers.contains(user),
                                onAvatarTap: {
                                    selectedUserForProfile = user
                                    showUserProfile = true
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleUserTap(user)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToPendingChat) {
                if let pending = pendingConversation {
                    PendingChatView(pendingConversation: pending)
                        .onDisappear {
                            // When chat is dismissed, close the entire sheet
                            dismiss()
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if canCreate && !isCreating {
                        // Enabled button - tappable
                        Button("Create") {
                            createConversation()
                        }
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                    } else {
                        // Disabled button - no tap gesture
                        Text(isCreating ? "Creating..." : "Create")
                            .foregroundStyle(.gray)
                    }
                }
            }
            .task {
                // For demo purposes, load all users on appear
                // In production, you'd only search on user input
                if viewModel.searchText.isEmpty {
                    await viewModel.fetchAllUsers()
                }
            }
            .sheet(isPresented: $showUserProfile) {
                if let user = selectedUserForProfile {
                    UserProfileModal(user: user)
                }
            }
        }
    }
    
    private func handleUserTap(_ user: User) {
        if isGroupChatMode {
            // Group chat mode: toggle selection
            if selectedUsers.contains(user) {
                selectedUsers.remove(user)
            } else {
                selectedUsers.insert(user)
            }
        } else {
            // Direct message mode: select only one user
            if selectedUsers.contains(user) {
                selectedUsers.remove(user)
            } else {
                selectedUsers.removeAll()
                selectedUsers.insert(user)
            }
        }
    }
    
    private var canCreate: Bool {
        if isGroupChatMode {
            // Group chat requires at least 2 users + group name
            return selectedUsers.count >= 2 && !groupName.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            // Direct message requires exactly 1 user
            return selectedUsers.count == 1
        }
    }
    
    private func createConversation() {
        guard let currentUserID = conversationViewModel.authManager.currentUserID else {
            errorMessage = "User not authenticated"
            return
        }
        
        // Create pending conversation (NOT saved to Firestore yet)
        if isGroupChatMode {
            print("📝 Creating pending group chat...")
            print("   Name: \(groupName)")
            print("   Selected users: \(selectedUsers.count)")
            
            let participantIDs = selectedUsers.compactMap { $0.id } + [currentUserID]
            
            pendingConversation = PendingConversation(
                type: .group,
                participants: participantIDs,
                name: groupName.trimmingCharacters(in: .whitespaces)
            )
            
            print("✅ Pending group chat created (not yet saved to Firestore)")
        } else {
            print("📝 Creating pending 1-on-1 chat...")
            guard let selectedUser = selectedUsers.first,
                  let otherUserID = selectedUser.id else {
                errorMessage = "Invalid user selection"
                return
            }
            print("   With: \(selectedUser.displayName)")
            
            // Check if conversation already exists
            Task {
                do {
                    let existing = try await conversationViewModel.conversationService.findExistingConversation(
                        between: [currentUserID, otherUserID]
                    )
                    
                    if let existing = existing {
                        // Conversation exists, just navigate to it
                        print("✅ Found existing conversation: \(existing.id ?? "no-id")")
                        await MainActor.run {
                            // We can't navigate to existing conversation from here
                            // So just dismiss and let user find it in their list
                            dismiss()
                        }
                    } else {
                        // Create pending conversation
                        await MainActor.run {
                            pendingConversation = PendingConversation(
                                type: .oneOnOne,
                                participants: [currentUserID, otherUserID],
                                name: nil
                            )
                            navigateToPendingChat = true
                            print("✅ Pending 1-on-1 chat created (not yet saved to Firestore)")
                        }
                    }
                } catch {
                    print("❌ Error checking for existing conversation: \(error)")
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            return
        }
        
        // For group chats, navigate immediately
        navigateToPendingChat = true
    }
}

struct UserRow: View {
    let user: User
    let isSelected: Bool
    var onAvatarTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Avatar (tappable to view profile)
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)

                if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.gray)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }
            }
            .onTapGesture {
                onAvatarTap?()
            }
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.headline)
                
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NewChatView()
}

