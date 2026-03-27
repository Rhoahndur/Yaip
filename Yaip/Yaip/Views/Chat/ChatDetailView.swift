//
//  ChatDetailView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import SwiftUI

struct ChatDetailView: View {
    let conversation: Conversation
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.dismiss) private var dismiss
    @State private var participantUsers: [User] = []
    @State private var isLoadingParticipants = true
    @State private var showAddParticipant = false
    @State private var showLeaveConfirmation = false
    @State private var isLeavingGroup = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            List {
                // Group Info Section (for groups only)
                if conversation.type == .group {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                    .overlay {
                                        Image(systemName: "person.3.fill")
                                            .font(.title)
                                            .foregroundStyle(.blue)
                                    }
                                
                                Text(conversation.name ?? "Group Chat")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Text("\(conversation.participants.count) participants")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            Spacer()
                        }
                    }
                }
                
                // Participants Section
                Section("Participants") {
                    if isLoadingParticipants {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        ForEach(participantUsers) { user in
                            ParticipantRow(
                                user: user,
                                isCurrentUser: user.id == authManager.currentUserID,
                                avatarSize: 40
                            ) {
                                if networkMonitor.isConnected {
                                    Circle()
                                        .fill(user.status == .online ? Color.green : Color.gray)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }
                
                // Actions Section (for groups)
                if conversation.type == .group {
                    Section {
                        Button {
                            showAddParticipant = true
                        } label: {
                            Label("Add Participant", systemImage: "person.badge.plus")
                        }

                        Button(role: .destructive) {
                            showLeaveConfirmation = true
                        } label: {
                            if isLeavingGroup {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                        .disabled(isLeavingGroup)
                    }

                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
                
                // Info Section
                Section {
                    LabeledContent("Created", value: conversation.createdAt.formatted(date: .abbreviated, time: .shortened))
                    
                    if conversation.type == .group {
                        LabeledContent("Type", value: "Group Chat")
                    } else {
                        LabeledContent("Type", value: "Direct Message")
                    }
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadParticipants()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddParticipant) {
                AddParticipantSheet(
                    conversation: conversation,
                    existingParticipants: conversation.participants,
                    onAdd: { userID in
                        Task {
                            await addParticipant(userID: userID)
                        }
                    }
                )
            }
            .alert("Leave Group", isPresented: $showLeaveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Leave", role: .destructive) {
                    Task {
                        await leaveGroup()
                    }
                }
            } message: {
                Text("Are you sure you want to leave this group? You will no longer receive messages from this conversation.")
            }
        }
    }

    private func addParticipant(userID: String) async {
        guard let conversationID = conversation.id else { return }
        errorMessage = nil

        do {
            try await ConversationService.shared.addParticipant(
                conversationID: conversationID,
                userID: userID
            )
            await loadParticipants()
        } catch {
            errorMessage = "Failed to add participant: \(error.localizedDescription)"
        }
    }

    private func leaveGroup() async {
        guard let conversationID = conversation.id,
              let currentUserID = authManager.currentUserID else { return }

        isLeavingGroup = true
        errorMessage = nil

        do {
            try await ConversationService.shared.removeParticipant(
                conversationID: conversationID,
                userID: currentUserID
            )
            dismiss()
        } catch {
            errorMessage = "Failed to leave group: \(error.localizedDescription)"
            isLeavingGroup = false
        }
    }

    private func loadParticipants() async {
        isLoadingParticipants = true
        
        do {
            let users = try await UserService.shared.fetchUsers(ids: conversation.participants)
            participantUsers = users
        } catch {
            print("Error loading participants: \(error)")
        }
        
        isLoadingParticipants = false
    }
}

// MARK: - Add Participant Sheet

struct AddParticipantSheet: View {
    let conversation: Conversation
    let existingParticipants: [String]
    let onAdd: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchVM = UserSearchViewModel()
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            List {
                if searchVM.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if filteredUsers.isEmpty {
                    Text("No users found")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(filteredUsers) { user in
                        Button {
                            guard let userID = user.id else { return }
                            isAdding = true
                            onAdd(userID)
                            dismiss()
                        } label: {
                            ParticipantRow(
                                user: user,
                                isCurrentUser: false,
                                avatarSize: 36
                            ) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .disabled(isAdding)
                    }
                }
            }
            .searchable(text: $searchVM.searchText, prompt: "Search users")
            .navigationTitle("Add Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await searchVM.fetchAllUsers()
            }
        }
    }

    private var filteredUsers: [User] {
        searchVM.users.filter { user in
            guard let userID = user.id else { return false }
            return !existingParticipants.contains(userID)
        }
    }
}

#Preview {
    ChatDetailView(conversation: Conversation(
        id: "1",
        type: .group,
        participants: ["user1", "user2", "user3"],
        name: "Project Team",
        imageURL: nil,
        lastMessage: nil,
        createdAt: Date(),
        updatedAt: Date(),
        unreadCount: [:]
    ))
}

