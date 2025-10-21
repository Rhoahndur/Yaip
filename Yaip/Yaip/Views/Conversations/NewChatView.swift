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
                            UserRow(user: user, isSelected: selectedUsers.contains(user))
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
        Task {
            isCreating = true
            errorMessage = nil
            
            do {
                if isGroupChatMode {
                    // Create group conversation
                    print("🔄 Creating group chat...")
                    print("   Name: \(groupName)")
                    print("   Selected users: \(selectedUsers.count)")
                    
                    guard let currentUserID = conversationViewModel.authManager.currentUserID else {
                        throw ConversationError.invalidID
                    }
                    
                    let participantIDs = selectedUsers.compactMap { $0.id }
                    print("   Participant IDs: \(participantIDs)")
                    print("   Current user: \(currentUserID)")
                    
                    let conversation = try await conversationViewModel.createGroupConversation(
                        name: groupName.trimmingCharacters(in: .whitespaces),
                        participants: participantIDs
                    )
                    
                    print("✅ Group chat created: \(conversation.id ?? "no-id")")
                } else {
                    // Create 1-on-1 conversation
                    print("🔄 Creating 1-on-1 chat...")
                    guard let selectedUser = selectedUsers.first else { 
                        print("❌ No selected user")
                        return 
                    }
                    print("   With: \(selectedUser.displayName)")
                    
                    let conversation = try await conversationViewModel.createOneOnOneConversation(with: selectedUser)
                    print("✅ 1-on-1 chat created: \(conversation.id ?? "no-id")")
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("❌ Error creating conversation: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isCreating = false
                }
            }
        }
    }
}

struct UserRow: View {
    let user: User
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
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

