//
//  GroupChatSettingsView.swift
//  Yaip
//
//  Edit group chat settings (name, participants, etc.)
//

import SwiftUI
import FirebaseFirestore

struct GroupChatSettingsView: View {
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared

    @State private var groupName: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var participantUsers: [User] = []
    @State private var isLoadingParticipants = true
    @State private var showAddParticipant = false
    @State private var showRemoveConfirmation = false
    @State private var userToRemove: User?

    var body: some View {
        NavigationStack {
            Form {
                Section("Group Name") {
                    TextField("Enter group name", text: $groupName)
                        .disabled(isSaving)

                    Text("Names longer than 25 characters will be truncated with \"...\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Participants (\(participantUsers.count))") {
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
                                avatarSize: 36
                            ) {
                                if user.id != authManager.currentUserID {
                                    Button {
                                        userToRemove = user
                                        showRemoveConfirmation = true
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Button {
                            showAddParticipant = true
                        } label: {
                            Label("Add Participant", systemImage: "person.badge.plus")
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        saveGroupName()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving || !hasChanges)
                }
            }
            .navigationTitle("Group Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Group Updated", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Group settings have been updated successfully.")
            }
            .alert("Remove Participant", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) {
                    userToRemove = nil
                }
                Button("Remove", role: .destructive) {
                    if let user = userToRemove {
                        Task {
                            await removeParticipant(user)
                        }
                    }
                    userToRemove = nil
                }
            } message: {
                if let user = userToRemove {
                    Text("Remove \(user.displayName) from this group?")
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
            .onAppear {
                loadCurrentName()
            }
            .task {
                await loadParticipants()
            }
        }
    }

    private var hasChanges: Bool {
        let currentName = conversation.name ?? ""
        return groupName.trimmingCharacters(in: .whitespaces) != currentName
    }

    private func loadCurrentName() {
        groupName = conversation.name ?? ""
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

    private func removeParticipant(_ user: User) async {
        guard let conversationID = conversation.id,
              let userID = user.id else { return }
        errorMessage = nil

        do {
            try await ConversationService.shared.removeParticipant(
                conversationID: conversationID,
                userID: userID
            )
            participantUsers.removeAll { $0.id == userID }
        } catch {
            errorMessage = "Failed to remove participant: \(error.localizedDescription)"
        }
    }

    private func saveGroupName() {
        guard let conversationID = conversation.id else { return }

        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Group name cannot be empty"
            return
        }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                // Update Firestore
                try await Firestore.firestore()
                    .collection(Constants.Collections.conversations)
                    .document(conversationID)
                    .updateData([
                        "name": trimmedName,
                        "updatedAt": FieldValue.serverTimestamp()
                    ])

                await MainActor.run {
                    isSaving = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to update group name: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    GroupChatSettingsView(conversation: Conversation(
        id: "preview",
        type: .group,
        participants: ["user1", "user2", "user3"],
        name: "Team Chat",
        imageURL: nil,
        lastMessage: nil,
        createdAt: Date(),
        updatedAt: Date(),
        unreadCount: [:]
    ))
}
