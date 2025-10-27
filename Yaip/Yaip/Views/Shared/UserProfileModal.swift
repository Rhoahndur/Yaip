//
//  UserProfileModal.swift
//  Yaip
//
//  User profile modal for viewing user details
//

import SwiftUI
import FirebaseFirestore

struct UserProfileModal: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @State private var userStatus: UserStatus = .offline
    @State private var lastSeen: Date?
    @State private var presenceListener: ListenerRegistration?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Picture
                    ZStack {
                        if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                profilePlaceholder
                            }
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(radius: 10)
                        } else {
                            profilePlaceholder
                                .frame(width: 200, height: 200)
                        }

                        // Online status indicator
                        Circle()
                            .fill(statusColor)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .offset(x: 70, y: 70)
                    }
                    .padding(.top, 20)

                    // User Info
                    VStack(spacing: 12) {
                        // Display Name
                        Text(user.displayName)
                            .font(.title)
                            .fontWeight(.bold)

                        // Email
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // Status
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)

                            Text(statusText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }

                    Divider()
                        .padding(.horizontal)

                    // Additional Info
                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(icon: "envelope.fill", title: "Email", value: user.email)

                        if let lastSeen = lastSeen, userStatus == .offline {
                            InfoRow(
                                icon: "clock.fill",
                                title: "Last Seen",
                                value: formatLastSeen(lastSeen)
                            )
                        }

                        InfoRow(
                            icon: "calendar",
                            title: "Member Since",
                            value: user.createdAt.formatted(date: .abbreviated, time: .omitted)
                        )
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupPresenceListener()
        }
        .onDisappear {
            presenceListener?.remove()
        }
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .overlay(
                Text(user.displayName.prefix(1).uppercased())
                    .font(.system(size: 80, weight: .semibold))
                    .foregroundStyle(.blue)
            )
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 4)
            )
            .shadow(radius: 10)
    }

    private var statusColor: Color {
        switch userStatus {
        case .online:
            return .green
        case .away:
            return .orange
        case .offline:
            return .gray
        }
    }

    private var statusText: String {
        switch userStatus {
        case .online:
            return "Online"
        case .away:
            return "Away"
        case .offline:
            if let lastSeen = lastSeen {
                return "Last seen \(formatLastSeen(lastSeen))"
            }
            return "Offline"
        }
    }

    private func setupPresenceListener() {
        guard let userID = user.id else { return }

        presenceListener = PresenceService.shared.listenToPresence(userID: userID) { status, lastSeenDate in
            self.userStatus = status
            self.lastSeen = lastSeenDate
        }
    }

    private func formatLastSeen(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    UserProfileModal(user: User(
        id: "preview",
        displayName: "John Doe",
        email: "john@example.com",
        profileImageURL: nil,
        status: .online,
        lastSeen: Date(),
        fcmToken: nil,
        createdAt: Date()
    ))
}
