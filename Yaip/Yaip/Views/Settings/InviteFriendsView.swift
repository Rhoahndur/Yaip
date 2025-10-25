//
//  InviteFriendsView.swift
//  Yaip
//
//  Invite friends to join Yaip
//

import SwiftUI
import MessageUI

struct InviteFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showMailCompose = false
    @State private var showCopiedAlert = false

    private let inviteMessage = """
    Hey! I'm using Yaip for team messaging with AI-powered features. Join me!

    Download: [App Store Link]
    """

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Invite Friends")
                                .font(.headline)
                            Text("Grow your team")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Section("Share Yaip") {
                Button {
                    showShareSheet = true
                } label: {
                    Label("Share via...", systemImage: "square.and.arrow.up")
                }

                Button {
                    copyInviteLink()
                } label: {
                    Label("Copy Invite Link", systemImage: "doc.on.doc")
                }

                if MFMailComposeViewController.canSendMail() {
                    Button {
                        showMailCompose = true
                    } label: {
                        Label("Invite via Email", systemImage: "envelope")
                    }
                }

                Button {
                    shareViaSMS()
                } label: {
                    Label("Invite via SMS", systemImage: "message")
                }
            }

            Section("Invite Message") {
                Text(inviteMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why Invite Friends?")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    FeatureRow(
                        icon: "sparkles",
                        text: "AI-powered features for your team",
                        color: .purple
                    )

                    FeatureRow(
                        icon: "message.fill",
                        text: "Real-time team messaging",
                        color: .blue
                    )

                    FeatureRow(
                        icon: "lock.shield.fill",
                        text: "Secure and private conversations",
                        color: .green
                    )
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Invite Friends")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [inviteMessage])
        }
        .sheet(isPresented: $showMailCompose) {
            MailComposeView(
                subject: "Join me on Yaip!",
                message: inviteMessage,
                recipients: []
            )
        }
        .alert("Link Copied", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Invite link copied to clipboard")
        }
    }

    private func copyInviteLink() {
        UIPasteboard.general.string = inviteMessage
        showCopiedAlert = true
    }

    private func shareViaSMS() {
        let sms = "sms:&body=\(inviteMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: sms) {
            UIApplication.shared.open(url)
        }
    }
}

// Share Sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Mail compose wrapper
struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let message: String
    let recipients: [String]

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.setSubject(subject)
        composer.setMessageBody(message, isHTML: false)
        composer.setToRecipients(recipients)
        composer.mailComposeDelegate = context.coordinator
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView

        init(parent: MailComposeView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        InviteFriendsView()
    }
}
