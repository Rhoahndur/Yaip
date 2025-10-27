//
//  MeetingSuggestionsView.swift
//  Yaip
//
//  View for AI-generated meeting time suggestions
//

import SwiftUI

struct MeetingSuggestionsView: View {
    @ObservedObject var viewModel: AIFeaturesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeSlot: TimeSlot?
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    if viewModel.isLoadingMeeting {
                        loadingView
                    } else if let suggestion = viewModel.meetingSuggestion {
                        // Intent detected
                        intentSection(suggestion)

                        // Suggested times
                        timeSlotsSection(suggestion)

                        // Participants
                        participantsSection(suggestion)
                    }
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                // Floating confirm button when time slot is selected
                if selectedTimeSlot != nil {
                    floatingConfirmButton
                        .padding()
                        .background(Color(.systemBackground))
                        .shadow(radius: 4)
                }
            }
            .navigationTitle("Meeting Scheduler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Confirm Meeting Time", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {
                    // Don't clear selection, let user pick again
                }
                Button("Confirm & Create Event") {
                    if let timeSlot = selectedTimeSlot {
                        viewModel.selectTimeSlot(timeSlot)
                        selectedTimeSlot = nil
                    }
                }
            } message: {
                if let timeSlot = selectedTimeSlot,
                   let suggestion = viewModel.meetingSuggestion {
                    Text("Create calendar event for \(suggestion.detectedIntent)?\n\n\(timeSlot.date.formatted(date: .abbreviated, time: .omitted))\n\(timeSlot.startTime) - \(timeSlot.endTime) (\(suggestion.duration) min)")
                }
            }
            .alert("Event Created", isPresented: $viewModel.showEventCreatedAlert) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("✓ The meeting has been added to your calendar.")
            }
            .alert("Error", isPresented: $viewModel.showEventErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.eventCreationError ?? "Failed to create calendar event.")
            }
            .overlay {
                if viewModel.isCreatingEvent {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Creating calendar event...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Meeting Scheduler")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Smart scheduling based on conversation context")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Calendar integration status
            if AppleCalendarService.shared.isAuthorized {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)

                    Text("Enhanced with your calendar availability")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)

                    Text("Connect your calendar for smarter suggestions")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    NavigationLink(destination: CalendarSettingsView()) {
                        Text("Connect")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }

    private var loadingView: some View {
        AILoadingView(
            title: "Detecting scheduling intent",
            subtitle: "AI is analyzing conversation for meeting suggestions..."
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func intentSection(_ suggestion: MeetingSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Detected Intent")
                .font(.headline)

            Text(suggestion.detectedIntent)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }

    private func timeSlotsSection(_ suggestion: MeetingSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Times")
                .font(.headline)

            Text("\(suggestion.duration) minutes • Tap to select")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(suggestion.suggestedTimes.enumerated()), id: \.element.id) { index, timeSlot in
                TimeSlotCard(
                    timeSlot: timeSlot,
                    number: index + 1,
                    isSelected: selectedTimeSlot?.id == timeSlot.id,
                    onSelect: {
                        selectedTimeSlot = timeSlot
                    }
                )
            }
        }
    }

    private var floatingConfirmButton: some View {
        Button {
            showConfirmation = true
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                Text("Confirm & Create Event")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }

    private func participantsSection(_ suggestion: MeetingSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(suggestion.participants, id: \.self) { participant in
                    Text(participant)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(16)
                }
            }
        }
    }
}

struct TimeSlotCard: View {
    let timeSlot: TimeSlot
    let number: Int
    let isSelected: Bool
    let onSelect: () -> Void

    private var isFullyAvailable: Bool {
        timeSlot.conflicts.isEmpty && (timeSlot.isUserFree ?? true)
    }

    private var cardColor: Color {
        if let isUserFree = timeSlot.isUserFree, !isUserFree {
            return .red
        }
        return timeSlot.conflicts.isEmpty ? .green : .orange
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                HStack {
                    // Selection checkbox
                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 24, height: 24)

                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }

                    // Number badge
                    Text("\(number)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(cardColor)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(timeSlot.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)

                        Text("\(timeSlot.startTime) - \(timeSlot.endTime)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Status icon
                    if isFullyAvailable {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    } else if let isUserFree = timeSlot.isUserFree, !isUserFree {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.title3)
                    }
                }

                Divider()

                // Your availability (from Apple Calendar)
                if let isUserFree = timeSlot.isUserFree {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(isUserFree ? .green : .red)

                        Text("You:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Text(isUserFree ? "Free" : "Busy")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(isUserFree ? .green : .red)

                        Spacer()
                    }
                }

                // Team availability (only show if we have data)
                if !timeSlot.available.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Team Available")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Text(timeSlot.available.joined(separator: ", "))
                                .font(.caption)
                        }

                        Spacer()
                    }
                } else if timeSlot.isUserFree != nil {
                    // Show message if we only have user's calendar data
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Team availability not checked")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                }

                if !timeSlot.conflicts.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Team Conflicts")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Text(timeSlot.conflicts.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        Spacer()
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.05) : Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: isSelected ? 4 : 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : cardColor.opacity(0.3), lineWidth: isSelected ? 3 : 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// Simple flow layout for wrapping views
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowLayoutResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowLayoutResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }

    struct FlowLayoutResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))

                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    MeetingSuggestionsView(viewModel: AIFeaturesViewModel(conversationID: "test-123"))
}
