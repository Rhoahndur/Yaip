import Foundation

/// Contract for checking calendar availability across providers.
protocol CalendarManagerProtocol {
    var hasAnyProviderConnected: Bool { get }
    func checkAvailability(for timeSlots: [TimeSlot]) async -> [TimeSlot]
}

/// Contract for creating calendar events.
protocol EventCreatorProtocol {
    var isAuthorized: Bool { get }
    func createEvent(title: String, startDate: Date, endDate: Date, notes: String?) async throws -> String
}
