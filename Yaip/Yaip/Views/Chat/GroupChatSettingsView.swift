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

    @State private var groupName: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

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

                Section("Participants") {
                    Text("\(conversation.participants.count) members")
                        .foregroundStyle(.secondary)

                    // TODO: Show participant list with ability to add/remove
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
            .onAppear {
                loadCurrentName()
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
