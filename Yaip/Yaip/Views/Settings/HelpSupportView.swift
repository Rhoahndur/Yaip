//
//  HelpSupportView.swift
//  Yaip
//
//  In-app FAQ and support page
//

import SwiftUI

struct HelpSupportView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                FAQItem(
                    question: "How do I start a conversation?",
                    answer: "Tap the compose button in the top right corner of the conversations list, search for a user by name or email, and tap their name to start chatting."
                )
                FAQItem(
                    question: "How do I create a group chat?",
                    answer: "Tap the compose button, then select multiple users to start a group conversation."
                )
            }

            Section("Messaging") {
                FAQItem(
                    question: "Can I send messages offline?",
                    answer: "Yes! Yaip queues your messages locally and sends them automatically when you're back online. You'll see a status indicator on each message."
                )
                FAQItem(
                    question: "How do read receipts work?",
                    answer: "In 1-on-1 chats, messages show as read when the other person views them. In group chats, messages show as read when all participants have seen them."
                )
                FAQItem(
                    question: "Can I react to or delete a message?",
                    answer: "Long-press on any message to see options like reactions and delete. You can only delete messages you sent."
                )
            }

            Section("AI Features") {
                FAQItem(
                    question: "What AI features are available?",
                    answer: "Yaip includes conversation summaries, action item extraction, smart meeting time suggestions, decision tracking, and message priority detection."
                )
                FAQItem(
                    question: "How do I use AI features?",
                    answer: "Open any conversation and tap the sparkle icon to access AI-powered tools like summarization, action items, and meeting suggestions."
                )
            }

            Section("Account & Privacy") {
                FAQItem(
                    question: "How do I change my display name or photo?",
                    answer: "Go to Settings and tap your profile at the top to edit your display name and profile photo."
                )
                FAQItem(
                    question: "How do I delete my account?",
                    answer: "Go to Settings > Delete Account. This permanently removes all your data including messages, conversations, and profile information."
                )
                FAQItem(
                    question: "Is my data secure?",
                    answer: "Yaip uses Firebase for secure authentication and data storage. Messages are protected by security rules ensuring only conversation participants can access them."
                )
            }

            Section("Contact") {
                Link(destination: URL(string: "https://github.com/rhoahndur/yaip/issues")!) {
                    Label("Report an Issue on GitHub", systemImage: "exclamationmark.bubble")
                }
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        } label: {
            Text(question)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        HelpSupportView()
    }
}
