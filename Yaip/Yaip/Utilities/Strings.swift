import Foundation

/// Centralized localization strings using `String(localized:defaultValue:)`.
/// English only for now — infrastructure ready for future translations.
enum L10n {

    // MARK: - Chat

    enum Chat {
        static let noMessages = String(localized: "chat.noMessages", defaultValue: "No messages yet")
        static let startConversation = String(localized: "chat.startConversation", defaultValue: "Send a message to start the conversation")
        static let tapToRetry = String(localized: "chat.tapToRetry", defaultValue: "Tap to retry")
        static let messageDeleted = String(localized: "chat.messageDeleted", defaultValue: "[Message deleted]")
        static let photo = String(localized: "chat.photo", defaultValue: "Photo")
        static let messagePlaceholder = String(localized: "chat.messagePlaceholder", defaultValue: "Message")
        static let sendButton = String(localized: "chat.sendButton", defaultValue: "Send message")
        static let attachPhoto = String(localized: "chat.attachPhoto", defaultValue: "Attach photo")
        static let read = String(localized: "chat.read", defaultValue: "Read")
        static let noUnreadMessages = String(localized: "chat.noUnread", defaultValue: "No unread messages to mark")
        static let you = String(localized: "chat.you", defaultValue: "You")
        static let someone = String(localized: "chat.someone", defaultValue: "Someone")
        static let isTyping = String(localized: "chat.isTyping", defaultValue: "is typing")
        static let participants = String(localized: "chat.participants", defaultValue: "participants")
        static let statusUnavailable = String(localized: "chat.statusUnavailable", defaultValue: "Status unavailable")
        static let newChat = String(localized: "chat.newChat", defaultValue: "New Chat")
        static let groupChat = String(localized: "chat.groupChat", defaultValue: "Group Chat")
    }

    // MARK: - Auth

    enum Auth {
        static let signIn = String(localized: "auth.signIn", defaultValue: "Sign In")
        static let signUp = String(localized: "auth.signUp", defaultValue: "Sign Up")
        static let signOut = String(localized: "auth.signOut", defaultValue: "Sign Out")
        static let email = String(localized: "auth.email", defaultValue: "Email")
        static let password = String(localized: "auth.password", defaultValue: "Password")
        static let displayName = String(localized: "auth.displayName", defaultValue: "Display Name")
        static let forgotPassword = String(localized: "auth.forgotPassword", defaultValue: "Forgot Password?")
        static let resetPassword = String(localized: "auth.resetPassword", defaultValue: "Reset Password")
        static let deleteAccount = String(localized: "auth.deleteAccount", defaultValue: "Delete Account")
        static let notAuthenticated = String(localized: "auth.notAuthenticated", defaultValue: "User not authenticated")
    }

    // MARK: - Errors

    enum Error {
        static let noConnection = String(localized: "error.noConnection", defaultValue: "No Connection")
        static let messageSendFailed = String(localized: "error.messageSendFailed", defaultValue: "Message Not Sent")
        static let imageUploadFailed = String(localized: "error.imageUploadFailed", defaultValue: "Upload Failed")
        static let authFailed = String(localized: "error.authFailed", defaultValue: "Sign In Failed")
        static let loadFailed = String(localized: "error.loadFailed", defaultValue: "Couldn't Load Chat")
        static let somethingWrong = String(localized: "error.somethingWrong", defaultValue: "Something Went Wrong")
        static let tryAgain = String(localized: "error.tryAgain", defaultValue: "Try Again")
        static let failedToAddReaction = String(localized: "error.failedReaction", defaultValue: "Failed to add reaction")
        static let failedToDeleteMessage = String(localized: "error.failedDelete", defaultValue: "Failed to delete message")
    }

    // MARK: - Common

    enum Common {
        static let loading = String(localized: "common.loading", defaultValue: "Loading...")
        static let unknown = String(localized: "common.unknown", defaultValue: "Unknown")
        static let cancel = String(localized: "common.cancel", defaultValue: "Cancel")
        static let done = String(localized: "common.done", defaultValue: "Done")
        static let delete = String(localized: "common.delete", defaultValue: "Delete")
        static let save = String(localized: "common.save", defaultValue: "Save")
        static let online = String(localized: "common.online", defaultValue: "Online")
        static let offline = String(localized: "common.offline", defaultValue: "Offline")
        static let away = String(localized: "common.away", defaultValue: "Away")
    }

    // MARK: - AI Features

    enum AI {
        static let assistant = String(localized: "ai.assistant", defaultValue: "AI Assistant")
        static let summarize = String(localized: "ai.summarize", defaultValue: "Summarize Thread")
        static let actionItems = String(localized: "ai.actionItems", defaultValue: "Extract Action Items")
        static let meetingTimes = String(localized: "ai.meetingTimes", defaultValue: "Suggest Meeting Times")
        static let decisions = String(localized: "ai.decisions", defaultValue: "View Decisions")
        static let priority = String(localized: "ai.priority", defaultValue: "Detect Priority Messages")
        static let search = String(localized: "ai.search", defaultValue: "Smart Search")
        static let indexMessages = String(localized: "ai.indexMessages", defaultValue: "Index Messages")
        static let processing = String(localized: "ai.processing", defaultValue: "AI is processing...")
    }
}
