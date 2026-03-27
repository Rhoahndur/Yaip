import Foundation
@testable import Yaip

final class MockCalendarManager: CalendarManagerProtocol {
    var hasAnyProviderConnected: Bool = false
    var availabilityResult: [TimeSlot]?

    func checkAvailability(for timeSlots: [TimeSlot]) async -> [TimeSlot] {
        availabilityResult ?? timeSlots
    }
}
