//
//  DecisionTrackingView.swift
//  Yaip
//
//  View for displaying AI-tracked decisions
//

import SwiftUI

struct DecisionTrackingView: View {
    @ObservedObject var viewModel: AIFeaturesViewModel
    @Environment(\.dismiss) private var dismiss
    var onJumpToMessage: ((String) -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingDecisions {
                    loadingView
                } else if viewModel.decisions.isEmpty {
                    emptyView
                } else {
                    decisionsList
                }
            }
            .navigationTitle("Decision Tracking")
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
                            // Refresh decisions
                            viewModel.extractDecisions()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }

                        Divider()

                        Button {
                            // Filter by high impact
                            // TODO: Implement filtering
                        } label: {
                            Label("High Impact Only", systemImage: "exclamationmark.triangle")
                        }

                        Button {
                            // Filter by category
                            // TODO: Implement filtering
                        } label: {
                            Label("Filter by Category", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        AILoadingView(
            title: "Tracking decisions",
            subtitle: "AI is identifying important decisions from the conversation..."
        )
        .frame(maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 48))
                .foregroundStyle(.purple.opacity(0.5))

            Text("No decisions found")
                .font(.headline)

            Text("The AI didn't detect any concrete decisions in this conversation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }

    private var decisionsList: some View {
        List {
            // Statistics
            Section {
                HStack(spacing: 24) {
                    StatBox(
                        value: viewModel.decisions.filter { $0.impact == .high }.count,
                        label: "High Impact",
                        color: .red
                    )

                    StatBox(
                        value: viewModel.decisions.filter { $0.impact == .medium }.count,
                        label: "Medium",
                        color: .orange
                    )

                    StatBox(
                        value: viewModel.decisions.filter { $0.impact == .low }.count,
                        label: "Low",
                        color: .gray
                    )
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // Group by impact
            if !highImpactDecisions.isEmpty {
                Section("High Impact") {
                    ForEach(highImpactDecisions) { decision in
                        DecisionRow(
                            decision: decision,
                            onTap: {
                                onJumpToMessage?(decision.messageID)
                                dismiss()
                            }
                        )
                    }
                }
            }

            if !mediumImpactDecisions.isEmpty {
                Section("Medium Impact") {
                    ForEach(mediumImpactDecisions) { decision in
                        DecisionRow(
                            decision: decision,
                            onTap: {
                                onJumpToMessage?(decision.messageID)
                                dismiss()
                            }
                        )
                    }
                }
            }

            if !lowImpactDecisions.isEmpty {
                Section("Low Impact") {
                    ForEach(lowImpactDecisions) { decision in
                        DecisionRow(
                            decision: decision,
                            onTap: {
                                onJumpToMessage?(decision.messageID)
                                dismiss()
                            }
                        )
                    }
                }
            }
        }
    }

    private var highImpactDecisions: [Decision] {
        viewModel.decisions.filter { $0.impact == .high }
    }

    private var mediumImpactDecisions: [Decision] {
        viewModel.decisions.filter { $0.impact == .medium }
    }

    private var lowImpactDecisions: [Decision] {
        viewModel.decisions.filter { $0.impact == .low }
    }
}

struct DecisionRow: View {
    let decision: Decision
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Decision header with impact badge
            HStack(alignment: .top, spacing: 8) {
                impactBadge

                Text(decision.decision)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Reasoning
            VStack(alignment: .leading, spacing: 4) {
                Text("Reasoning")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(decision.reasoning)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            // Metadata row
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    // Decision maker
                    Label(decision.decisionMaker, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)

                    // Category
                    categoryBadge

                    Spacer()

                    // Timestamp
                    Text(decision.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Context
                if !decision.context.isEmpty {
                    Text(decision.context)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Jump to message button
                Button(action: onTap) {
                    Label("View in chat", systemImage: "arrow.right.circle")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var impactBadge: some View {
        let (icon, color): (String, Color) = switch decision.impact {
        case .high: ("exclamationmark.triangle.fill", .red)
        case .medium: ("exclamationmark.circle.fill", .orange)
        case .low: ("info.circle.fill", .gray)
        }

        Image(systemName: icon)
            .foregroundStyle(color)
            .font(.title3)
    }

    @ViewBuilder
    private var categoryBadge: some View {
        let (icon, text): (String, String) = switch decision.category {
        case .technical: ("wrench.and.screwdriver", "Technical")
        case .business: ("briefcase.fill", "Business")
        case .process: ("arrow.triangle.2.circlepath", "Process")
        case .other: ("tag.fill", "Other")
        }

        Label(text, systemImage: icon)
            .font(.caption2)
            .foregroundStyle(.purple)
    }
}

#Preview {
    DecisionTrackingView(viewModel: AIFeaturesViewModel(conversationID: "test-123"))
}
