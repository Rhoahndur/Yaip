//
//  ParticipantRow.swift
//  Yaip
//
//  Reusable row for displaying a participant's avatar, name, and email.
//

import SwiftUI

struct ParticipantRow<Trailing: View>: View {
    let user: User
    let isCurrentUser: Bool
    let avatarSize: CGFloat
    @ViewBuilder let trailing: () -> Trailing

    init(
        user: User,
        isCurrentUser: Bool,
        avatarSize: CGFloat = 40,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.user = user
        self.isCurrentUser = isCurrentUser
        self.avatarSize = avatarSize
        self.trailing = trailing
    }

    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: avatarSize, height: avatarSize)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrentUser ? "You" : user.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)

                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            trailing()
        }
    }
}

extension ParticipantRow where Trailing == EmptyView {
    init(user: User, isCurrentUser: Bool, avatarSize: CGFloat = 40) {
        self.init(user: user, isCurrentUser: isCurrentUser, avatarSize: avatarSize) {
            EmptyView()
        }
    }
}
