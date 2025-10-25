//
//  PriorityMessagesView.swift
//  Yaip
//
//  View for displaying AI-detected priority messages
//

import SwiftUI

struct PriorityMessagesView: View {
    @ObservedObject var viewModel: AIFeaturesViewModel
    @Environment(\.dismiss) private var dismiss
    var onJumpToMessage: ((String) -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingPriority {
                    loadingView
                } else if viewModel.priorityMessages.isEmpty {
                    emptyView
                } else {
                    priorityList
                }
            }
            .navigationTitle("Priority Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.detectPriority()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        AILoadingView(
            title: "Detecting priority messages",
            subtitle: "AI is analyzing messages for urgency and importance..."
        )
        .frame(maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green.opacity(0.5))

            Text("All caught up!")
                .font(.headline)

            Text("No high-priority messages detected in this conversation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }

    private var priorityList: some View {
        List {
            // Header with stats
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundStyle(.red)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(viewModel.priorityMessages.count) Priority Items")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Requiring your attention")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    // Score distribution
                    HStack(spacing: 16) {
                        ScoreBadge(
                            count: criticalMessages.count,
                            label: "Critical",
                            color: .red,
                            range: "9-10"
                        )

                        ScoreBadge(
                            count: highMessages.count,
                            label: "High",
                            color: .orange,
                            range: "7-8"
                        )

                        ScoreBadge(
                            count: mediumMessages.count,
                            label: "Medium",
                            color: .yellow,
                            range: "6"
                        )
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // Critical priority (9-10)
            if !criticalMessages.isEmpty {
                Section {
                    ForEach(criticalMessages) { message in
                        PriorityMessageRow(
                            message: message,
                            onTap: {
                                onJumpToMessage?(message.messageID)
                                dismiss()
                            }
                        )
                    }
                } header: {
                    Label("Critical", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            // High priority (7-8)
            if !highMessages.isEmpty {
                Section {
                    ForEach(highMessages) { message in
                        PriorityMessageRow(
                            message: message,
                            onTap: {
                                onJumpToMessage?(message.messageID)
                                dismiss()
                            }
                        )
                    }
                } header: {
                    Label("High Priority", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            }

            // Medium priority (6)
            if !mediumMessages.isEmpty {
                Section {
                    ForEach(mediumMessages) { message in
                        PriorityMessageRow(
                            message: message,
                            onTap: {
                                onJumpToMessage?(message.messageID)
                                dismiss()
                            }
                        )
                    }
                } header: {
                    Label("Needs Attention", systemImage: "flag.fill")
                        .foregroundStyle(.yellow)
                }
            }
        }
    }

    private var criticalMessages: [PriorityMessage] {
        viewModel.priorityMessages.filter { $0.priorityScore >= 9 }
    }

    private var highMessages: [PriorityMessage] {
        viewModel.priorityMessages.filter { $0.priorityScore >= 7 && $0.priorityScore < 9 }
    }

    private var mediumMessages: [PriorityMessage] {
        viewModel.priorityMessages.filter { $0.priorityScore == 6 }
    }
}

struct PriorityMessageRow: View {
    let message: PriorityMessage
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Score badge and excerpt
            HStack(alignment: .top, spacing: 12) {
                // Priority score badge
                ZStack {
                    Circle()
                        .fill(scoreColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Text("\(message.priorityScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(scoreColor)
                }

                // Message excerpt
                VStack(alignment: .leading, spacing: 6) {
                    Text(message.excerpt)
                        .font(.body)
                        .lineLimit(3)

                    // Reason badge
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)

                        Text(message.reason)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                }
            }

            // Action button
            Button(action: onTap) {
                HStack {
                    Label("View Message", systemImage: "arrow.right.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()
                }
                .foregroundStyle(.purple)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    private var scoreColor: Color {
        switch message.priorityScore {
        case 9...10: return .red
        case 7...8: return .orange
        default: return .yellow
        }
    }
}

struct ScoreBadge: View {
    let count: Int
    let label: String
    let color: Color
    let range: String

    var body: some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text(range)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    PriorityMessagesView(viewModel: AIFeaturesViewModel(conversationID: "test-123"))
}
