//
//  CalendarProvider.swift
//  Yaip
//
//  Protocol for unified calendar provider interface
//

import Foundation

/// Protocol that all calendar providers must conform to
protocol CalendarProvider {
    /// Whether the provider is currently authorized
    var isAuthorized: Bool { get }

    /// Display name of the provider
    var providerName: String { get }

    /// User's email/identifier (if connected)
    var userIdentifier: String? { get }

    /// Request authorization to access calendar
    func requestAccess() async throws -> Bool

    /// Check availability for given time slots
    func checkAvailability(for timeSlots: [TimeSlot]) async -> [TimeSlot]

    /// Disconnect/sign out from the provider
    func disconnect() async throws
}

/// Enum representing different calendar provider types
enum CalendarProviderType: String, CaseIterable, Identifiable, Codable {
    case apple = "Apple Calendar"
    case google = "Google Calendar"
    case outlook = "Outlook Calendar"

    var id: String { rawValue }

    /// SF Symbol icon for each provider
    var icon: String {
        switch self {
        case .apple: return "calendar"
        case .google: return "globe"
        case .outlook: return "envelope"
        }
    }

    /// Color for each provider
    var color: String {
        switch self {
        case .apple: return "blue"
        case .google: return "red"
        case .outlook: return "blue"
        }
    }

    /// Short description
    var description: String {
        switch self {
        case .apple: return "Built-in iOS calendar"
        case .google: return "Google Workspace calendar"
        case .outlook: return "Microsoft 365 calendar"
        }
    }
}

/// Calendar provider status
enum CalendarProviderStatus {
    case notConnected
    case connecting
    case connected(userIdentifier: String)
    case error(message: String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}
