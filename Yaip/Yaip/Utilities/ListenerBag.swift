import FirebaseFirestore

/// Non-Sendable container for Firestore ListenerRegistration references.
/// Owns listeners and removes them in deinit, avoiding @MainActor isolation
/// boundary crossings that require nonisolated(unsafe).
final class ListenerBag {
    private var listeners: [String: ListenerRegistration] = [:]

    /// Store a listener under a key. If a listener already exists for that key, it is removed first.
    func store(_ listener: ListenerRegistration, key: String) {
        listeners[key]?.remove()
        listeners[key] = listener
    }

    /// Remove and release a single listener by key.
    func remove(key: String) {
        listeners[key]?.remove()
        listeners[key] = nil
    }

    /// Remove and release all stored listeners.
    func removeAll() {
        for listener in listeners.values {
            listener.remove()
        }
        listeners.removeAll()
    }

    deinit {
        removeAll()
    }
}
