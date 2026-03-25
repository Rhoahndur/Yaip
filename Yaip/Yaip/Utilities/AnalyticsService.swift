import Foundation
import FirebaseAnalytics

/// Centralized analytics wrapper around Firebase Analytics.
/// All user action events are logged through this service for consistent tracking.
enum AnalyticsService {

    enum Event: String {
        case messageSent = "message_sent"
        case messageRetried = "message_retried"
        case reactionAdded = "reaction_added"
        case conversationCreated = "conversation_created"
        case imageUploaded = "image_uploaded"
        case aiFeatureUsed = "ai_feature_used"
        case searchPerformed = "search_performed"
        case messageDeleted = "message_deleted"
        case profileUpdated = "profile_updated"
    }

    /// Log an analytics event with optional parameters.
    /// - Parameters:
    ///   - event: The typed event to log.
    ///   - parameters: Optional key-value pairs for event context.
    static func log(_ event: Event, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event.rawValue, parameters: parameters)
    }

    // MARK: - Convenience Methods

    /// Log a message sent event. Tracks whether the message included an image.
    static func logMessageSent(conversationID: String, hasImage: Bool) {
        log(.messageSent, parameters: [
            "conversation_id": conversationID,
            "has_image": hasImage
        ])
    }

    static func logMessageRetried(conversationID: String) {
        log(.messageRetried, parameters: [
            "conversation_id": conversationID
        ])
    }

    static func logReactionAdded(emoji: String) {
        log(.reactionAdded, parameters: ["emoji": emoji])
    }

    static func logConversationCreated(type: String, participantCount: Int) {
        log(.conversationCreated, parameters: [
            "type": type,
            "participant_count": participantCount
        ])
    }

    static func logAIFeatureUsed(feature: String) {
        log(.aiFeatureUsed, parameters: ["feature": feature])
    }

    static func logSearchPerformed(queryLength: Int) {
        log(.searchPerformed, parameters: ["query_length": queryLength])
    }
}
