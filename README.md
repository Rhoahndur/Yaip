# Yaip - AI-Powered Team Messaging

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017.0%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-6.0-orange" alt="Swift">
  <img src="https://img.shields.io/badge/Xcode-26.0-purple" alt="Xcode">
  <img src="https://img.shields.io/badge/CI-GitHub%20Actions-green" alt="CI">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

**Yaip** is a modern iOS team messaging app built with SwiftUI and Firebase. It combines real-time chat with AI features that summarize conversations, extract action items, detect priorities, and enable semantic search — all powered by N8N workflows and OpenAI.

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

### AI Features (N8N + OpenAI)
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
- Google Calendar and Outlook Calendar service stubs ready for expansion

### Authentication
- Email/password sign-up and sign-in
- Google Sign-In (via Firebase Auth)
- Profile management with photo upload

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
┌────────────────────────────────────────────────────────────────┐
│                       iOS App (SwiftUI)                        │
│                                                                │
│  Views ←→ ViewModels ←→ Protocols ←→ Services / Managers       │
│                                                                │
│  94 Swift source files │ 13 test files │ 9 protocols            │
└───────────────────────────┬────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ↓               ↓               ↓
     ┌──────────┐   ┌──────────────┐   ┌──────────┐
     │ Firebase  │   │ N8N Workflows│   │ SwiftData│
     │           │   │              │   │ (Local)  │
     │ • Auth    │   │ • OpenAI API │   └──────────┘
     │ • Firestore│  │ • AI Processing│
     │ • Storage │   │ • User Lookup│       ┌──────────┐
     │ • FCM     │   └──────────────┘       │ Pinecone │
     └──────────┘                           │ (Vector) │
                                            └──────────┘
```

### Key Design Decisions

**Optimistic Network Approach** — Messages are always sent regardless of local network status. Firebase SDK handles offline queuing and retry. `NetworkMonitor` is used for UI feedback only, never to block operations.

**Protocol-Based Dependency Injection** — All services and managers conform to protocols. ViewModels accept protocol-typed dependencies with `.shared` singleton defaults, enabling unit testing with mocks and zero call-site changes.

**Message Lifecycle** — Messages progress through: `.staged` → `.sending` → `.sent` → `.delivered` → `.read` (or `.failed` for retry). Local states are preserved during Firestore merge to prevent data loss.

**Listener Lifecycle** — Firestore listeners are managed via `ListenerBag`, a non-Sendable container that removes listeners in `deinit`, eliminating `nonisolated(unsafe)` usage.

---

## Project Structure

```
Yaip/Yaip/
├── YaipApp.swift                    # App entry, Firebase config, lifecycle
├── ContentView.swift                # Root navigation
├── Models/                          # Data models (3)
│   ├── Conversation.swift
│   ├── Message.swift
│   └── User.swift
├── Views/                           # SwiftUI views (41)
│   ├── AIFeatures/                  #   AI result sheets (7)
│   ├── Auth/                        #   Login, signup, welcome (4)
│   ├── Chat/                        #   Chat UI, bubbles, composer (13)
│   ├── Components/                  #   Reusable components (7)
│   ├── Conversations/               #   Conversation list (3)
│   ├── Settings/                    #   User & app settings (6)
│   └── Shared/                      #   Cross-feature views (1)
├── ViewModels/                      # Business logic (8)
│   ├── ChatViewModel.swift          #   Core chat coordinator
│   ├── ChatViewModel+Messaging.swift    #   Send, retry, merge, listen
│   ├── ChatViewModel+Interactions.swift #   Reactions, delete, reply
│   ├── ChatViewModel+Presence.swift     #   Typing indicators
│   ├── ConversationListViewModel.swift  #   Conversation CRUD
│   ├── AIFeaturesViewModel.swift        #   All 6 AI features
│   ├── PendingChatViewModel.swift       #   New chat flow
│   └── UserSearchViewModel.swift        #   User search
├── Services/                        # Firebase & backend (12)
│   ├── MessageService.swift
│   ├── ConversationService.swift
│   ├── UserService.swift
│   ├── StorageService.swift
│   ├── PresenceService.swift
│   ├── N8NService.swift             #   N8N webhook client
│   ├── MessageIndexingService.swift #   Pinecone vector indexing
│   ├── MessageListenerService.swift #   Background message listener
│   ├── AppleCalendarService.swift
│   ├── GoogleCalendarService.swift
│   ├── OutlookCalendarService.swift
│   └── CalendarProvider.swift
├── Managers/                        # Shared state (6)
│   ├── AuthManager.swift
│   ├── ImageUploadManager.swift     #   Three-state image lifecycle
│   ├── LocalStorageManager.swift    #   SwiftData persistence
│   ├── CalendarManager.swift
│   ├── LocalNotificationManager.swift
│   └── ThemeManager.swift
├── Protocols/                       # Service abstractions (9)
├── Extensions/                      # Swift extensions (5)
├── Utilities/                       # Cross-cutting concerns (8)
│   ├── AnalyticsService.swift       #   Firebase Analytics wrapper
│   ├── Logger.swift                 #   Structured os.log logging
│   ├── ListenerBag.swift            #   Firestore listener lifecycle
│   ├── NetworkMonitor.swift         #   NWPathMonitor (UI only)
│   ├── NetworkStateViewModifier.swift
│   ├── Strings.swift                #   L10n localization strings
│   ├── UserFacingError.swift        #   Typed error enum
│   └── Constants.swift
└── Assets.xcassets/
```

### Tests

```
Yaip/YaipTests/
├── Helpers/
│   └── TestFixtures.swift           # Factory methods for test data
├── Mocks/                           # 7 mock implementations
│   ├── MockMessageService.swift
│   ├── MockConversationService.swift
│   ├── MockAuthManager.swift
│   ├── MockLocalStorageManager.swift
│   ├── MockImageUploadManager.swift
│   ├── MockNetworkMonitor.swift
│   └── MockUserService.swift
├── MessageStatusTests.swift         # 14 tests — status state machine
├── MessageMergeTests.swift          # 6 tests — merge algorithm
├── ChatViewModelSendTests.swift     # 11 tests — send lifecycle
├── ChatViewModelInteractionTests.swift  # 10 tests — reactions, delete
└── ConversationListViewModelTests.swift # 5 tests — filtering, creation
```

---

## Setup

### Prerequisites
- **Xcode 26.0+** with iOS 17.0+ SDK
- **Firebase project** (Auth, Firestore, Storage)
- **N8N instance** (cloud or self-hosted) for AI features
- **OpenAI API key** for AI processing
- **Pinecone account** for RAG search (optional)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/yaip.git
   cd yaip
   ```

2. **Configure Firebase**
   - Create a project at [Firebase Console](https://console.firebase.google.com)
   - Add an iOS app with the bundle ID
   - Download `GoogleService-Info.plist` into `Yaip/Yaip/`
   - Enable Email/Password and Google Sign-In authentication
   - Create a Firestore database and enable Firebase Storage

3. **Deploy security rules**
   ```bash
   firebase deploy --only firestore:rules,storage
   ```

4. **Configure N8N** (for AI features)
   - Set up N8N workflows for AI endpoints (summarize, extract actions, search, etc.)
   - Copy `Config.xcconfig.template` to `Config.xcconfig`
   - Set `N8N_WEBHOOK_URL` and `N8N_AUTH_TOKEN`
   - Never commit `Config.xcconfig` to git

5. **Build and run**
   ```bash
   open Yaip/Yaip.xcodeproj
   # Select target → Cmd+R
   ```

### CI/CD

GitHub Actions runs on every push/PR to `main`:
- **Build** — `xcodebuild build` on macOS 15 with iPhone 16 simulator
- **Test** — `xcodebuild test` with all unit tests
- **Lint** — SwiftLint with project-specific rules (`.swiftlint.yml`)

---

## Firebase Collections

```
conversations/{conversationID}
  ├── type: "oneOnOne" | "group"
  ├── participants: [userID, ...]
  ├── name: String?
  ├── lastMessage: { text, senderID, timestamp }
  ├── unreadCount: { userID: Int, ... }
  ├── messages/{messageID}                  # Subcollection
  │     ├── text, senderID, timestamp, status
  │     ├── mediaURL?, mediaType?
  │     ├── readBy: [userID, ...]
  │     ├── reactions: { emoji: [userID, ...] }
  │     └── replyTo: messageID?
  └── presence/{userID}                     # Typing indicators (subcollection)
        ├── isTyping: Bool
        └── timestamp: Timestamp

users/{userID}
  ├── displayName, email, profileImageURL?
  ├── status: "online" | "away" | "offline"
  ├── lastSeen, lastHeartbeat: Timestamp
  └── fcmToken: String?
```

---

## Engineering Quality

| Area | Implementation |
|------|---------------|
| **Architecture** | MVVM + protocol-based DI, 9 service protocols |
| **Testing** | 46 unit tests across 5 suites, 7 mock implementations |
| **CI/CD** | GitHub Actions (build + test + lint) |
| **Code Quality** | SwiftLint with custom rules, structured `os.log` logging |
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
  CODE_SIGNING_ALLOWED=NO
```

### Manual Testing
1. Run on 2 simulators with different accounts
2. Test real-time messaging, reactions, replies, image sharing
3. Test offline mode (airplane mode → send → reconnect)
4. Test AI features on conversations with 20+ messages
5. Test group chat creation and participant management

---

## Dependencies

**Swift Package Manager:**
- Firebase iOS SDK — Auth, Firestore, Storage, Messaging, Analytics
- Google Sign-In for iOS

**Native Frameworks:**
- SwiftUI, SwiftData, EventKit, Network, os.log

**Node.js (backfill script only):**
- `firebase-admin` — Firestore access for Pinecone backfill
- `node-fetch` — HTTP client

---

## Known Limitations

- **Simulator network detection** — NWPathMonitor unreliable on simulator; Firebase SDK handles actual connectivity
- **Group typing indicators** — Only 1-on-1 chats show typing status
- **Message pagination** — Loads all messages (performant up to ~1000)
- **Google/Outlook calendar** — Service stubs exist but require OAuth setup
- **Push notifications** — Local notifications work; remote push requires APNs certificate setup

---

## Documentation

| Document | Description |
|----------|-------------|
| [`CLAUDE.md`](CLAUDE.md) | AI assistant guidelines and codebase reference |
| [`PRD.md`](PRD.md) | Product requirements (3100+ lines) |
| [`architecture.md`](architecture.md) | System architecture diagram |
| [`docs/`](docs/) | 24 guides organized by topic (features, setup, technical) |
| [`firestore.rules`](firestore.rules) | Firestore security rules |
| [`storage.rules`](storage.rules) | Firebase Storage security rules |

---

## Project Stats

| Metric | Count |
|--------|-------|
| Swift source files | 94 |
| Views | 41 |
| ViewModels | 8 |
| Services | 12 |
| Managers | 6 |
| Protocols | 9 |
| Unit tests | 46 |
| Test suites | 5 |
| Mock implementations | 7 |
| AI features | 6 |
| Firebase collections | 3 |

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
