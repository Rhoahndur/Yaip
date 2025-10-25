//
//  ReactionPickerView.swift
//  Yaip
//
//  Emoji reaction picker for messages
//

import SwiftUI

struct ReactionPickerView: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    // Common reaction emojis
    private let reactions = ["👍", "❤️", "😂", "😮", "😢", "🙏", "🎉", "🔥"]

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // Title
            Text("React to message")
                .font(.headline)
                .padding()

            // Reactions grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                ForEach(reactions, id: \.self) { emoji in
                    Button {
                        onSelect(emoji)
                        dismiss()
                    } label: {
                        Text(emoji)
                            .font(.system(size: 40))
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }
}

struct MessageReactionsView: View {
    let reactions: [String: [String]]
    let currentUserID: String
    let onTap: (String) -> Void

    var body: some View {
        if !reactions.isEmpty {
            HStack(spacing: 4) {
                ForEach(sortedReactions, id: \.emoji) { reaction in
                    ReactionBubble(
                        emoji: reaction.emoji,
                        count: reaction.count,
                        userReacted: reaction.userIDs.contains(currentUserID),
                        onTap: {
                            onTap(reaction.emoji)
                        }
                    )
                }
            }
            .padding(.top, 4)
        }
    }

    private var sortedReactions: [(emoji: String, count: Int, userIDs: [String])] {
        reactions.map { (emoji: $0.key, count: $0.value.count, userIDs: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

struct ReactionBubble: View {
    let emoji: String
    let count: Int
    let userReacted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 2) {
                Text(emoji)
                    .font(.caption)

                if count > 1 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(userReacted ? Color.blue.opacity(0.2) : Color(.systemGray5))
            .foregroundStyle(userReacted ? .blue : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(userReacted ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        ReactionPickerView { emoji in
            print("Selected: \(emoji)")
        }

        Divider()

        MessageReactionsView(
            reactions: ["👍": ["user1", "user2"], "❤️": ["user3"]],
            currentUserID: "user1"
        ) { emoji in
            print("Tapped: \(emoji)")
        }
        .padding()
    }
}
