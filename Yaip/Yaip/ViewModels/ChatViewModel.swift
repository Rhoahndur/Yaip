//
//  ChatViewModel.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// ViewModel for managing chat messages in a single conversation.
///
/// Follows an **optimistic UI** pattern: messages appear instantly in the UI,
/// then sync to Firestore in the background. Failed sends are queued for retry.
///
/// Organized into extensions by responsibility:
/// - `ChatViewModel+Messaging.swift` — send, retry, merge, listen, markAsRead
/// - `ChatViewModel+Interactions.swift` — reactions, deletion, replies
/// - `ChatViewModel+Presence.swift` — typing indicators
///
/// All dependencies are injected via protocols with `.shared` defaults,
/// enabling unit testing with mocks.
@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published State

    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var selectedImage: UIImage?
    @Published var otherUserIsTyping = false
    @Published var isLoading = false
    @Published var isUploadingImage = false
    @Published var errorMessage: String?
    @Published var participantNames: [String: String] = [:]
    @Published var conversation: Conversation
    @Published var replyingTo: Message?

    // MARK: - Dependencies

    let messageService: MessageServiceProtocol
    let conversationService: ConversationServiceProtocol
    let authManager: AuthManagerProtocol
    let localStorage: LocalStorageManagerProtocol
    let imageUploadManager: ImageUploadManagerProtocol
    let networkMonitor: NetworkMonitorProtocol

    // MARK: - Internal State

    let listenerBag = ListenerBag()
    var typingTimer: Timer?
    var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        conversation: Conversation,
        messageService: MessageServiceProtocol = MessageService.shared,
        conversationService: ConversationServiceProtocol = ConversationService.shared,
        authManager: AuthManagerProtocol = AuthManager.shared,
        localStorage: LocalStorageManagerProtocol = LocalStorageManager.shared,
        imageUploadManager: ImageUploadManagerProtocol = ImageUploadManager.shared,
        networkMonitor: NetworkMonitorProtocol = NetworkMonitor.shared
    ) {
        self.conversation = conversation
        self.messageService = messageService
        self.conversationService = conversationService
        self.authManager = authManager
        self.localStorage = localStorage
        self.imageUploadManager = imageUploadManager
        self.networkMonitor = networkMonitor
        setupMessageTextObserver()
        setupNetworkReconnectListener()

        if conversation.type == .group {
            Task {
                await loadParticipantNames()
            }
        }
    }

    // MARK: - Network Reconnection

    private func setupNetworkReconnectListener() {
        NotificationCenter.default.publisher(for: .networkDidReconnect)
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("🔄 Network reconnected - retrying pending messages and indexing queue")
                Task { @MainActor in
                    await self.retryAllFailedMessages()
                    await MessageIndexingService.shared.processOfflineQueue()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Participant Names

    func getSenderName(for userID: String) -> String {
        return participantNames[userID] ?? "Unknown"
    }

    func loadParticipantNames() async {
        do {
            let users = try await UserService.shared.fetchUsers(ids: conversation.participants)
            await MainActor.run {
                for user in users {
                    if let userID = user.id {
                        self.participantNames[userID] = user.displayName
                    }
                }
            }
        } catch {
            print("Error loading participant names: \(error)")
        }
    }

    deinit {
        typingTimer?.invalidate()
    }
}
