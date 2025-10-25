//
//  OutlookCalendarService.swift
//  Yaip
//
//  Service for accessing Outlook/Microsoft 365 Calendar via Microsoft Graph API
//

import Foundation
import Combine
import MSAL

/// Service for accessing Outlook Calendar
@MainActor
class OutlookCalendarService: ObservableObject, CalendarProvider {
    static let shared = OutlookCalendarService()

    @Published var isAuthorized = false
    @Published var userEmail: String?

    // CalendarProvider conformance
    var providerName: String { "Outlook Calendar" }
    var userIdentifier: String? { userEmail }

    // MSAL configuration
    private var msalApplication: MSALPublicClientApplication?
    private let calendarScope = "Calendars.Read"
    private let graphBaseURL = "https://graph.microsoft.com/v1.0"

    // Load configuration from Info.plist
    private var clientID: String {
        return Bundle.main.object(forInfoDictionaryKey: "MSALClientID") as? String ?? ""
    }

    private var redirectURI: String {
        return "msauth.\(Bundle.main.bundleIdentifier ?? "")://auth"
    }

    private init() {
        configureMSAL()
        restorePreviousSignIn()
    }

    /// Configure MSAL application
    private func configureMSAL() {
        do {
            let authority = try MSALAADAuthority(url: URL(string: "https://login.microsoftonline.com/common")!)

            let config = MSALPublicClientApplicationConfig(
                clientId: clientID,
                redirectUri: redirectURI,
                authority: authority
            )

            msalApplication = try MSALPublicClientApplication(configuration: config)
            print("✅ MSAL configured successfully")

        } catch {
            print("❌ Failed to configure MSAL: \(error.localizedDescription)")
        }
    }

    /// Restore previous sign-in state if available
    private func restorePreviousSignIn() {
        guard let application = msalApplication else { return }

        do {
            let accounts = try application.allAccounts()

            if let account = accounts.first {
                // Try to acquire token silently
                let parameters = MSALSilentTokenParameters(scopes: [calendarScope], account: account)

                Task {
                    do {
                        let result = try await application.acquireTokenSilent(with: parameters)
                        self.isAuthorized = true
                        self.userEmail = account.username
                        print("✅ Restored Outlook sign-in: \(account.username ?? "unknown")")
                    } catch {
                        print("⚠️ Could not restore Outlook session: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("⚠️ Error checking for existing Outlook accounts: \(error.localizedDescription)")
        }
    }

    /// Request access to Outlook Calendar
    func requestAccess() async throws -> Bool {
        guard let application = msalApplication else {
            throw CalendarError.notSupported("MSAL not configured")
        }

        // Get the root view controller for presenting the sign-in UI
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw CalendarError.notSupported("Unable to present sign-in UI")
        }

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    // Check if we already have an account
                    let accounts = try application.allAccounts()

                    if let account = accounts.first {
                        // Try silent token acquisition
                        let silentParameters = MSALSilentTokenParameters(scopes: [calendarScope], account: account)

                        do {
                            let result = try await application.acquireTokenSilent(with: silentParameters)
                            self.isAuthorized = true
                            self.userEmail = account.username
                            print("✅ Outlook token acquired silently")
                            continuation.resume(returning: true)
                            return
                        } catch {
                            print("⚠️ Silent acquisition failed, will try interactive: \(error)")
                        }
                    }

                    // Interactive sign-in required
                    print("🔐 Starting Outlook interactive sign-in...")

                    let webviewParameters = MSALWebviewParameters(authPresentationViewController: rootViewController)
                    let interactiveParameters = MSALInteractiveTokenParameters(
                        scopes: [calendarScope],
                        webviewParameters: webviewParameters
                    )

                    let result = try await application.acquireToken(with: interactiveParameters)

                    self.isAuthorized = true
                    self.userEmail = result.account.username
                    print("✅ Outlook sign-in successful: \(self.userEmail ?? "unknown")")
                    continuation.resume(returning: true)

                } catch {
                    print("❌ Outlook sign-in failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Check availability for given time slots
    func checkAvailability(for timeSlots: [TimeSlot]) async -> [TimeSlot] {
        guard isAuthorized else {
            print("⚠️ Outlook Calendar not authorized")
            return timeSlots
        }

        guard let application = msalApplication else {
            print("⚠️ MSAL not configured")
            return timeSlots
        }

        // Get access token
        do {
            let accounts = try application.allAccounts()
            guard let account = accounts.first else {
                print("⚠️ No Outlook account found")
                return timeSlots
            }

            let parameters = MSALSilentTokenParameters(scopes: [calendarScope], account: account)
            let result = try await application.acquireTokenSilent(with: parameters)
            let accessToken = result.accessToken

            // Get date range from time slots
            guard let firstSlot = timeSlots.first, let lastSlot = timeSlots.last else {
                return timeSlots
            }

            let calendar = Calendar.current
            let startDate = calendar.startOfDay(for: firstSlot.date)
            let endDate = calendar.date(byAdding: .day, value: 1, to: lastSlot.date) ?? lastSlot.date

            // Fetch busy periods from Microsoft Graph
            let busyPeriods = try await fetchBusyPeriods(
                accessToken: accessToken,
                email: account.username ?? "",
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
            print("❌ Error checking Outlook Calendar availability: \(error)")
            return timeSlots
        }
    }

    /// Disconnect from Outlook Calendar
    func disconnect() async throws {
        guard let application = msalApplication else {
            throw CalendarError.notSupported("MSAL not configured")
        }

        do {
            let accounts = try application.allAccounts()

            for account in accounts {
                try await application.remove(account)
            }

            isAuthorized = false
            userEmail = nil
            print("✅ Signed out from Outlook Calendar")

        } catch {
            print("❌ Error signing out from Outlook: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Private Helpers

    /// Fetch busy periods from Microsoft Graph API
    private func fetchBusyPeriods(accessToken: String, email: String, startDate: Date, endDate: Date) async throws -> [BusyPeriod] {
        let urlString = "\(graphBaseURL)/me/calendar/getSchedule"
        guard let url = URL(string: urlString) else {
            throw CalendarError.noEventsFound
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Format dates for API (ISO 8601 with timezone)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current

        let requestBody: [String: Any] = [
            "schedules": [email],
            "startTime": [
                "dateTime": dateFormatter.string(from: startDate),
                "timeZone": TimeZone.current.identifier
            ],
            "endTime": [
                "dateTime": dateFormatter.string(from: endDate),
                "timeZone": TimeZone.current.identifier
            ],
            "availabilityViewInterval": 30 // 30-minute intervals
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ Microsoft Graph API error: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            if let dataString = String(data: data, encoding: .utf8) {
                print("   Response: \(dataString)")
            }
            throw CalendarError.noEventsFound
        }

        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let value = json?["value"] as? [[String: Any]],
              let schedule = value.first,
              let scheduleItems = schedule["scheduleItems"] as? [[String: Any]] else {
            return [] // No busy periods
        }

        // Parse busy periods (filter for "busy", "tentative", "oof" - out of office)
        return scheduleItems.compactMap { item in
            guard let status = item["status"] as? String,
                  ["busy", "tentative", "oof"].contains(status.lowercased()),
                  let startDict = item["start"] as? [String: String],
                  let endDict = item["end"] as? [String: String],
                  let startString = startDict["dateTime"],
                  let endString = endDict["dateTime"],
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

// MARK: - MSAL Extension for Swift Concurrency
extension MSALPublicClientApplication {
    func acquireToken(with parameters: MSALInteractiveTokenParameters) async throws -> MSALResult {
        try await withCheckedThrowingContinuation { continuation in
            self.acquireToken(with: parameters) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: CalendarError.notSupported("Unknown MSAL error"))
                }
            }
        }
    }

    func acquireTokenSilent(with parameters: MSALSilentTokenParameters) async throws -> MSALResult {
        try await withCheckedThrowingContinuation { continuation in
            self.acquireTokenSilent(with: parameters) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: CalendarError.notSupported("Unknown MSAL error"))
                }
            }
        }
    }

    func remove(_ account: MSALAccount) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.remove(account) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
