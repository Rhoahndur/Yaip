//
//  EnhancedMessageBubble.swift
//  Yaip
//
//  Message bubble with reactions, reply, and delete support
//

import SwiftUI

struct EnhancedMessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    let currentUserID: String
    let conversationID: String
    let replyToMessage: Message? // The message this is replying to
    var onRetry: (() -> Void)? = nil
    var onReact: ((String) -> Void)? = nil
    var onReply: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var showReactionPicker = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser { Spacer(minLength: 50) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Reply indicator (if replying to another message)
                if let replyTo = replyToMessage {
                    ReplyPreviewView(message: replyTo, isFromCurrentUser: isFromCurrentUser)
                }

                // Check if message is deleted
                if message.isDeleted {
                    DeletedMessageView(isFromCurrentUser: isFromCurrentUser)
                } else {
                    // Original message content
                    MessageContentView(
                        message: message,
                        isFromCurrentUser: isFromCurrentUser
                    )
                }

                // Reactions
                if !message.reactions.isEmpty && !message.isDeleted {
                    MessageReactionsView(
                        reactions: message.reactions,
                        currentUserID: currentUserID
                    ) { emoji in
                        onReact?(emoji)
                    }
                }

                // Timestamp and status
                HStack(spacing: 4) {
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if isFromCurrentUser {
                        StatusIcon(status: message.status)
                    }
                }
            }

            if !isFromCurrentUser { Spacer(minLength: 50) }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
        .contextMenu {
            if !message.isDeleted {
                // React button
                Button {
                    showReactionPicker = true
                } label: {
                    Label("React", systemImage: "face.smiling")
                }

                // Reply button
                Button {
                    onReply?()
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }

                // Copy text (if has text)
                if let text = message.text, !text.isEmpty {
                    Button {
                        UIPasteboard.general.string = text
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }

                Divider()

                // Delete (only for own messages)
                if isFromCurrentUser {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .sheet(isPresented: $showReactionPicker) {
            ReactionPickerView { emoji in
                onReact?(emoji)
            }
        }
        .confirmationDialog(
            "Delete this message?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete for Everyone", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This message will be deleted for everyone in the conversation")
        }
    }
}

// MARK: - Supporting Views

struct MessageContentView: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Text content
            if let text = message.text, !text.isEmpty {
                Text(text)
                    .padding(12)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
            }

            // Image content (simplified - full implementation in original MessageBubble)
            if message.mediaType == .image, let mediaURL = message.mediaURL {
                AsyncImage(url: URL(string: mediaURL)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 250)
                        .cornerRadius(12)
                } placeholder: {
                    ProgressView()
                        .frame(width: 250, height: 200)
                }
            }
        }
    }
}

struct ReplyPreviewView: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .font(.caption2)
                Text("Reply to")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)

            if message.isDeleted {
                Text("[Message deleted]")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
            } else if let text = message.text {
                Text(text)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DeletedMessageView: View {
    let isFromCurrentUser: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "trash.slash")
                .font(.caption)
            Text("Message deleted")
                .font(.subheadline)
                .italic()
        }
        .foregroundStyle(.secondary)
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }
}

struct StatusIcon: View {
    let status: MessageStatus

    var body: some View {
        Group {
            switch status {
            case .staged, .sending:
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
            case .sent:
                Image(systemName: "checkmark")
                    .foregroundStyle(.secondary)
            case .delivered:
                Image(systemName: "checkmark.checkmark")
                    .foregroundStyle(.secondary)
            case .read:
                Image(systemName: "checkmark.checkmark")
                    .foregroundStyle(.blue)
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.red)
            }
        }
        .font(.caption2)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Regular message with reactions
        EnhancedMessageBubble(
            message: Message(
                id: "1",
                conversationID: "conv1",
                senderID: "user1",
                text: "Hey! How's it going?",
                timestamp: Date(),
                status: .read,
                readBy: ["user1", "user2"],
                reactions: ["👍": ["user2"], "❤️": ["user1", "user2"]]
            ),
            isFromCurrentUser: false,
            currentUserID: "user1",
            conversationID: "conv1",
            replyToMessage: nil
        )

        // Deleted message
        EnhancedMessageBubble(
            message: Message(
                id: "2",
                conversationID: "conv1",
                senderID: "user1",
                text: "[Message deleted]",
                timestamp: Date(),
                status: .read,
                readBy: ["user1"],
                isDeleted: true
            ),
            isFromCurrentUser: true,
            currentUserID: "user1",
            conversationID: "conv1",
            replyToMessage: nil
        )

        // Reply message
        EnhancedMessageBubble(
            message: Message(
                id: "3",
                conversationID: "conv1",
                senderID: "user1",
                text: "Sounds good!",
                timestamp: Date(),
                status: .sent,
                readBy: ["user1"],
                replyTo: "1"
            ),
            isFromCurrentUser: true,
            currentUserID: "user1",
            conversationID: "conv1",
            replyToMessage: Message(
                id: "1",
                conversationID: "conv1",
                senderID: "user2",
                text: "Let's meet tomorrow",
                timestamp: Date().addingTimeInterval(-3600),
                status: .read,
                readBy: ["user1", "user2"]
            )
        )
    }
    .padding()
}
