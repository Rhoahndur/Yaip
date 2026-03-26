import FirebaseFirestore

extension DocumentSnapshot {
    /// Decode this document snapshot into a Codable type, returning nil on failure.
    func decoded<T: Decodable>(as type: T.Type) -> T? {
        try? data(as: type)
    }
}

extension Array where Element == Conversation {
    /// Filter out conversations where the user is chatting with themselves.
    /// In 1-on-1 conversations, ensures there are at least 2 unique participants.
    func excludingSelfChats() -> [Conversation] {
        filter { conversation in
            if conversation.type == .group { return true }
            return Set(conversation.participants).count > 1
        }
    }
}
