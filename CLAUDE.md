# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Yaip** is an iOS messaging app built with SwiftUI and Firebase. It's a real-time chat application focused on reliable messaging with optimistic UI updates and offline support. The app uses Firebase for backend (Firestore, Storage, Auth) and SwiftData for local persistence.

**Bundle ID**: `Tavern.Yaip` (Debug), `yaip.tavern` (Release)

## Key Technical Decisions

### Network Strategy: Optimistic Approach
The app follows an **optimistic network approach** - it always attempts to send messages regardless of local network status checks. This is a deliberate design decision because:
- iOS Simulator's network detection (NWPathMonitor) is unreliable
- Firebase SDK has better connectivity detection than custom checks
- Firebase automatically queues operations when offline
- NetworkMonitor is only used for UI feedback, not blocking operations

**Critical**: Never add network checks that block sending messages or uploading images. Let Firebase SDK handle connectivity.

### Message Status Flow
Messages progress through these states:
1. `.staged` - Created locally, not yet sent
2. `.sending` - Being uploaded to Firebase
3. `.sent` - Successfully saved to Firestore
4. `.delivered` - Received by other users
5. `.read` - Viewed by other users
6. `.failed` - Send failed, needs retry

### Reconnection Architecture
The app handles offline/online transitions using:
- `NetworkMonitor` posts `.networkDidReconnect` notification
- `ChatViewModel` listens and calls `retryAllFailedMessages()`
- Messages in `.staged` status are automatically retried
- Images are cached locally via `ImageUploadManager` and uploaded on reconnection

## Project Structure

```
Yaip/Yaip/
├── YaipApp.swift           # App entry point, Firebase config, lifecycle
├── ContentView.swift       # Root view
├── Models/                 # Data models (Message, Conversation, User)
├── Views/                  # SwiftUI views
│   ├── Auth/              # Login, signup flows
│   └── Chat/              # Chat list, detail, messages
├── ViewModels/            # Business logic, state management
│   ├── ChatViewModel.swift          # Core messaging logic
│   ├── ConversationListViewModel.swift
│   └── UserSearchViewModel.swift
├── Services/              # Firebase interactions
│   ├── MessageService.swift         # Firestore message operations
│   ├── ConversationService.swift
│   └── PresenceService.swift
├── Managers/              # Shared managers
│   ├── AuthManager.swift            # Authentication state
│   ├── LocalStorageManager.swift    # SwiftData persistence
│   └── ImageUploadManager.swift     # Image caching/upload
├── Utilities/
│   ├── NetworkMonitor.swift         # Network status (UI only)
│   └── Constants.swift
└── Extensions/            # Swift extensions
```

## Common Development Commands

### Build & Run
```bash
# Open project
open Yaip/Yaip.xcodeproj

# Build from command line
xcodebuild -project Yaip/Yaip.xcodeproj -scheme Yaip -configuration Debug

# Run tests
xcodebuild test -project Yaip/Yaip.xcodeproj -scheme Yaip -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Network Testing
```bash
# Simulate poor network conditions (requires Network Link Conditioner)
./simulator-network.sh

# Watch logs and rebuild on changes
./watch-and-build.sh

# Simple file watcher
./watch-simple.sh
```

### Git Workflow
The repository follows a standard Git workflow. Modified files currently include:
- `Yaip/Yaip/Managers/ImageUploadManager.swift`
- `Yaip/Yaip/Utilities/NetworkMonitor.swift`
- `Yaip/Yaip/ViewModels/ChatViewModel.swift`

Recent commits focus on fixing reconnection issues and implementing optimistic network approach.

## Critical Code Patterns

### Sending Messages (ChatViewModel)
```swift
// ALWAYS attempt to send, even if NetworkMonitor says offline
if !networkMonitor.isConnected {
    print("⚠️ NetworkMonitor thinks we're offline, but trying anyway...")
}
try await messageService.sendMessage(newMessage)
```

**Never do this**:
```swift
// ❌ WRONG - Don't block on network status
if !networkMonitor.isConnected {
    return  // This breaks the optimistic approach!
}
```

### Image Upload Pattern (ImageUploadManager)
Images follow a three-state system:
- `.notStarted` - Image not yet cached
- `.cached(UIImage)` - Image cached locally, ready to upload
- `.uploaded(String)` - Uploaded to Firebase Storage, URL available

Always cache images before attempting upload. On reconnection, check cache and upload if in `.cached` state.

### Offline Message Queueing
When sending messages offline:
1. Create message with `.staged` status
2. Add to UI immediately (optimistic)
3. Save to SwiftData via `LocalStorageManager`
4. Attempt Firebase send (will auto-queue if offline)
5. On reconnect, retry via `retryAllFailedMessages()`

### Real-time Listeners
Firestore listeners use `includeMetadataChanges: true` to catch pending writes:
```swift
.addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
    // Handle updates including local pending writes
}
```

Always remove listeners in `deinit` to prevent memory leaks.

## Firebase Collections Structure

```
conversations/{conversationID}
  - type: "oneOnOne" | "group"
  - participants: [userID1, userID2, ...]
  - name: String (optional, for groups)
  - lastMessage: { text, senderID, timestamp }
  - updatedAt: Timestamp

  messages/{messageID}
    - conversationID: String
    - senderID: String
    - text: String (optional)
    - mediaURL: String (optional)
    - timestamp: Timestamp
    - status: "staged" | "sending" | "sent" | "delivered" | "read"
    - readBy: [userID1, userID2, ...]

  presence/{userID}
    - isTyping: Bool
    - timestamp: Timestamp

users/{userID}
  - displayName: String
  - email: String
  - profileImageURL: String (optional)
  - status: "online" | "away" | "offline"
  - lastSeen: Timestamp
  - fcmToken: String (optional)
```

## Known Issues & Workarounds

### Simulator Network Detection
NWPathMonitor reports incorrect network status in iOS Simulator. The app works around this by:
- Always attempting operations regardless of network status
- Using Firebase SDK's internal connectivity detection
- NetworkMonitor only updates UI, doesn't block operations

See `OPTIMISTIC_NETWORK_APPROACH.md` for full explanation.

### Read Receipts in Group Chats
Status transitions to `.read` only when ALL non-sender participants have read the message. In 1-on-1 chats, status changes to `.read` as soon as the recipient reads it.

Logic is in `MessageService.markMessagesAsRead()` starting at line 74.

### Image Upload Retry
Images are cached to disk before upload attempts. On reconnection, `ChatViewModel.retryAllFailedMessages()` checks `ImageUploadManager` state and resumes uploads for messages in `.cached` state.

## Testing Strategy

### Essential Test Scenarios
1. **Offline Text Message**: Send while offline, reconnect, verify sync
2. **Offline Image Message**: Send image offline, reconnect, verify upload + sync
3. **Multiple Offline Messages**: Send several messages offline, verify order preserved on sync
4. **Group Chat**: Test message delivery to all participants
5. **Read Receipts**: Verify status changes in 1-on-1 and group chats
6. **App Background**: Send while app in background, verify notification

### Debugging Network Issues
Enable verbose logging by checking console for:
- `🎉 CONNECTION RESTORED` - NetworkMonitor detected reconnection
- `🔄 Network reconnected - immediately retrying` - Retry triggered
- `📋 Found staged message` - Messages found to retry
- `⚠️ NetworkMonitor thinks we're offline, but trying anyway` - Optimistic send

See `RECONNECTION_FIX_SUMMARY.md` and `RECONNECTION_TEST_GUIDE.md` for detailed test procedures.

## Architecture Philosophy

### MVVM with Services
- **Views**: SwiftUI, purely presentational
- **ViewModels**: Business logic, state management, published properties
- **Services**: Firebase operations, no UI knowledge
- **Managers**: Shared functionality (auth, storage, networking)

### Optimistic UI
Show immediate feedback, then sync in background. Users see instant updates even when offline. Firebase handles eventual consistency.

### Firebase-First
Trust Firebase SDK for:
- Offline persistence (automatic)
- Retry logic (automatic)
- Network detection (more reliable than custom checks)

Only implement custom logic when Firebase doesn't provide it (e.g., image caching).

## Important Constants

```swift
// Firestore collections
Constants.Collections.conversations = "conversations"
Constants.Collections.messages = "messages"
Constants.Collections.users = "users"

// Notification names
Notification.Name.networkDidReconnect
Notification.Name.networkDidDisconnect
```

## Documentation References

Key documentation files:
- `PRD.md` - Original product requirements (3100+ lines)
- `architecture.md` - System architecture diagram
- `RECONNECTION_FIX_SUMMARY.md` - Offline reconnection fix details
- `OPTIMISTIC_NETWORK_APPROACH.md` - Network strategy explanation
- `RECONNECTION_TEST_GUIDE.md` - Testing procedures
- `firestore.rules` - Firestore security rules
- `storage.rules` - Firebase Storage security rules

## Dependencies

Firebase iOS SDK (via Swift Package Manager):
- FirebaseAuth
- FirebaseFirestore
- FirebaseStorage
- FirebaseMessaging (for push notifications)

SwiftData (native) for local persistence.

## Common Pitfalls

1. **Don't add network checks that block operations** - Trust Firebase SDK
2. **Don't forget to remove Firestore listeners** - Memory leaks in ViewModels
3. **Don't modify message status outside MessageService** - Centralized status management
4. **Don't skip caching images** - Required for offline upload retry
5. **Don't use device timestamps for message ordering** - Use server timestamps

## Xcode Configuration

- Minimum iOS version: iOS 17.0+
- Swift version: 6.0
- Xcode version: 26.0.1
- Signing: Automatic
- Capabilities required: Push Notifications, Background Modes (Remote notifications)

The project includes entitlements files for both Debug (`Yaip.entitlements`) and Release (`YaipRelease.entitlements`) configurations.
