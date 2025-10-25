//
//  CalendarSettingsView.swift
//  Yaip
//
//  Calendar integration settings
//

import SwiftUI
import EventKit

struct CalendarSettingsView: View {
    @StateObject private var calendarManager = CalendarManager.shared
    @State private var showingPermissionAlert = false
    @State private var isRequestingApple = false
    @State private var isRequestingGoogle = false
    @State private var isRequestingOutlook = false

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
                            Text("Connect calendars for smarter suggestions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            // Apple Calendar Section
            appleCalendarSection

            // Google Calendar Section
            googleCalendarSection

            // Outlook Calendar Section
            outlookCalendarSection

            if calendarManager.hasAnyProviderConnected {
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

        }
        .navigationTitle("Calendar Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Calendar Permission Required", isPresented: $showingPermissionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Calendar permission is required for smart meeting suggestions.")
        }
    }

    // MARK: - Apple Calendar Section
    @ViewBuilder
    private var appleCalendarSection: some View {
        Section("Apple Calendar") {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    if calendarManager.appleCalendar.isAuthorized {
                        Text("Connected")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Built-in iOS calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not Connected")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text("Built-in iOS calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if calendarManager.appleCalendar.isAuthorized {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                } else {
                    Button {
                        requestAppleCalendarAccess()
                    } label: {
                        if isRequestingApple {
                            ProgressView()
                        } else {
                            Text("Connect")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRequestingApple)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Google Calendar Section
    @ViewBuilder
    private var googleCalendarSection: some View {
        Section("Google Calendar") {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundStyle(.red)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    if let google = calendarManager.googleCalendar, google.isAuthorized {
                        Text("Connected")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(google.userEmail ?? "Google Workspace")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not Connected")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text("Google Workspace calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let google = calendarManager.googleCalendar, google.isAuthorized {
                    Menu {
                        Button(role: .destructive) {
                            disconnectGoogleCalendar()
                        } label: {
                            Label("Disconnect", systemImage: "xmark")
                        }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                } else {
                    Button {
                        requestGoogleCalendarAccess()
                    } label: {
                        if isRequestingGoogle {
                            ProgressView()
                        } else {
                            Text("Connect")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRequestingGoogle)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Outlook Calendar Section
    @ViewBuilder
    private var outlookCalendarSection: some View {
        Section("Outlook Calendar") {
            HStack(spacing: 12) {
                Image(systemName: "envelope")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    if let outlook = calendarManager.outlookCalendar, outlook.isAuthorized {
                        Text("Connected")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(outlook.userEmail ?? "Microsoft 365")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not Connected")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text("Microsoft 365 calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let outlook = calendarManager.outlookCalendar, outlook.isAuthorized {
                    Menu {
                        Button(role: .destructive) {
                            disconnectOutlookCalendar()
                        } label: {
                            Label("Disconnect", systemImage: "xmark")
                        }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                } else {
                    Button {
                        requestOutlookCalendarAccess()
                    } label: {
                        if isRequestingOutlook {
                            ProgressView()
                        } else {
                            Text("Connect")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRequestingOutlook)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Actions
    private func requestAppleCalendarAccess() {
        isRequestingApple = true

        Task {
            do {
                _ = try await calendarManager.appleCalendar.requestAccess()
                calendarManager.enableProvider(.apple)
            } catch {
                print("❌ Apple Calendar error: \(error)")
            }
            isRequestingApple = false
        }
    }

    private func requestGoogleCalendarAccess() {
        isRequestingGoogle = true

        Task {
            do {
                // Initialize Google Calendar if not already
                if calendarManager.googleCalendar == nil {
                    calendarManager.enableProvider(.google)
                }

                guard let google = calendarManager.googleCalendar else { return }
                _ = try await google.requestAccess()
                calendarManager.enableProvider(.google)
            } catch {
                print("❌ Google Calendar error: \(error)")
                showingPermissionAlert = true
            }
            isRequestingGoogle = false
        }
    }

    private func disconnectGoogleCalendar() {
        Task {
            guard let google = calendarManager.googleCalendar else { return }
            try? await google.disconnect()
            calendarManager.disableProvider(.google)
        }
    }

    private func requestOutlookCalendarAccess() {
        isRequestingOutlook = true

        Task {
            do {
                // Initialize Outlook Calendar if not already
                if calendarManager.outlookCalendar == nil {
                    calendarManager.enableProvider(.outlook)
                }

                guard let outlook = calendarManager.outlookCalendar else { return }
                _ = try await outlook.requestAccess()
                calendarManager.enableProvider(.outlook)
            } catch {
                print("❌ Outlook Calendar error: \(error)")
                showingPermissionAlert = true
            }
            isRequestingOutlook = false
        }
    }

    private func disconnectOutlookCalendar() {
        Task {
            guard let outlook = calendarManager.outlookCalendar else { return }
            try? await outlook.disconnect()
            calendarManager.disableProvider(.outlook)
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
