//
//  GoogleCalendarService.swift
//  Yaip
//
//  Service for accessing Google Calendar via Google Sign-In SDK
//

import Foundation
import Combine
import GoogleSignIn

/// Service for accessing Google Calendar
@MainActor
class GoogleCalendarService: ObservableObject, CalendarProvider {
    static let shared = GoogleCalendarService()

    @Published var isAuthorized = false
    @Published var userEmail: String?

    // CalendarProvider conformance
    var providerName: String { "Google Calendar" }
    var userIdentifier: String? { userEmail }

    // Calendar API scope
    private let calendarScope = "https://www.googleapis.com/auth/calendar.readonly"

    private init() {
        // Check if user is already signed in
        restorePreviousSignIn()
    }

    /// Restore previous sign-in state if available
    private func restorePreviousSignIn() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            self.isAuthorized = user.grantedScopes?.contains(calendarScope) ?? false
            self.userEmail = user.profile?.email
            print("✅ Restored Google Sign-In: \(userEmail ?? "unknown")")
        }
    }

    /// Request access to Google Calendar
    func requestAccess() async throws -> Bool {
        // Get the root view controller for presenting the sign-in UI
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw CalendarError.notSupported("Unable to present sign-in UI")
        }

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    // Check if user is already signed in
                    if let currentUser = GIDSignIn.sharedInstance.currentUser {
                        // Check if we have the calendar scope
                        if currentUser.grantedScopes?.contains(calendarScope) == true {
                            // Already have access
                            self.isAuthorized = true
                            self.userEmail = currentUser.profile?.email
                            print("✅ Already signed in to Google Calendar")
                            continuation.resume(returning: true)
                            return
                        } else {
                            // Need to request additional scope
                            print("🔄 Requesting additional calendar scope...")
                            let result = try await currentUser.addScopes([calendarScope], presenting: rootViewController)
                            self.isAuthorized = true
                            self.userEmail = result.user.profile?.email
                            print("✅ Google Calendar scope granted")
                            continuation.resume(returning: true)
                            return
                        }
                    }

                    // Fresh sign-in required
                    print("🔐 Starting Google Sign-In...")
                    let result = try await GIDSignIn.sharedInstance.signIn(
                        withPresenting: rootViewController,
                        hint: nil,
                        additionalScopes: [calendarScope]
                    )

                    self.isAuthorized = true
                    self.userEmail = result.user.profile?.email
                    print("✅ Google Sign-In successful: \(self.userEmail ?? "unknown")")
                    continuation.resume(returning: true)

                } catch {
                    print("❌ Google Sign-In failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Check availability for given time slots
    func checkAvailability(for timeSlots: [TimeSlot]) async -> [TimeSlot] {
        guard isAuthorized else {
            print("⚠️ Google Calendar not authorized")
            return timeSlots
        }

        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("⚠️ No Google user signed in")
            return timeSlots
        }

        // Get access token
        let accessToken = user.accessToken.tokenString

        // Get date range from time slots
        guard let firstSlot = timeSlots.first, let lastSlot = timeSlots.last else {
            return timeSlots
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: firstSlot.date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: lastSlot.date) ?? lastSlot.date

        do {
            // Call Google Calendar freebusy API
            let busyPeriods = try await fetchBusyPeriods(
                accessToken: accessToken,
                startDate: startDate,
                endDate: endDate
            )

            // Check each time slot against busy periods
            return timeSlots.map { slot in
                let slotStart = combineDateAndTime(date: slot.date, time: slot.startTime)
                let slotEnd = combineDateAndTime(date: slot.date, time: slot.endTime)

                let hasConflict = busyPeriods.contains { busyPeriod in
                    return eventsOverlap(
                        event1Start: slotStart,
                        event1End: slotEnd,
                        event2Start: busyPeriod.start,
                        event2End: busyPeriod.end
                    )
                }

                var updatedSlot = slot
                // If isUserFree is already false (from another calendar), keep it false
                if let currentFree = updatedSlot.isUserFree, !currentFree {
                    updatedSlot.isUserFree = false
                } else {
                    updatedSlot.isUserFree = !hasConflict
                }
                return updatedSlot
            }

        } catch {
            print("❌ Error checking Google Calendar availability: \(error)")
            return timeSlots
        }
    }

    /// Disconnect from Google Calendar
    func disconnect() async throws {
        GIDSignIn.sharedInstance.signOut()
        isAuthorized = false
        userEmail = nil
        print("✅ Signed out from Google Calendar")
    }

    // MARK: - Private Helpers

    /// Fetch busy periods from Google Calendar API
    private func fetchBusyPeriods(accessToken: String, startDate: Date, endDate: Date) async throws -> [BusyPeriod] {
        let urlString = "https://www.googleapis.com/calendar/v3/freeBusy"
        guard let url = URL(string: urlString) else {
            throw CalendarError.noEventsFound
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Format dates for API
        let dateFormatter = ISO8601DateFormatter()
        let requestBody: [String: Any] = [
            "timeMin": dateFormatter.string(from: startDate),
            "timeMax": dateFormatter.string(from: endDate),
            "items": [
                ["id": "primary"] // Check primary calendar
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ Google Calendar API error: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            throw CalendarError.noEventsFound
        }

        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let calendars = json?["calendars"] as? [String: Any],
              let primary = calendars["primary"] as? [String: Any],
              let busy = primary["busy"] as? [[String: Any]] else {
            return [] // No busy periods
        }

        // Parse busy periods
        return busy.compactMap { period in
            guard let startString = period["start"] as? String,
                  let endString = period["end"] as? String,
                  let start = dateFormatter.date(from: startString),
                  let end = dateFormatter.date(from: endString) else {
                return nil
            }
            return BusyPeriod(start: start, end: end)
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
}

/// Represents a busy period from calendar
private struct BusyPeriod {
    let start: Date
    let end: Date
}

// MARK: - Implementation Notes
/*
 Once Google Sign-In SDK is added, implement:

 1. Configure in AppDelegate/SceneDelegate:
    ```swift
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "YOUR_CLIENT_ID")
    ```

 2. Handle URL callback:
    ```swift
    GIDSignIn.sharedInstance.handle(url)
    ```

 3. Sign-in flow:
    ```swift
    let result = try await GIDSignIn.sharedInstance.signIn(
        withPresenting: getRootViewController(),
        hint: nil,
        additionalScopes: ["https://www.googleapis.com/auth/calendar.readonly"]
    )
    ```

 4. API Calls:
    - Use Google Calendar API v3
    - Endpoint: GET https://www.googleapis.com/calendar/v3/freeBusy
    - Parse JSON response for busy/free periods
 */
