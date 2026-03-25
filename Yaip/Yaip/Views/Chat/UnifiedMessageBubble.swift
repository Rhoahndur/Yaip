import SwiftUI

/// Single message bubble view that handles both 1-on-1 and group chat contexts,
/// replacing the duplicated MessageBubble and GroupMessageBubble.
struct UnifiedMessageBubble: View {
    enum ChatContext {
        case oneOnOne
        case group(senderName: String, conversation: Conversation, currentUserID: String)
    }

    let message: Message
    let isFromCurrentUser: Bool
    let context: ChatContext
    var onRetry: (() -> Void)?

    @ObservedObject private var imageUploadManager = ImageUploadManager.shared
    @State private var isRetrying = false
    @State private var showingReadReceipts = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser { Spacer(minLength: 50) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                // Sender name (group chats only)
                if case .group(let senderName, _, _) = context {
                    if isFromCurrentUser {
                        Text("You")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                            .padding(.trailing, 12)
                    } else {
                        Text(senderName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 12)
                    }
                }

                // Image content
                if message.mediaType == .image {
                    VStack(spacing: 0) {
                        imageContent
                            .frame(maxWidth: 250, maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        // Caption text below image
                        if let text = message.text, !text.isEmpty {
                            Text(text)
                                .font(.body)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                        }
                    }
                    .background(isFromCurrentUser ? Color.sentMessageBackground : Color.receivedMessageBackground)
                    .foregroundStyle(isFromCurrentUser ? Color.sentMessageText : Color.receivedMessageText)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else if let text = message.text {
                    // Text-only message
                    Text(text)
                        .font(.body)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isFromCurrentUser ? Color.sentMessageBackground : Color.receivedMessageBackground)
                        .foregroundStyle(isFromCurrentUser ? Color.sentMessageText : Color.receivedMessageText)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                // Timestamp + status row
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    if isFromCurrentUser {
                        statusIcon

                        // Read label for 1-on-1
                        if case .oneOnOne = context,
                           message.status == .read && message.readBy.count > 1 {
                            Text("Read")
                                .font(.system(size: 11))
                                .foregroundStyle(.blue)
                        }

                        if message.status == .failed {
                            Text("• Tap to retry")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            if !isFromCurrentUser { Spacer(minLength: 50) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint(message.status == .failed ? "Double tap to retry sending" : "")
        .accessibilityIdentifier("messageBubble_\(message.id ?? "")")
        .onTapGesture {
            handleTap()
        }
        .sheet(isPresented: $showingReadReceipts) {
            if case .group(_, let conversation, let currentUserID) = context {
                MessageReadReceiptsView(
                    message: message,
                    conversation: conversation,
                    currentUserID: currentUserID
                )
            }
        }
    }

    // MARK: - Image Content

    @ViewBuilder
    private var imageContent: some View {
        if let mediaURL = message.mediaURL, !mediaURL.isEmpty {
            // Uploaded image
            AsyncImage(url: URL(string: mediaURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 250, height: 200)
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 250, maxHeight: 200)
                        .clipped()
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                        .frame(width: 250, height: 200)
                @unknown default:
                    EmptyView()
                }
            }
        } else if let messageID = message.id {
            // Cached image (uploading or failed)
            let imageState = imageUploadManager.getState(for: messageID)
            if let cachedImage = imageUploadManager.getCachedImage(for: messageID) {
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 250, maxHeight: 200)
                    .clipped()
                    .overlay(imageUploadOverlay(state: imageState))
                    .opacity(message.status.isRetryable ? 0.6 : 0.9)
            } else {
                // Placeholder
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    if message.status.isRetryable || message.status == .staged {
                        Text("Tap to retry")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 250, height: 200)
            }
        }
    }

    // MARK: - Upload Overlay

    @ViewBuilder
    private func imageUploadOverlay(state: ImageUploadManager.ImageState) -> some View {
        switch state {
        case .uploading(let progress):
            ZStack {
                Color.black.opacity(0.3)
                VStack(spacing: 4) {
                    ProgressView(value: progress)
                        .progressViewStyle(.circular)
                        .tint(.white)
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
        case .failed(let error, _):
            ZStack {
                Color.black.opacity(0.3)
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.title2)
                    Text("Tap to retry")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Status Icon

    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .staged:
            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .opacity(0.5)
        case .sending:
            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        case .sent:
            Image(systemName: "checkmark")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        case .delivered:
            HStack(spacing: -2) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Image(systemName: "checkmark")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        case .read:
            HStack(spacing: 2) {
                HStack(spacing: -2) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                }
                // Show read count in group chats
                if case .group = context, message.readBy.count > 1 {
                    Text("\(message.readBy.count)")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 12))
                .foregroundStyle(.red)
        }
    }

    // MARK: - Tap Handling

    private func handleTap() {
        // Retry failed/stuck messages
        let shouldRetry: Bool = {
            if message.status.isRetryable || message.status == .staged { return true }
            if message.status == .sending, message.mediaType == .image, message.mediaURL == nil {
                if let id = message.id {
                    let state = imageUploadManager.getState(for: id)
                    return state.isRetryable || state == .notStarted
                }
            }
            return false
        }()

        if shouldRetry && !isRetrying {
            isRetrying = true
            print("🔄 Tapped to retry message: \(message.id ?? "unknown")")
            onRetry?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isRetrying = false
            }
        } else if case .group(_, let conversation, _) = context,
                  isFromCurrentUser && conversation.type == .group && !isRetrying {
            // Show read receipts for own messages in group chats
            showingReadReceipts = true
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts: [String] = []

        if case .group(let senderName, _, _) = context {
            parts.append(isFromCurrentUser ? "You" : senderName)
        }

        if let text = message.text, !text.isEmpty {
            parts.append(text)
        } else if message.mediaType == .image {
            parts.append("Photo")
        }

        switch message.status {
        case .staged: parts.append("Queued")
        case .sending: parts.append("Sending")
        case .failed: parts.append("Failed to send")
        case .sent: parts.append("Sent")
        case .delivered: parts.append("Delivered")
        case .read: parts.append("Read")
        }

        return parts.joined(separator: ", ")
    }
}
