//
//  AppleCalendarService.swift
//  Yaip
//
//  Created for Calendar Integration
//

import Foundation
import EventKit
import Combine

/// Service for accessing Apple Calendar (EventKit) to check availability
@MainActor
class AppleCalendarService: ObservableObject, CalendarProvider {
    static let shared = AppleCalendarService()

    private let eventStore = EKEventStore()

    @Published var isAuthorized = false
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    // CalendarProvider conformance
    var providerName: String { "Apple Calendar" }
    var userIdentifier: String? { nil } // Apple Calendar doesn't expose user email

    private init() {
        checkAuthorizationStatus()
    }

    /// Check current authorization status
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        // iOS 17.0+ uses .fullAccess and .writeOnly instead of deprecated .authorized
        isAuthorized = (authorizationStatus == .fullAccess || authorizationStatus == .writeOnly)
    }

    /// Request calendar access permission
    func requestAccess() async throws -> Bool {
        let granted: Bool

        if #available(iOS 17.0, *) {
            granted = try await eventStore.requestFullAccessToEvents()
        } else {
            granted = try await eventStore.requestAccess(to: .event)
        }

        await MainActor.run {
            self.isAuthorized = granted
            self.checkAuthorizationStatus()
        }

        return granted
    }

    /// Check if user is free at specific time slots
    func checkAvailability(for timeSlots: [TimeSlot]) -> [TimeSlot] {
        guard isAuthorized else {
            return timeSlots // Return unchanged if not authorized
        }

        // Get date range from time slots
        guard let firstSlot = timeSlots.first, let lastSlot = timeSlots.last else {
            return timeSlots
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: firstSlot.date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: lastSlot.date) ?? lastSlot.date

        // Get all calendars
        let calendars = eventStore.calendars(for: .event)

        // Create predicate for date range
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )

        // Fetch events
        let events = eventStore.events(matching: predicate)

        // Check each time slot
        return timeSlots.map { slot in
            let slotStart = combineDateAndTime(date: slot.date, time: slot.startTime)
            let slotEnd = combineDateAndTime(date: slot.date, time: slot.endTime)

            // Check if this slot conflicts with any event
            let hasConflict = events.contains { event in
                return eventsOverlap(
                    event1Start: slotStart,
                    event1End: slotEnd,
                    event2Start: event.startDate,
                    event2End: event.endDate
                )
            }

            var updatedSlot = slot
            updatedSlot.isUserFree = !hasConflict
            return updatedSlot
        }
    }

    /// Check if two time ranges overlap
    private func eventsOverlap(
        event1Start: Date,
        event1End: Date,
        event2Start: Date,
        event2End: Date
    ) -> Bool {
        return (event1Start < event2End && event1End > event2Start)
    }

    /// Check if date is a weekend
    private func isWeekend(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // Sunday or Saturday
    }

    /// Check if time is during business hours (9am - 5pm)
    private func isBusinessHours(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return hour >= 9 && hour < 17
    }

    /// Combine date and time string into a single Date
    private func combineDateAndTime(date: Date, time: String) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        // Parse time string (e.g., "14:00")
        let timeComponents = time.split(separator: ":")
        guard timeComponents.count == 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            return date
        }

        var components = dateComponents
        components.hour = hour
        components.minute = minute
        components.second = 0

        return calendar.date(from: components) ?? date
    }

    /// Create a calendar event
    func createEvent(title: String, startDate: Date, endDate: Date, notes: String? = nil) async throws -> String {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ Created calendar event: \(title) on \(startDate.formatted())")
            return event.eventIdentifier
        } catch {
            print("❌ Failed to create calendar event: \(error)")
            throw CalendarError.notSupported("Failed to create event: \(error.localizedDescription)")
        }
    }

    /// Disconnect from Apple Calendar (not applicable - managed by system)
    func disconnect() async throws {
        // Apple Calendar permissions are managed by iOS Settings
        // Users must go to Settings → Yaip → Calendars to revoke
        throw CalendarError.notSupported("Apple Calendar permissions are managed in iOS Settings")
    }
}

/// Calendar service errors
enum CalendarError: LocalizedError {
    case notAuthorized
    case accessDenied
    case noEventsFound
    case notSupported(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized"
        case .accessDenied:
            return "Calendar access denied by user"
        case .noEventsFound:
            return "No calendar events found"
        case .notSupported(let message):
            return message
        }
    }
}
