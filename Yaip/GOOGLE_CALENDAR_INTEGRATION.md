# Google Calendar Integration Plan

## Current State
✅ **Apple Calendar (EventKit)** - Fully implemented
- AppleCalendarService.swift - Checks user availability
- CalendarSettingsView.swift - Permission UI
- Integration with Meeting Suggestions

## Google Calendar Integration Architecture

### Overview
Add Google Calendar as a second calendar provider option, allowing users to connect either Apple Calendar, Google Calendar, or both for comprehensive availability checking.

---

## Implementation Options

### Option A: Google Sign-In SDK (Recommended)
**Pros:**
- Official Google SDK
- Handles OAuth flow automatically
- Better security and token management
- Refresh tokens handled automatically

**Cons:**
- Adds ~5MB to app size
- Requires Google Cloud Console setup
- More complex initial setup

**SDK:** `GoogleSignIn` + `GoogleAPIClientForREST`

### Option B: Manual OAuth 2.0
**Pros:**
- No additional dependencies
- Smaller app size
- Full control over auth flow

**Cons:**
- More code to maintain
- Manual token refresh logic
- Manual OAuth implementation prone to errors

**Recommended: Option A** for production quality and maintainability.

---

## Prerequisites

### 1. Google Cloud Console Setup
1. Create project at https://console.cloud.google.com
2. Enable Google Calendar API
3. Create OAuth 2.0 Client ID (iOS)
   - Bundle ID: `com.yaip.app` (or your bundle ID)
   - Get Client ID and download config file
4. Add authorized redirect URI: `com.googleusercontent.apps.YOUR_CLIENT_ID:/oauth2redirect`

### 2. Add Dependencies
**Package.swift or CocoaPods:**
```swift
// Swift Package Manager
dependencies: [
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    .package(url: "https://github.com/google/google-api-objectivec-client-for-rest", from: "3.0.0")
]
```

OR

**Podfile:**
```ruby
pod 'GoogleSignIn', '~> 7.0'
pod 'GoogleAPIClientForREST/Calendar', '~> 3.0'
```

### 3. Update Info.plist
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>

<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
```

---

## Architecture Design

### 1. Calendar Provider Protocol
Create a unified interface for all calendar providers:

```swift
// CalendarProvider.swift
protocol CalendarProvider {
    var isAuthorized: Bool { get }
    var providerName: String { get }

    func requestAccess() async throws -> Bool
    func checkAvailability(for timeSlots: [TimeSlot]) async -> [TimeSlot]
    func disconnect() async throws
}

enum CalendarProviderType: String, CaseIterable, Identifiable {
    case apple = "Apple Calendar"
    case google = "Google Calendar"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .apple: return "calendar"
        case .google: return "globe"
        }
    }
}
```

### 2. Calendar Manager (Coordinator)
Manages multiple calendar providers:

```swift
// CalendarManager.swift
@MainActor
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    @Published var enabledProviders: Set<CalendarProviderType> = []
    @Published var appleCalendar: AppleCalendarService
    @Published var googleCalendar: GoogleCalendarService

    // Check availability across all enabled providers
    func checkAvailability(for timeSlots: [TimeSlot]) async -> [TimeSlot] {
        var enrichedSlots = timeSlots

        // Check Apple Calendar if enabled
        if enabledProviders.contains(.apple) && appleCalendar.isAuthorized {
            enrichedSlots = appleCalendar.checkAvailability(for: enrichedSlots)
        }

        // Check Google Calendar if enabled
        if enabledProviders.contains(.google) && googleCalendar.isAuthorized {
            enrichedSlots = await googleCalendar.checkAvailability(for: enrichedSlots)
        }

        return enrichedSlots
    }
}
```

### 3. Google Calendar Service
```swift
// GoogleCalendarService.swift
import GoogleSignIn
import GoogleAPIClientForRESTCore
import GTMSessionFetcherCore

@MainActor
class GoogleCalendarService: ObservableObject, CalendarProvider {
    static let shared = GoogleCalendarService()

    @Published var isAuthorized = false
    @Published var userEmail: String?

    private var calendarService: GTLRCalendarService?

    var providerName: String { "Google Calendar" }

    func requestAccess() async throws -> Bool {
        // Implement Google Sign-In flow
        // Request calendar.readonly scope
    }

    func checkAvailability(for timeSlots: [TimeSlot]) async -> [TimeSlot] {
        // Fetch events from Google Calendar API
        // Check for conflicts
    }

    func disconnect() async throws {
        // Sign out and revoke tokens
    }
}
```

---

## UI Updates

### 1. Updated CalendarSettingsView
```swift
struct CalendarSettingsView: View {
    @StateObject private var calendarManager = CalendarManager.shared

    var body: some View {
        Form {
            // Apple Calendar Section
            Section("Apple Calendar") {
                // Existing Apple Calendar UI
            }

            // Google Calendar Section
            Section("Google Calendar") {
                if calendarManager.googleCalendar.isAuthorized {
                    // Connected state
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connected: \(calendarManager.googleCalendar.userEmail ?? "Unknown")")
                    }

                    Button("Disconnect", role: .destructive) {
                        Task {
                            try? await calendarManager.googleCalendar.disconnect()
                        }
                    }
                } else {
                    // Not connected state
                    Button("Connect Google Calendar") {
                        Task {
                            try? await calendarManager.googleCalendar.requestAccess()
                        }
                    }
                }
            }

            // Info section
            Section("About") {
                Text("Connect multiple calendars for comprehensive availability checking.")
            }
        }
    }
}
```

### 2. Updated MeetingSuggestionsView
```swift
// Update header to show which calendars are connected
var calendarStatus: some View {
    HStack(spacing: 8) {
        if calendarManager.enabledProviders.contains(.apple) {
            Label("Apple", systemImage: "calendar")
        }
        if calendarManager.enabledProviders.contains(.google) {
            Label("Google", systemImage: "globe")
        }
    }
}
```

---

## Implementation Steps

### Phase 1: Setup & Dependencies (1-2 hours)
1. ✅ Set up Google Cloud Console project
2. ✅ Enable Google Calendar API
3. ✅ Create OAuth credentials
4. ✅ Add GoogleSignIn SDK to project
5. ✅ Update Info.plist with URL schemes

### Phase 2: Protocol & Architecture (1 hour)
1. ✅ Create CalendarProvider protocol
2. ✅ Create CalendarProviderType enum
3. ✅ Update AppleCalendarService to conform to protocol
4. ✅ Create CalendarManager coordinator

### Phase 3: Google Calendar Service (3-4 hours)
1. ✅ Implement GoogleCalendarService
2. ✅ OAuth sign-in flow
3. ✅ Token storage and refresh
4. ✅ Fetch events from Google Calendar API
5. ✅ Parse and check availability
6. ✅ Handle errors and edge cases

### Phase 4: UI Updates (1-2 hours)
1. ✅ Update CalendarSettingsView
2. ✅ Add Google Calendar connection UI
3. ✅ Update MeetingSuggestionsView
4. ✅ Show multiple calendar status

### Phase 5: Integration & Testing (2-3 hours)
1. ✅ Update AIFeaturesViewModel to use CalendarManager
2. ✅ Test with both calendars connected
3. ✅ Test with only one calendar
4. ✅ Test disconnect/reconnect flows
5. ✅ Test availability checking across both calendars

**Total Estimated Time: 8-12 hours**

---

## Key Decisions Needed

### 1. Calendar Priority
**Question:** If both calendars are connected and show conflicts, how should we prioritize?

**Options:**
- A) Show as busy if EITHER calendar has a conflict (more conservative)
- B) Show as busy only if BOTH calendars have a conflict (less conservative)
- C) Let user choose priority in settings

**Recommendation:** Option A (most conservative - safer for scheduling)

### 2. Calendar Selection UI
**Question:** Should users select which calendars to check per meeting, or globally?

**Options:**
- A) Global setting (applies to all meeting suggestions)
- B) Per-meeting toggle (more flexible but complex)

**Recommendation:** Option A (simpler, cleaner UX)

### 3. Offline Behavior
**Question:** What happens if Google Calendar API is unreachable?

**Options:**
- A) Show warning, continue with available calendars
- B) Fail the entire availability check
- C) Cache last known availability (24 hours)

**Recommendation:** Option A + C (graceful degradation + caching)

---

## Security Considerations

1. **Token Storage**
   - Use iOS Keychain for Google tokens
   - Never log or expose tokens
   - Implement automatic token refresh

2. **Scope Minimization**
   - Request only `calendar.readonly` scope
   - Don't request write access unless needed

3. **User Privacy**
   - Clear indication of what data is accessed
   - Easy disconnect option
   - No event data stored locally (only availability)

---

## Testing Checklist

- [ ] Google OAuth flow works
- [ ] Token refresh works automatically
- [ ] Availability check with Google Calendar only
- [ ] Availability check with Apple Calendar only
- [ ] Availability check with both calendars
- [ ] Disconnect Google Calendar
- [ ] Reconnect Google Calendar
- [ ] Handle API errors gracefully
- [ ] Handle network errors gracefully
- [ ] UI updates correctly based on connection status

---

## Future Enhancements

### V2 Features
- Microsoft Outlook Calendar support
- Calendar event creation from meeting suggestions
- Sync meeting RSVPs back to calendar
- Multiple Google accounts
- Calendar-specific settings (which calendars to check)

### V3 Features
- Automatic meeting scheduling (find mutual availability)
- Calendar analytics (meeting time patterns)
- Smart scheduling preferences (preferred times, buffer times)

---

## Questions for User

1. **Google Cloud Console**: Do you already have a Google Cloud project, or should I guide you through setup?

2. **Dependencies**: Prefer Swift Package Manager or CocoaPods for Google SDK?

3. **Calendar Priority**: Use Option A (busy if EITHER has conflict)?

4. **Scope**: Start with read-only access, or plan for write access (creating events)?

5. **Testing**: Do you have a Google account with calendar events for testing?

---

## Next Steps

Once you answer the questions above, I can:
1. Create the protocol and architecture files
2. Implement GoogleCalendarService
3. Update the UI components
4. Guide you through Google Cloud Console setup

Let me know your preferences and we'll proceed!
