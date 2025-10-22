//
//  PendingChatView.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/22/25.
//

import SwiftUI

/// ChatView for conversations that haven't been created in Firestore yet
struct PendingChatView: View {
    let pendingConversation: PendingConversation
    @StateObject private var viewModel: PendingChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(pendingConversation: PendingConversation) {
        self.pendingConversation = pendingConversation
        self._viewModel = StateObject(wrappedValue: PendingChatViewModel(pendingConversation: pendingConversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.conversationCreated, let conversation = viewModel.createdConversation {
                // Conversation was created, now show regular ChatView
                // ChatView has its own MessageComposer, so don't show ours
                ChatView(conversation: conversation)
            } else {
                // Pending state - show empty state + our own composer
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.5))
                    
                    Text("No messages yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Send a message to start the conversation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Message composer (only show when pending)
                MessageComposer(
                    text: $viewModel.messageText,
                    selectedImage: $viewModel.selectedImage
                ) {
                    Task {
                        await viewModel.sendFirstMessage()
                    }
                }
            }
        }
        .navigationTitle(viewModel.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(viewModel.displayName)
                        .font(.headline)
                    
                    if pendingConversation.type == .oneOnOne {
                        Text("New conversation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(pendingConversation.participants.count) participants")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}


