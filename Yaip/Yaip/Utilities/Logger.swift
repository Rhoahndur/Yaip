import os.log

/// Structured logging utility using os.log for categorized, searchable logs.
enum AppLogger {
    enum Category: String {
        case messages = "Messages"
        case auth = "Auth"
        case network = "Network"
        case storage = "Storage"
        case sync = "Sync"
        case ai = "AI"
        case general = "General"

        var logger: os.Logger {
            os.Logger(subsystem: "com.tavern.yaip", category: rawValue)
        }
    }

    static func info(_ message: String, category: Category = .general) {
        category.logger.info("\(message, privacy: .public)")
    }

    static func debug(_ message: String, category: Category = .general) {
        category.logger.debug("\(message, privacy: .public)")
    }

    static func warning(_ message: String, category: Category = .general) {
        category.logger.warning("\(message, privacy: .public)")
    }

    static func error(_ message: String, category: Category = .general) {
        category.logger.error("\(message, privacy: .public)")
    }

    /// Log a previously-silent failure that was hidden behind `try?`.
    /// Use this when converting `try?` to `do/catch` for operations that
    /// should not crash but whose failures are worth tracking.
    static func logSilentFailure(_ error: Error, context: String, category: Category = .general) {
        category.logger.error("Silent failure in \(context, privacy: .public): \(error.localizedDescription, privacy: .public)")
    }
}
