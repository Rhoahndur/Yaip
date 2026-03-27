# Yaip - AI-Powered Team Messaging

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017.0%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-6.0-orange" alt="Swift">
  <img src="https://img.shields.io/badge/Xcode-26.0-purple" alt="Xcode">
  <img src="https://img.shields.io/badge/CI-GitHub%20Actions-green" alt="CI">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

**Yaip** is a modern iOS team messaging app built with SwiftUI and Firebase. It combines real-time chat with AI features that summarize conversations, extract action items, detect priorities, and enable semantic search — all powered by N8N workflows and OpenRouter (free-tier models via OpenAI-compatible API).

---

## Features

### Core Messaging
- **Real-time chat** with Firestore snapshot listeners (<500ms delivery)
- **1-on-1 and group conversations** with participant management
- **Offline-first architecture** — messages queue locally (SwiftData) and sync on reconnect
- **Image sharing** with automatic compression and offline upload retry
- **Message reactions** (8 emoji), **replies**, and **soft delete**
- **Read receipts** — per-user tracking, group-aware status transitions
- **Typing indicators** for 1-on-1 chats
- **Online presence** — online, away, offline with real-time listeners

### AI Features (N8N + OpenRouter)
| Feature | Description |
|---------|-------------|
| **Thread Summarization** | AI-generated summaries with key points, decisions, and tone |
| **Action Items** | Auto-extract tasks with assignees, deadlines, and priorities |
| **Smart Search** | Semantic search via Pinecone RAG with AI-synthesized answers |
| **Priority Detection** | Score messages 0-10 for urgency, highlight critical items |
| **Decision Tracking** | Extract decisions with reasoning and impact assessment |
| **Meeting Suggestions** | Suggest meeting times with calendar availability checks |

### Calendar Integration
- Apple Calendar (EventKit) — create events from meeting suggestions
- Google Calendar service stub ready for OAuth expansion

### Authentication
- Email/password sign-up and sign-in
- Google Sign-In (via Firebase Auth)
- Profile setup after registration with photo upload

### User Experience
- Dark/light/system theme support (ThemeManager)
- Haptic feedback on interactions
- Network status banner with auto-reconnect
- In-app notification banners with deep-linking to specific messages
- Error toasts with retry actions

---

## Architecture

### MVVM + Services + Protocols

```
+-----------------------------------------------------------------+
|                       iOS App (SwiftUI)                         |
|                                                                 |
|  Views <-> ViewModels <-> Protocols <-> Services / Managers     |
|                                                                 |
|  97 Swift source files | 8 test suites (103 tests) | 12 mocks  |
+-----------------------------------------------------------------+
                            |
            +---------------+---------------+
            v               v               v
     +----------+   +--------------+   +----------+
     | Firebase  |   | N8N Workflows|   | SwiftData|
     |           |   |              |   | (Local)  |
     | - Auth    |   | - OpenRouter |   +----------+
     | - Firestore|  | - AI Process |
     | - Storage |   | - User Lookup|       +----------+
     | - FCM     |   +--------------+       | Pinecone |
     +----------+                           | (Vector) |
                                            +----------+
```

### Key Design Decisions

**Optimistic Network Approach** — Messages are always sent regardless of local network status. Firebase SDK handles offline queuing and retry. `NetworkMonitor` is used for UI feedback only, never to block operations.

**Protocol-Based Dependency Injection** — All services and managers conform to protocols (12 protocols across 11 files). ViewModels accept protocol-typed dependencies with `.shared` singleton defaults, enabling unit testing with mocks and zero call-site changes.

**Message Lifecycle** — Messages progress through: `.staged` -> `.sending` -> `.sent` -> `.delivered` -> `.read` (or `.failed` for retry). Local states are preserved during Firestore merge to prevent data loss.

**Listener Lifecycle** — Firestore listeners are managed via `ListenerBag`, a non-Sendable container that removes listeners in `deinit`, eliminating `nonisolated(unsafe)` usage.

---

## Project Structure

```
Yaip/Yaip/
+-- YaipApp.swift                    # App entry, Firebase config, lifecycle
+-- ContentView.swift                # Root navigation
+-- Models/                          # Data models (3)
|   +-- Conversation.swift
|   +-- Message.swift
|   +-- User.swift
+-- Views/                           # SwiftUI views (43)
|   +-- AIFeatures/                  #   AI result sheets (7)
|   +-- Auth/                        #   Login, signup, welcome, profile setup (4)
|   +-- Chat/                        #   Chat UI, bubbles, composer (13)
|   +-- Components/                  #   Reusable components (8)
|   +-- Conversations/               #   Conversation list (3)
|   +-- Settings/                    #   User & app settings (7)
|   +-- Shared/                      #   Cross-feature views (1)
+-- ViewModels/                      # Business logic (8 files, 5 VMs)
|   +-- ChatViewModel.swift              # Core chat coordinator
|   +-- ChatViewModel+Messaging.swift    # Send, retry, merge, listen
|   +-- ChatViewModel+Interactions.swift # Reactions, delete, reply
|   +-- ChatViewModel+Presence.swift     # Typing indicators
|   +-- ConversationListViewModel.swift  # Conversation CRUD
|   +-- AIFeaturesViewModel.swift        # All 6 AI features
|   +-- PendingChatViewModel.swift       # New chat flow
|   +-- UserSearchViewModel.swift        # User search
+-- Services/                        # Firebase & backend (11)
|   +-- MessageService.swift
|   +-- ConversationService.swift
|   +-- UserService.swift
|   +-- StorageService.swift
|   +-- PresenceService.swift
|   +-- N8NService.swift                 # N8N webhook client
|   +-- MessageIndexingService.swift     # Pinecone vector indexing
|   +-- MessageListenerService.swift     # Background message listener
|   +-- AppleCalendarService.swift
|   +-- GoogleCalendarService.swift
|   +-- CalendarProvider.swift
+-- Managers/                        # Shared state (6)
|   +-- AuthManager.swift
|   +-- ImageUploadManager.swift         # Three-state image lifecycle
|   +-- LocalStorageManager.swift        # SwiftData persistence
|   +-- CalendarManager.swift
|   +-- LocalNotificationManager.swift
|   +-- ThemeManager.swift
+-- Protocols/                       # Service abstractions (11 files, 12 protocols)
+-- Extensions/                      # Swift extensions (5)
+-- Utilities/                       # Cross-cutting concerns (8)
|   +-- AnalyticsService.swift           # Firebase Analytics wrapper
|   +-- Logger.swift                     # Structured os.log logging
|   +-- ListenerBag.swift                # Firestore listener lifecycle
|   +-- NetworkMonitor.swift             # NWPathMonitor (UI only)
|   +-- NetworkStateViewModifier.swift
|   +-- Strings.swift                    # L10n localization strings
|   +-- UserFacingError.swift            # Typed error enum
|   +-- Constants.swift
+-- Assets.xcassets/
```

### Tests

```
Yaip/YaipTests/                          # 21 files, 103 test methods
+-- Helpers/
|   +-- TestFixtures.swift               # Factory methods for all model types
+-- Mocks/                               # 12 mock implementations
|   +-- MockAuthManager.swift
|   +-- MockCalendarManager.swift
|   +-- MockConversationService.swift
|   +-- MockEventCreator.swift
|   +-- MockImageUploadManager.swift
|   +-- MockLocalStorageManager.swift
|   +-- MockMessageService.swift
|   +-- MockN8NService.swift
|   +-- MockNetworkMonitor.swift
|   +-- MockPresenceService.swift
|   +-- MockStorageService.swift
|   +-- MockUserService.swift
+-- AIFeaturesViewModelTests.swift       # 26 tests - AI features, search, calendar
+-- ChatViewModelInteractionTests.swift  # 10 tests - reactions, delete, reply
+-- ChatViewModelSendTests.swift         # 12 tests - send lifecycle, retry
+-- ConversationListViewModelTests.swift #  6 tests - filtering, creation
+-- MessageMergeTests.swift              #  6 tests - merge algorithm
+-- MessageStatusTests.swift             # 18 tests - status state machine
+-- PendingChatViewModelTests.swift      # 15 tests - new conversation flow
+-- UserSearchViewModelTests.swift       # 10 tests - search, filtering
```

---

## Setup

### Prerequisites
- **Xcode 26.0+** with iOS 17.0+ SDK
- **Firebase project** (Auth, Firestore, Storage, Realtime Database)
- **N8N instance** (cloud or self-hosted) for AI features
- **OpenRouter API key** for AI processing (free-tier models; OpenAI-compatible API)
- **Pinecone account** for RAG search (optional)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/rhoahndur/yaip.git
   cd yaip
   ```

2. **Configure Firebase**
   - Create a project at [Firebase Console](https://console.firebase.google.com)
   - Add an iOS app with bundle ID `Tavern.Yaip`
   - Download `GoogleService-Info.plist` into `Yaip/Yaip/`
   - Enable Email/Password and Google Sign-In authentication
   - Create a Firestore database, enable Firebase Storage, and enable Realtime Database

3. **Deploy security rules**
   ```bash
   firebase deploy --only firestore:rules,storage
   ```

4. **Configure N8N** (for AI features)
   - Set up N8N workflows for AI endpoints (summarize, extract actions, search, etc.)
   - Copy `Config.xcconfig.template` to `Yaip/Config.xcconfig`
   - Set `N8N_WEBHOOK_URL`, `N8N_AUTH_TOKEN`, `GOOGLE_CLIENT_ID`, and `GOOGLE_REVERSED_CLIENT_ID`
   - Never commit `Config.xcconfig` to git

5. **Build and run**
   ```bash
   open Yaip/Yaip.xcodeproj
   # Select target -> Cmd+R
   ```

### CI/CD

GitHub Actions (`.github/workflows/ci.yml`) runs on every push/PR to `main`:
- **Build** — `xcodebuild build` on macOS 15 with iPhone 16 simulator
- **Test** — `xcodebuild test` with code coverage enabled
- **Lint** — SwiftLint with project-specific rules (`.swiftlint.yml`)

SPM dependencies are cached between runs via `actions/cache@v4`.

---

## Firebase Collections

```
conversations/{conversationID}
  +-- type: "oneOnOne" | "group"
  +-- participants: [userID, ...]
  +-- name: String?
  +-- imageURL: String?
  +-- lastMessage: { text, senderID, timestamp }
  +-- unreadCount: { userID: Int, ... }
  +-- createdAt, updatedAt: Timestamp
  +-- messages/{messageID}                  # Subcollection
  |     +-- text, senderID, timestamp, status
  |     +-- mediaURL?, mediaType?
  |     +-- readBy: [userID, ...]
  |     +-- reactions: { emoji: [userID, ...] }
  |     +-- replyTo: messageID?
  |     +-- isDeleted: Bool, deletedAt: Timestamp?
  +-- presence/{userID}                     # Typing indicators (subcollection)
        +-- isTyping: Bool
        +-- timestamp: Timestamp

users/{userID}
  +-- displayName, email, profileImageURL?
  +-- status: "online" | "away" | "offline"
  +-- lastSeen, lastHeartbeat: Timestamp
  +-- fcmToken: String?

Firebase Realtime Database:
  presence/{userID}                         # Auto-disconnect detection
    +-- status: "online" | "offline"
    +-- lastSeen: ServerTimestamp

Firebase Storage:
  chat_images/{conversationID}/{uuid}.jpg
  profile_images/{userID}/{uuid}.jpg
```

---

## Engineering Quality

| Area | Implementation |
|------|---------------|
| **Architecture** | MVVM + protocol-based DI, 12 service/manager protocols |
| **Testing** | 103 unit tests across 8 suites, 12 mock implementations |
| **CI/CD** | GitHub Actions (build + test + lint), SPM caching |
| **Code Quality** | SwiftLint with custom rules, pre-commit hook, structured `os.log` logging |
| **Analytics** | Firebase Analytics with typed events (`AnalyticsService`) |
| **Localization** | `L10n` enum with `String(localized:defaultValue:)`, translation-ready |
| **Accessibility** | Labels, hints, and identifiers on interactive elements |
| **Error Handling** | `UserFacingError` enum with `ErrorToast` view modifier |
| **Concurrency** | `@MainActor` isolation, `ListenerBag` for safe listener cleanup |
| **Offline** | SwiftData persistence, optimistic UI, auto-retry on reconnect |

---

## Testing

### Unit Tests
```bash
xcodebuild test \
  -project Yaip/Yaip.xcodeproj \
  -scheme Yaip \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO \
  -enableCodeCoverage YES
```

### Test Suites

| Suite | Tests | Coverage |
|-------|-------|----------|
| `MessageStatusTests` | 18 | Status enum properties and transitions |
| `AIFeaturesViewModelTests` | 26 | All 6 AI features, search (basic+RAG), calendar event creation |
| `PendingChatViewModelTests` | 15 | Conversation creation, message send, image upload, errors |
| `ChatViewModelSendTests` | 12 | Message send lifecycle, retry, staged/failed flow |
| `ChatViewModelInteractionTests` | 10 | Reactions, soft delete, replies |
| `UserSearchViewModelTests` | 10 | Search, fetchAll, current user filtering |
| `MessageMergeTests` | 6 | Merge algorithm (local state preservation, dedup) |
| `ConversationListViewModelTests` | 6 | Filtering, unread toggle, self-chat exclusion |

### Manual Testing
1. Run on 2 simulators with different accounts
2. Test real-time messaging, reactions, replies, image sharing
3. Test offline mode (airplane mode -> send -> reconnect)
4. Test AI features on conversations with 20+ messages
5. Test group chat creation and participant management

---

## Dependencies

**Swift Package Manager:**
- Firebase iOS SDK — Auth, Firestore, Storage, Realtime Database, Messaging, Analytics
- Google Sign-In for iOS

**Native Frameworks:**
- SwiftUI, SwiftData, EventKit, Network, os.log, Combine, UserNotifications

**External Services:**
- N8N (webhooks for AI processing)
- OpenRouter (LLM API, OpenAI-compatible)
- Pinecone (vector database for RAG search)

**Node.js (backfill script only):**
- `firebase-admin` — Firestore access for Pinecone backfill
- `node-fetch` — HTTP client

---

## Known Limitations

- **Simulator network detection** — NWPathMonitor unreliable on simulator; Firebase SDK handles actual connectivity
- **Group typing indicators** — Only 1-on-1 chats show typing status
- **Message pagination** — Loads all messages (performant up to ~1000)
- **Google Calendar** — Service stub exists but requires OAuth setup
- **Push notifications** — Local notifications work; remote push requires APNs certificate setup

---

## Documentation

| Document | Description |
|----------|-------------|
| [`CLAUDE.md`](CLAUDE.md) | AI assistant guidelines and codebase reference |
| [`architecture.md`](architecture.md) | System architecture and data flows |
| [`PRD.md`](PRD.md) | Product requirements (3100+ lines) |
| [`FOLLOWUP_PLAN.md`](FOLLOWUP_PLAN.md) | Codebase health plan and progress tracking |
| [`docs/`](docs/) | 29 guides organized by topic |
| [`docs/FEATURES/`](docs/FEATURES/) | 9 feature guides (presence, notifications, group chat, etc.) |
| [`docs/SETUP/`](docs/SETUP/) | 6 setup guides (Firebase rules, multi-simulator, deployment) |
| [`docs/TECHNICAL/`](docs/TECHNICAL/) | 11 technical docs (build status, offline handling, etc.) |
| [`firestore.rules`](firestore.rules) | Firestore security rules |
| [`storage.rules`](storage.rules) | Firebase Storage security rules |

---

## Project Stats

| Metric | Count |
|--------|-------|
| Swift source files | 97 |
| Views | 43 |
| ViewModels | 5 (8 files) |
| Services | 11 |
| Managers | 6 |
| Protocols | 12 |
| Unit tests | 103 |
| Test suites | 8 |
| Mock implementations | 12 |
| AI features | 6 |
| Firebase collections | 3 |
| Documentation files | 29 |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes
4. Push to branch and open a Pull Request

CI will automatically build, test, and lint your changes.

---

## License

This project is licensed under the MIT License.

---

<p align="center">
  Built with SwiftUI, Firebase, and AI
</p>

<p align="center">
  <strong>Yaip</strong> — Making team communication smarter, not louder.
</p>
