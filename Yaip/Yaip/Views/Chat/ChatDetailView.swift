//
//  ChatDetailView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import SwiftUI

struct ChatDetailView: View {
    let conversation: Conversation
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var participantUsers: [User] = []
    @State private var isLoadingParticipants = true
    
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
                            HStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.id == authManager.currentUserID ? "You" : user.displayName)
                                        .font(.body)
                                    
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                // Online status indicator
                                Circle()
                                    .fill(user.status == .online ? Color.green : Color.gray)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                
                // Actions Section (for groups)
                if conversation.type == .group {
                    Section {
                        Button {
                            // TODO: Add participant
                        } label: {
                            Label("Add Participant", systemImage: "person.badge.plus")
                        }
                        
                        Button(role: .destructive) {
                            // TODO: Leave group
                            dismiss()
                        } label: {
                            Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
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

