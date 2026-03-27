import Foundation

/// Structured error type for user-facing error messages.
/// Provides consistent, actionable error information across the app.
enum UserFacingError: Equatable {
    case networkUnavailable
    case messageSendFailed
    case imageUploadFailed
    case authenticationFailed(String)
    case conversationLoadFailed
    case aiFeatureFailed(String)
    case unknown(String)

    var title: String {
        switch self {
        case .networkUnavailable: "No Connection"
        case .messageSendFailed: "Message Not Sent"
        case .imageUploadFailed: "Upload Failed"
        case .authenticationFailed: "Sign In Failed"
        case .conversationLoadFailed: "Couldn't Load Chat"
        case .aiFeatureFailed: "AI Feature Failed"
        case .unknown: "Something Went Wrong"
        }
    }

    var message: String {
        switch self {
        case .networkUnavailable:
            "Check your internet connection and try again."
        case .messageSendFailed:
            "Your message couldn't be sent. Tap to retry."
        case .imageUploadFailed:
            "The image couldn't be uploaded. Tap to retry."
        case .authenticationFailed(let detail):
            detail
        case .conversationLoadFailed:
            "We couldn't load this conversation. Pull to refresh."
        case .aiFeatureFailed(let detail):
            detail
        case .unknown(let detail):
            detail
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .messageSendFailed, .imageUploadFailed, .conversationLoadFailed, .aiFeatureFailed:
            true
        case .authenticationFailed, .unknown:
            false
        }
    }

    var retryLabel: String? {
        isRetryable ? "Try Again" : nil
    }
}
