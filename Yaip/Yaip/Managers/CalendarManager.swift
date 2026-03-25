//
//  CalendarManager.swift
//  Yaip
//
//  Coordinates multiple calendar providers for availability checking
//

import Foundation
import Combine

/// Manages all calendar providers and coordinates availability checking
@MainActor
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    // Calendar providers
    @Published var appleCalendar: AppleCalendarService
    @Published var googleCalendar: GoogleCalendarService?

    // Enabled providers (persisted)
    @Published var enabledProviders: Set<CalendarProviderType> = []

    private let enabledProvidersKey = "enabled_calendar_providers"

    private init() {
        // Initialize Apple Calendar (always available)
        self.appleCalendar = AppleCalendarService.shared

        // Load enabled providers from UserDefaults (decode gracefully if stored values include removed cases)
        if let data = UserDefaults.standard.data(forKey: enabledProvidersKey),
           let rawStrings = try? JSONDecoder().decode(Set<String>.self, from: data) {
            let valid = Set(rawStrings.compactMap { CalendarProviderType(rawValue: $0) })
            self.enabledProviders = valid
            if valid.count != rawStrings.count {
                saveEnabledProviders()
            }
        }

        // Initialize other providers if they were previously enabled
        if enabledProviders.contains(.google) {
            self.googleCalendar = GoogleCalendarService.shared
        }
    }

    /// Check if any calendar provider is connected
    var hasAnyProviderConnected: Bool {
        return appleCalendar.isAuthorized ||
               (googleCalendar?.isAuthorized ?? false)
    }

    /// Get all connected providers
    var connectedProviders: [CalendarProviderType] {
        var providers: [CalendarProviderType] = []

        if appleCalendar.isAuthorized {
            providers.append(.apple)
        }
        if googleCalendar?.isAuthorized == true {
            providers.append(.google)
        }

        return providers
    }

    /// Check availability across ALL connected calendar providers
    /// Returns time slots enriched with availability info from all calendars
    /// CONSERVATIVE: Marks as busy if ANY calendar has a conflict
    func checkAvailability(for timeSlots: [TimeSlot]) async -> [TimeSlot] {
        var enrichedSlots = timeSlots

        // Check Apple Calendar (synchronous)
        if enabledProviders.contains(.apple) && appleCalendar.isAuthorized {
            enrichedSlots = appleCalendar.checkAvailability(for: enrichedSlots)
            print("📅 Checked Apple Calendar availability")
        }

        // Check Google Calendar (async)
        if enabledProviders.contains(.google),
           let google = googleCalendar,
           google.isAuthorized {
            enrichedSlots = await google.checkAvailability(for: enrichedSlots)
            print("📅 Checked Google Calendar availability")
        }

        return enrichedSlots
    }

    /// Enable a calendar provider
    func enableProvider(_ type: CalendarProviderType) {
        enabledProviders.insert(type)
        saveEnabledProviders()

        // Initialize provider if needed
        switch type {
        case .apple:
            break // Already initialized
        case .google:
            if googleCalendar == nil {
                googleCalendar = GoogleCalendarService.shared
            }
        }
    }

    /// Disable a calendar provider
    func disableProvider(_ type: CalendarProviderType) {
        enabledProviders.remove(type)
        saveEnabledProviders()
    }

    /// Save enabled providers to UserDefaults
    private func saveEnabledProviders() {
        if let data = try? JSONEncoder().encode(enabledProviders) {
            UserDefaults.standard.set(data, forKey: enabledProvidersKey)
        }
    }

    /// Get provider by type
    func getProvider(_ type: CalendarProviderType) -> (any CalendarProvider)? {
        switch type {
        case .apple:
            return appleCalendar
        case .google:
            return googleCalendar
        }
    }
}
