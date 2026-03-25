import Foundation
import Combine

/// Typing indicators and presence management.
extension ChatViewModel {

    /// Update typing status in Firestore
    func updateTypingStatus(_ isTyping: Bool) async {
        guard let currentUserID = authManager.currentUserID,
              let conversationID = conversation.id else {
            return
        }

        do {
            try await messageService.updateTypingStatus(
                conversationID: conversationID,
                userID: currentUserID,
                isTyping: isTyping
            )
        } catch {
            print("Error updating typing status: \(error.localizedDescription)")
        }
    }

    /// Setup observer for message text to update typing indicator
    func setupMessageTextObserver() {
        $messageText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                Task {
                    await self?.handleTypingChange(text: text)
                }
            }
            .store(in: &cancellables)
    }

    /// Handle typing status changes with auto-stop timer
    func handleTypingChange(text: String) async {
        let isTyping = !text.isEmpty
        await updateTypingStatus(isTyping)

        // Auto-stop typing after 3 seconds of no changes
        typingTimer?.invalidate()
        if isTyping {
            typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                Task {
                    await self?.updateTypingStatus(false)
                }
            }
        }
    }
}
