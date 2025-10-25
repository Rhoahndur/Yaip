# Calendar Integration Guide - Meeting Suggestions AI

## Overview

Your **Meeting Suggestions** AI feature currently analyzes conversation text and suggests times based on patterns. This guide shows how to integrate with Google Calendar, Outlook, and Apple Calendar to check **real availability**.

---

## 🎯 Current State vs. Enhanced State

### Current Implementation
```
User: "Let's schedule a meeting this week"
↓
AI analyzes conversation
↓
Suggests: Mon 2pm, Tue 10am, Wed 3pm (based on heuristics)
```

### Enhanced with Calendar Integration
```
User: "Let's schedule a meeting this week"
↓
AI analyzes conversation
↓
Check participants' calendars (Google/Outlook/Apple)
↓
Suggests: Mon 2pm (all free), Wed 3pm (all free), Thu 10am (all free)
```

**Key Difference**: Real availability vs. guessing

---

## 📊 Calendar Provider Comparison

| Provider | Market Share | Complexity | OAuth | Cost | Best For |
|----------|-------------|------------|-------|------|----------|
| **Google Calendar** | 60% | Medium | Yes | Free API | Most users |
| **Outlook/Office 365** | 30% | Medium | Yes | Free API | Enterprise |
| **Apple Calendar (EventKit)** | iOS only | Low | No | Free | iOS users |
| **Calendly** | 5% | Low | Yes | Paid | Scheduling pros |

**Recommendation**: Start with **Google Calendar** (covers 60% of users), then add Outlook.

---

## 🗓️ Option 1: Google Calendar API (Recommended First)

### Overview
- ✅ Most popular calendar service
- ✅ Excellent API documentation
- ✅ Free API quota (1M requests/day)
- ✅ OAuth 2.0 authentication
- ✅ Read/write events
- ✅ Check free/busy times

### Implementation Steps

#### Step 1: Set Up Google Cloud Project (30 mins)

1. **Create Project**:
   ```
   1. Go to console.cloud.google.com
   2. Create new project: "Yaip Calendar Integration"
   3. Enable Google Calendar API
   ```

2. **Configure OAuth Consent Screen**:
   ```
   1. OAuth consent screen → External
   2. App name: "Yaip"
   3. Support email: your-email@example.com
   4. Scopes: Add calendar.readonly and calendar.events
   5. Save
   ```

3. **Create OAuth Client ID**:
   ```
   1. Credentials → Create OAuth Client ID
   2. Type: iOS
   3. Bundle ID: com.yourname.Yaip
   4. Download credentials JSON
   ```

4. **Get Client ID and Secret**:
   ```json
   {
     "client_id": "123456.apps.googleusercontent.com",
     "client_secret": "GOCSPX-abcd1234",
     "redirect_uris": ["com.googleusercontent.apps.123456:/oauth2redirect"]
   }
   ```

#### Step 2: Add OAuth to iOS App (2-3 hours)

**Install Google Sign-In SDK**:
```swift
// Package.swift or SPM
dependencies: [
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
]
```

**Create CalendarAuthManager**:
```swift
import GoogleSignIn
import GoogleAPIClientForREST

class CalendarAuthManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var userEmail: String?

    private let signInConfig = GIDConfiguration(
        clientID: "YOUR_CLIENT_ID.apps.googleusercontent.com"
    )

    // Sign in with Google
    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw CalendarError.noViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: [
                "https://www.googleapis.com/auth/calendar.readonly",
                "https://www.googleapis.com/auth/calendar.events"
            ]
        )

        await MainActor.run {
            self.isAuthorized = true
            self.userEmail = result.user.profile?.email
        }

        // Store tokens securely
        if let idToken = result.user.idToken?.tokenString,
           let accessToken = result.user.accessToken.tokenString {
            KeychainHelper.save(accessToken, for: "google_access_token")
            KeychainHelper.save(idToken, for: "google_id_token")
        }
    }

    // Get access token
    func getAccessToken() -> String? {
        return KeychainHelper.load(for: "google_access_token")
    }
}
```

#### Step 3: Create N8N Workflow to Check Availability (2 hours)

**Workflow**: `meeting-suggestions-with-calendar`

```
1. Webhook Trigger (receive request from iOS)
   Input: {
     conversationID,
     participants: [userIDs],
     dateRange: "2025-11-01 to 2025-11-07"
   }

2. Get Participant Emails (Firebase)
   - Fetch user documents for all participants
   - Extract email addresses

3. For Each Participant:
   a. HTTP Request (Google Calendar API)
      GET https://www.googleapis.com/calendar/v3/freeBusy
      Headers: Authorization: Bearer {accessToken}
      Body: {
        "timeMin": "2025-11-01T00:00:00Z",
        "timeMax": "2025-11-07T23:59:59Z",
        "items": [{"id": "user@gmail.com"}]
      }

   b. Parse Free/Busy Response
      {
        "calendars": {
          "user@gmail.com": {
            "busy": [
              {"start": "2025-11-01T14:00:00Z", "end": "2025-11-01T15:00:00Z"},
              {"start": "2025-11-01T16:00:00Z", "end": "2025-11-01T17:00:00Z"}
            ]
          }
        }
      }

4. Merge Availability
   - Code node: Find time slots where ALL participants are free
   - Filter by business hours (9am-5pm)
   - Return 3-5 best options

5. Call AI (OpenAI)
   - Analyze conversation context
   - Rank suggested times by preference
   - Format recommendations

6. Respond to Webhook
   Return: {
     "success": true,
     "suggestions": [
       {
         "dateTime": "2025-11-01T14:00:00Z",
         "duration": 60,
         "availability": "all_free",
         "participants": ["user1@gmail.com", "user2@gmail.com"],
         "reason": "Optimal time based on conversation"
       }
     ]
   }
```

**N8N Code Node - Merge Availability**:
```javascript
// Get all participants' busy times
const participants = $input.all().map(item => ({
  email: item.json.email,
  busy: item.json.freeBusy.calendars[item.json.email].busy || []
}));

// Define time slots to check (30-min intervals)
const startDate = new Date('2025-11-01T09:00:00Z');
const endDate = new Date('2025-11-07T17:00:00Z');
const slots = [];

let current = new Date(startDate);
while (current < endDate) {
  // Skip weekends
  if (current.getDay() !== 0 && current.getDay() !== 6) {
    const slotEnd = new Date(current.getTime() + 60 * 60 * 1000); // 1 hour

    // Check if ALL participants are free
    const allFree = participants.every(p => {
      return !p.busy.some(b => {
        const busyStart = new Date(b.start);
        const busyEnd = new Date(b.end);
        return (current >= busyStart && current < busyEnd) ||
               (slotEnd > busyStart && slotEnd <= busyEnd) ||
               (current <= busyStart && slotEnd >= busyEnd);
      });
    });

    if (allFree) {
      slots.push({
        start: current.toISOString(),
        end: slotEnd.toISOString(),
        participants: participants.map(p => p.email)
      });
    }
  }

  current = new Date(current.getTime() + 30 * 60 * 1000); // Next 30-min slot
}

// Return top 5 slots
return [{
  json: {
    availableSlots: slots.slice(0, 5),
    totalSlotsChecked: slots.length
  }
}];
```

#### Step 4: Update iOS CalendarService (1 hour)

**Create CalendarService.swift**:
```swift
import Foundation

class CalendarService {
    static let shared = CalendarService()
    private let authManager = CalendarAuthManager.shared

    // Check availability via N8N (which calls Google Calendar API)
    func checkAvailability(
        participants: [String],
        dateRange: DateInterval
    ) async throws -> [TimeSlot] {

        let request = CalendarAvailabilityRequest(
            participants: participants,
            startDate: dateRange.start,
            endDate: dateRange.end
        )

        // Call N8N workflow
        guard let url = URL(string: "\(Config.n8nBaseURL)/meeting-availability") else {
            throw CalendarError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(Config.n8nAuthToken, forHTTPHeaderField: "Authorization")

        let jsonData = try JSONEncoder().encode(request)
        urlRequest.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CalendarError.requestFailed
        }

        let availabilityResponse = try JSONDecoder().decode(
            CalendarAvailabilityResponse.self,
            from: data
        )

        return availabilityResponse.availableSlots
    }
}

// Models
struct CalendarAvailabilityRequest: Codable {
    let participants: [String]
    let startDate: Date
    let endDate: Date
}

struct CalendarAvailabilityResponse: Codable {
    let success: Bool
    let availableSlots: [TimeSlot]
    let totalChecked: Int
}

struct TimeSlot: Codable, Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let participants: [String]
    let allFree: Bool

    enum CodingKeys: String, CodingKey {
        case start, end, participants, allFree
    }
}
```

#### Step 5: Update AIFeaturesViewModel (30 mins)

**Enhance Meeting Suggestions**:
```swift
// In AIFeaturesViewModel.swift

func suggestMeetingTimesWithCalendar() {
    isLoadingMeeting = true
    showMeetingSuggestion = false
    meetingError = nil

    Task {
        do {
            // Get conversation participants
            let participantIDs = conversation.participants

            // Check if users have connected Google Calendar
            let usersWithCalendar = try await checkCalendarConnections(participantIDs)

            if usersWithCalendar.count >= 2 {
                // Use real calendar availability
                let dateRange = DateInterval(
                    start: Date(),
                    end: Date().addingTimeInterval(7 * 24 * 60 * 60) // Next 7 days
                )

                let availableSlots = try await CalendarService.shared.checkAvailability(
                    participants: usersWithCalendar,
                    dateRange: dateRange
                )

                // Format as meeting suggestions
                await MainActor.run {
                    self.meetingSuggestion = MeetingSuggestion(
                        suggestedTimes: availableSlots.prefix(3).map { slot in
                            TimeSlotData(
                                dateTime: slot.start,
                                duration: 60,
                                available: slot.participants,
                                conflicts: []
                            )
                        },
                        reasoning: "Based on actual calendar availability",
                        confidence: 0.95
                    )
                    self.isLoadingMeeting = false
                    self.showMeetingSuggestion = true
                }
            } else {
                // Fall back to AI-only suggestions (existing behavior)
                try await originalSuggestMeetingTimes()
            }
        } catch {
            await MainActor.run {
                self.meetingError = error.localizedDescription
                self.isLoadingMeeting = false
            }
        }
    }
}

private func checkCalendarConnections(_ userIDs: [String]) async throws -> [String] {
    // Check which users have connected Google Calendar
    // Query Firestore for user calendar connection status
    let db = Firestore.firestore()
    var connectedUsers: [String] = []

    for userID in userIDs {
        let doc = try await db.collection("users").document(userID).getDocument()
        if let data = doc.data(),
           let hasCalendar = data["googleCalendarConnected"] as? Bool,
           hasCalendar {
            connectedUsers.append(userID)
        }
    }

    return connectedUsers
}
```

#### Step 6: Add Settings UI (1 hour)

**CalendarSettingsView.swift**:
```swift
import SwiftUI

struct CalendarSettingsView: View {
    @StateObject private var authManager = CalendarAuthManager.shared

    var body: some View {
        Form {
            Section("Google Calendar") {
                if authManager.isAuthorized {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connected")
                        Spacer()
                        Text(authManager.userEmail ?? "")
                            .foregroundStyle(.secondary)
                    }

                    Button("Disconnect", role: .destructive) {
                        authManager.signOut()
                    }

                    Toggle("Use calendar for meeting suggestions", isOn: $authManager.useSuggestions)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connect your Google Calendar to:")
                            .font(.subheadline)

                        Label("Get real availability", systemImage: "calendar")
                        Label("Smart meeting suggestions", systemImage: "sparkles")
                        Label("Avoid scheduling conflicts", systemImage: "exclamationmark.triangle")
                    }
                    .padding(.vertical, 8)

                    Button {
                        Task {
                            try? await authManager.signInWithGoogle()
                        }
                    } label: {
                        HStack {
                            Image("google-logo") // Add Google logo asset
                            Text("Connect Google Calendar")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Section {
                Text("Yaip will only access your calendar to check availability for meeting suggestions. We never read or modify your calendar events.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Calendar Integration")
    }
}
```

### Security & Privacy

**What to Store**:
```swift
// Store in Firestore (users collection)
{
  "googleCalendarConnected": true,
  "googleCalendarEmail": "user@gmail.com",
  "calendarPermissions": ["readonly"],
  "lastCalendarSync": "2025-11-15T10:00:00Z"
}
```

**What NOT to Store**:
- ❌ Calendar event details
- ❌ Event titles or descriptions
- ❌ Attendee lists
- ❌ Only store: busy/free times

**OAuth Token Storage**:
```swift
// Use Keychain (secure storage)
import Security

class KeychainHelper {
    static func save(_ value: String, for key: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)

        if let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
```

---

## 🗓️ Option 2: Microsoft Outlook / Office 365

### Overview
- ✅ Second most popular (30% market share)
- ✅ Strong in enterprise
- ✅ Microsoft Graph API
- ✅ OAuth 2.0 authentication
- ✅ Free API quota

### Implementation

**Similar to Google but use Microsoft Graph API**:

**API Endpoint**:
```
GET https://graph.microsoft.com/v1.0/me/calendar/getSchedule
```

**Request**:
```json
{
  "schedules": ["user1@company.com", "user2@company.com"],
  "startTime": {
    "dateTime": "2025-11-01T00:00:00",
    "timeZone": "Pacific Standard Time"
  },
  "endTime": {
    "dateTime": "2025-11-07T23:59:59",
    "timeZone": "Pacific Standard Time"
  },
  "availabilityViewInterval": 60
}
```

**Response**:
```json
{
  "value": [
    {
      "scheduleId": "user1@company.com",
      "availabilityView": "222200002222",
      "scheduleItems": [
        {
          "status": "busy",
          "start": { "dateTime": "2025-11-01T14:00:00" },
          "end": { "dateTime": "2025-11-01T15:00:00" }
        }
      ]
    }
  ]
}
```

**N8N Node**: Use "Microsoft Outlook" node instead of HTTP Request

---

## 🍎 Option 3: Apple Calendar (EventKit)

### Overview
- ✅ Native iOS integration
- ✅ No OAuth needed
- ✅ Direct access via EventKit
- ✅ Best UX for iOS users
- ⚠️ iOS only (not cross-platform)

### Implementation (Simplest!)

**No N8N needed - all in iOS app**:

```swift
import EventKit

class AppleCalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var isAuthorized = false

    // Request permission
    func requestAccess() async throws {
        let granted = try await eventStore.requestAccess(to: .event)
        await MainActor.run {
            self.isAuthorized = granted
        }
    }

    // Check availability
    func checkAvailability(
        startDate: Date,
        endDate: Date
    ) -> [TimeSlot] {
        // Fetch all calendars
        let calendars = eventStore.calendars(for: .event)

        // Create predicate for date range
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )

        // Fetch events
        let events = eventStore.events(matching: predicate)

        // Find free slots
        return findFreeSlots(
            between: startDate,
            and: endDate,
            excluding: events
        )
    }

    private func findFreeSlots(
        between startDate: Date,
        and endDate: Date,
        excluding busyEvents: [EKEvent]
    ) -> [TimeSlot] {
        var freeSlots: [TimeSlot] = []
        var current = startDate

        while current < endDate {
            let slotEnd = current.addingTimeInterval(60 * 60) // 1 hour

            // Check if this slot conflicts with any event
            let hasConflict = busyEvents.contains { event in
                event.startDate < slotEnd && event.endDate > current
            }

            if !hasConflict {
                freeSlots.append(TimeSlot(
                    start: current,
                    end: slotEnd,
                    participants: [], // Current user only
                    allFree: true
                ))
            }

            current = current.addingTimeInterval(30 * 60) // Next 30-min slot
        }

        return freeSlots
    }
}
```

**Usage in AIFeaturesViewModel**:
```swift
func suggestMeetingTimesWithAppleCalendar() {
    Task {
        // Request permission first
        try await AppleCalendarService.shared.requestAccess()

        // Check availability
        let dateRange = DateInterval(
            start: Date(),
            end: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )

        let freeSlots = AppleCalendarService.shared.checkAvailability(
            startDate: dateRange.start,
            endDate: dateRange.end
        )

        // Combine with AI analysis
        // ...
    }
}
```

**Pros**:
- ✅ No OAuth complexity
- ✅ No external API calls
- ✅ Works offline
- ✅ Fast

**Cons**:
- ❌ Only checks current user's calendar
- ❌ Can't check other participants
- ❌ iOS only

---

## 🎯 Recommended Implementation Strategy

### Phase 1: Apple Calendar Only (2-3 hours) ⭐ START HERE
**Why**: Simplest, no OAuth, works for MVP

```
1. Add EventKit framework
2. Request calendar permission
3. Check current user's availability
4. Combine with existing AI suggestions
5. Display in MeetingSuggestionsView
```

**Result**: AI suggests times + shows which times YOU are free

---

### Phase 2: Add Google Calendar (1 week)
**Why**: Covers 60% of users, enables multi-participant checking

```
1. Set up Google Cloud project
2. Add OAuth flow
3. Create N8N workflow for calendar API
4. Check all participants' availability
5. Merge with Apple Calendar data
```

**Result**: AI suggests times when ALL participants are free

---

### Phase 3: Add Outlook (3-4 days)
**Why**: Covers enterprise users (30% market)

```
1. Set up Microsoft Azure app
2. Add Microsoft OAuth
3. Update N8N workflow
4. Merge all calendar sources
```

**Result**: Complete calendar coverage (90%+ users)

---

## 💡 Hybrid Approach (Best UX)

**Combine all three sources**:

```swift
func suggestMeetingTimesIntelligent() async throws {
    var availability: [String: [TimeSlot]] = [:]

    // 1. Check Apple Calendar (current user)
    if AppleCalendarService.shared.isAuthorized {
        availability[currentUserID] = AppleCalendarService.shared.checkAvailability(...)
    }

    // 2. Check Google Calendar (if connected)
    for participant in participants {
        if participant.googleCalendarConnected {
            let slots = try await GoogleCalendarService.shared.checkAvailability(participant)
            availability[participant.id] = slots
        }
    }

    // 3. Check Outlook (if connected)
    for participant in participants {
        if participant.outlookCalendarConnected {
            let slots = try await OutlookCalendarService.shared.checkAvailability(participant)
            availability[participant.id] = slots
        }
    }

    // 4. For participants without calendar, use AI heuristics
    let participantsWithoutCalendar = participants.filter {
        availability[$0.id] == nil
    }

    // 5. Merge all availability + AI analysis
    let suggestions = try await mergeAvailabilityAndAI(
        availability: availability,
        aiAnalysis: existingAISuggestions
    )

    return suggestions
}
```

**This gives you**:
- ✅ Best possible accuracy (real calendar data)
- ✅ Graceful degradation (AI fallback)
- ✅ Works even if not everyone has calendar connected

---

## 📊 UI/UX Enhancements

### Meeting Suggestion with Calendar Data

```swift
struct MeetingSuggestionRow: View {
    let suggestion: TimeSlotData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.dateTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)

                Spacer()

                // Show availability badge
                availabilityBadge
            }

            // Show who's available
            HStack {
                ForEach(suggestion.available, id: \.self) { userID in
                    Image(systemName: "person.fill")
                        .foregroundStyle(.green)
                }

                if !suggestion.conflicts.isEmpty {
                    ForEach(suggestion.conflicts, id: \.self) { userID in
                        Image(systemName: "person.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            // Reasoning
            Text(suggestion.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    var availabilityBadge: some View {
        if suggestion.conflicts.isEmpty {
            Label("All free", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        } else {
            Label("\(suggestion.conflicts.count) conflicts", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}
```

---

## 💰 Cost Analysis

### API Quotas (Free Tier)

**Google Calendar API**:
- 1,000,000 queries/day
- 100 queries/user/day
- Free!

**Microsoft Graph API**:
- No explicit limit
- Rate limit: 2000 requests/minute
- Free!

**Apple EventKit**:
- Unlimited (local only)
- No API calls
- Free!

### For 1,000 Users:
Assuming 5 calendar checks per day:
- 5,000 API calls/day
- Well within free tier
- **Cost: $0/month**

---

## 🔐 Privacy Considerations

### What to Tell Users

**Privacy Policy Section**:
```
Calendar Access:
- We only check busy/free times
- We never read event titles or details
- We never modify your calendar
- Tokens stored securely (Keychain)
- You can disconnect anytime
```

**In-App Disclosure**:
```swift
.alert("Calendar Permission", isPresented: $showCalendarDisclosure) {
    Button("Allow") { requestCalendarAccess() }
    Button("Not Now", role: .cancel) { }
} message: {
    Text("Yaip needs calendar access to suggest meeting times when you're available. We only check if you're busy or free, never read event details.")
}
```

---

## 🚀 Quick Start: Apple Calendar (2 hours)

**Fastest way to get calendar integration working**:

### 1. Add EventKit Capability (5 mins)
```
Xcode → Target → Signing & Capabilities → + Capability → Calendars
```

### 2. Add Privacy Description (5 mins)
```xml
<!-- Info.plist -->
<key>NSCalendarsUsageDescription</key>
<string>Yaip needs calendar access to suggest meeting times when you're available.</string>
```

### 3. Create AppleCalendarService (30 mins)
See code above ↑

### 4. Update AIFeaturesViewModel (30 mins)
Integrate calendar checks with AI suggestions

### 5. Add Settings Toggle (15 mins)
```swift
Toggle("Use my calendar for suggestions", isOn: $useCalendar)
```

### 6. Test! (30 mins)
```
1. Build and run
2. Grant calendar permission
3. Create busy events in Apple Calendar
4. Ask AI for meeting suggestions
5. See suggestions avoid your busy times
6. 🎉 Working!
```

---

## 📈 Success Metrics

### Key Metrics:
- % users who connect calendar
- Accuracy of suggestions (busy vs free)
- Meeting acceptance rate
- Time saved scheduling

### Goals:
- 40%+ users connect calendar
- 95%+ accuracy for busy/free
- 2x meeting acceptance rate
- 5 minutes saved per scheduling

---

## 🎯 Final Recommendation

**Best path forward**:

1. **Week 1: Apple Calendar** (2-3 hours)
   - Immediate value for iOS users
   - No OAuth complexity
   - Test the concept

2. **Week 2: Google Calendar** (1 week)
   - Cover 60% of users
   - Enable multi-participant checking
   - N8N integration

3. **Week 3: Polish** (2-3 days)
   - Improve UI/UX
   - Add Outlook support
   - Optimize performance

**This gives you**:
- ✅ Real calendar integration
- ✅ Accurate meeting suggestions
- ✅ Competitive advantage
- ✅ Measurable ROI (time saved)

---

Your **Meeting Suggestions** AI feature would go from "interesting" to "indispensable" with calendar integration! 🚀
