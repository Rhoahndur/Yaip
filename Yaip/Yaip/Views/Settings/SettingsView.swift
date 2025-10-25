//
//  SettingsView.swift
//  Yaip
//
//  Main settings screen
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                Section {
                    NavigationLink(destination: ProfileSettingsView()) {
                        HStack(spacing: 16) {
                            // Profile photo
                            if let profileImageURL = authManager.currentUser?.profileImageURL,
                               let url = URL(string: profileImageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    profileImagePlaceholder
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            } else {
                                profileImagePlaceholder
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(authManager.currentUser?.displayName ?? "User")
                                    .font(.headline)

                                Text(authManager.currentUser?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Preferences
                Section("Preferences") {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        Label("Appearance", systemImage: "paintbrush.fill")
                    }

                    NavigationLink(destination: CalendarSettingsView()) {
                        HStack {
                            Label("Calendar Integration", systemImage: "calendar")

                            Spacer()

                            if AppleCalendarService.shared.isAuthorized {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                        }
                    }
                }

                // Social
                Section("Social") {
                    NavigationLink(destination: InviteFriendsView()) {
                        Label("Invite Friends", systemImage: "person.2.fill")
                    }
                }

                // App Info
                Section("About") {
                    LabeledContent("Version", value: appVersion)

                    Link(destination: URL(string: "https://github.com/yourusername/yaip")!) {
                        Label("GitHub", systemImage: "link")
                    }

                    Link(destination: URL(string: "https://docs.yaip.com")!) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                }

                // Account
                Section("Account") {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showLogoutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authManager.signOut()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .animation(.easeInOut(duration: 0.3), value: themeManager.currentTheme)
        }
    }

    private var profileImagePlaceholder: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay(
                Text(authManager.currentUser?.displayName.prefix(1).uppercased() ?? "U")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            )
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    SettingsView()
}
