//
//  CalendarSettingsView.swift
//  Yaip
//
//  Calendar integration settings
//

import SwiftUI
import EventKit

struct CalendarSettingsView: View {
    @StateObject private var calendarService = AppleCalendarService.shared
    @State private var showingPermissionAlert = false
    @State private var isRequesting = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: "calendar")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calendar Integration")
                                .font(.headline)
                            Text("Smart meeting suggestions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    // Status
                    statusBadge
                }
            }

            if calendarService.isAuthorized {
                Section("Benefits") {
                    FeatureRow(
                        icon: "checkmark.circle.fill",
                        text: "AI suggests times when you're actually free",
                        color: .green
                    )
                    FeatureRow(
                        icon: "calendar.badge.clock",
                        text: "Avoids scheduling conflicts automatically",
                        color: .blue
                    )
                    FeatureRow(
                        icon: "sparkles",
                        text: "Smarter meeting time recommendations",
                        color: .purple
                    )
                }
            } else {
                Section("What You'll Get") {
                    FeatureRow(
                        icon: "calendar",
                        text: "Check your actual calendar availability",
                        color: .blue
                    )
                    FeatureRow(
                        icon: "sparkles",
                        text: "AI-powered meeting suggestions",
                        color: .purple
                    )
                    FeatureRow(
                        icon: "lock.shield",
                        text: "We only check busy/free, never event details",
                        color: .green
                    )
                }

                Section {
                    Button {
                        requestCalendarAccess()
                    } label: {
                        if isRequesting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Enable Calendar Access", systemImage: "calendar.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRequesting)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Privacy First", systemImage: "hand.raised.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Yaip only checks if you're busy or free at suggested times. We never read event titles, descriptions, or attendees.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if calendarService.authorizationStatus == .denied {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Calendar Access Denied", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)

                        Text("To enable calendar integration, go to Settings > Yaip > Calendars and turn on access.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Calendar Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Calendar Permission Required", isPresented: $showingPermissionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Yaip needs calendar access to suggest meeting times when you're available. We only check if you're busy or free, never read event details.")
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack {
            if calendarService.isAuthorized {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Connected")
                    .fontWeight(.semibold)
                Spacer()
                Text("Apple Calendar")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.gray)
                Text("Not Connected")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(calendarService.isAuthorized ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func requestCalendarAccess() {
        isRequesting = true

        Task {
            do {
                let granted = try await calendarService.requestAccess()

                await MainActor.run {
                    isRequesting = false

                    if !granted {
                        showingPermissionAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    showingPermissionAlert = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        CalendarSettingsView()
    }
}
