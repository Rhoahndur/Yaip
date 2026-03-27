import Foundation
@testable import Yaip

final class MockEventCreator: EventCreatorProtocol {
    var isAuthorized: Bool = true
    var shouldFail = false
    var createdEvents: [(title: String, startDate: Date, endDate: Date, notes: String?)] = []
    var eventIDToReturn = "mock-event-123"

    func createEvent(title: String, startDate: Date, endDate: Date, notes: String?) async throws -> String {
        if shouldFail { throw CalendarError.notAuthorized }
        createdEvents.append((title, startDate, endDate, notes))
        return eventIDToReturn
    }
}
