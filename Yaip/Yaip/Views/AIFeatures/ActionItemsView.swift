//
//  ActionItemsView.swift
//  Yaip
//
//  View for displaying AI-extracted action items
//

import SwiftUI

struct ActionItemsView: View {
    @ObservedObject var viewModel: AIFeaturesViewModel
    @Environment(\.dismiss) private var dismiss
    var onJumpToMessage: ((String) -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingActionItems {
                    loadingView
                } else if viewModel.actionItems.isEmpty {
                    emptyView
                } else {
                    actionItemsList
                }
            }
            .navigationTitle("Action Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.extractActionItems(dateRange: "1d")
                        } label: {
                            Label("Today", systemImage: "calendar")
                        }

                        Button {
                            viewModel.extractActionItems(dateRange: "7d")
                        } label: {
                            Label("Last 7 Days", systemImage: "calendar")
                        }

                        Button {
                            viewModel.extractActionItems(dateRange: "30d")
                        } label: {
                            Label("Last 30 Days", systemImage: "calendar")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        AILoadingView(
            title: "Extracting action items",
            subtitle: "AI is identifying tasks, assignees, and deadlines..."
        )
        .frame(maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green.opacity(0.5))

            Text("No action items found")
                .font(.headline)

            Text("The AI didn't detect any tasks or action items in recent messages")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }

    private var actionItemsList: some View {
        List {
            // Statistics
            Section {
                HStack(spacing: 24) {
                    StatBox(
                        value: viewModel.actionItems.filter { $0.status == .pending }.count,
                        label: "Pending",
                        color: .orange
                    )

                    StatBox(
                        value: viewModel.actionItems.filter { $0.status == .inProgress }.count,
                        label: "In Progress",
                        color: .blue
                    )

                    StatBox(
                        value: viewModel.actionItems.filter { $0.status == .completed }.count,
                        label: "Completed",
                        color: .green
                    )
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // Group by status
            if !pendingItems.isEmpty {
                Section("Pending") {
                    ForEach(pendingItems) { item in
                        ActionItemRow(
                            item: item,
                            onToggle: {
                                viewModel.toggleActionItem(item)
                            },
                            onTap: {
                                onJumpToMessage?(item.messageID)
                                dismiss()
                            }
                        )
                    }
                }
            }

            if !completedItems.isEmpty {
                Section("Completed") {
                    ForEach(completedItems) { item in
                        ActionItemRow(
                            item: item,
                            onToggle: {
                                viewModel.toggleActionItem(item)
                            },
                            onTap: {
                                onJumpToMessage?(item.messageID)
                                dismiss()
                            }
                        )
                    }
                }
            }
        }
    }

    private var pendingItems: [ActionItem] {
        viewModel.actionItems.filter { $0.status != .completed }
    }

    private var completedItems: [ActionItem] {
        viewModel.actionItems.filter { $0.status == .completed }
    }
}

struct ActionItemRow: View {
    let item: ActionItem
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: item.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.status == .completed ? .green : .gray)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(item.task)
                    .font(.body)
                    .strikethrough(item.status == .completed)

                // Metadata
                HStack(spacing: 12) {
                    if let assignee = item.assignee {
                        Label(assignee, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    if let deadline = item.deadline {
                        Label(
                            deadline.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        .font(.caption)
                        .foregroundStyle(deadline < Date() ? .red : .secondary)
                    }

                    // Priority badge
                    priorityBadge
                }

                // Context
                Text(item.context)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Jump to message button
                Button(action: onTap) {
                    Label("View in chat", systemImage: "arrow.right.circle")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var priorityBadge: some View {
        let (text, color): (String, Color) = switch item.priority {
        case .high: ("High", .red)
        case .medium: ("Medium", .orange)
        case .low: ("Low", .gray)
        }

        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(4)
    }
}

struct StatBox: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ActionItemsView(viewModel: AIFeaturesViewModel(conversationID: "test-123"))
}
