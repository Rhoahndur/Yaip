# MessageAI - Development Task Checklist
## Project File Structure & PR Breakdown

---

## 📁 Project File Structure

```
MessageAI/
├── MessageAI.xcodeproj
├── MessageAI/
│   ├── MessageAIApp.swift                    # App entry point
│   ├── ContentView.swift                     # Root view with tab navigation
│   │
│   ├── Models/
│   │   ├── User.swift                        # User data model
│   │   ├── Conversation.swift                # Conversation data model
│   │   ├── Message.swift                     # Message data model
│   │   ├── ActionItem.swift                  # AI action item model
│   │   ├── Decision.swift                    # AI decision model
│   │   └── AIFeature.swift                   # AI feature cache model
│   │
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift               # Authentication logic
│   │   ├── ConversationListViewModel.swift   # Chat list logic
│   │   ├── ChatViewModel.swift               # Individual chat logic
│   │   ├── UserSearchViewModel.swift         # User search logic
│   │   ├── AIFeaturesViewModel.swift         # AI features orchestration
│   │   ├── ActionItemsViewModel.swift        # Action items management
│   │   ├── DecisionsViewModel.swift          # Decisions tracking
│   │   └── SearchViewModel.swift             # Smart search logic
│   │
│   ├── Views/
│   │   ├── Auth/
│   │   │   ├── WelcomeView.swift
│   │   │   ├── LoginView.swift
│   │   │   ├── SignUpView.swift
│   │   │   └── ProfileSetupView.swift
│   │   │
│   │   ├── Conversations/
│   │   │   ├── ConversationListView.swift
│   │   │   ├── ConversationRow.swift
│   │   │   ├── NewChatView.swift
│   │   │   └── UserSearchRow.swift
│   │   │
│   │   ├── Chat/
│   │   │   ├── ChatView.swift
│   │   │   ├── MessageBubble.swift
│   │   │   ├── GroupMessageBubble.swift
│   │   │   ├── MediaMessageBubble.swift
│   │   │   ├── MessageComposer.swift
│   │   │   ├── TypingIndicator.swift
│   │   │   └── ChatDetailView.swift
│   │   │
│   │   ├── AIFeatures/
│   │   │   ├── SummaryView.swift
│   │   │   ├── ActionItemsView.swift
│   │   │   ├── ActionItemRow.swift
│   │   │   ├── DecisionsView.swift
│   │   │   ├── DecisionCard.swift
│   │   │   ├── SearchView.swift
│   │   │   ├── SearchResultRow.swift
│   │   │   ├── PriorityInboxView.swift
│   │   │   ├── PriorityMessageRow.swift
│   │   │   └── AssistantMessageBubble.swift
│   │   │
│   │   └── Components/
│   │       ├── ImagePickerButton.swift
│   │       ├── LoadingView.swift
│   │       └── ErrorView.swift
│   │
│   ├── Managers/
│   │   ├── FirebaseManager.swift             # Firebase singleton
│   │   ├── AuthManager.swift                 # Auth state management
│   │   ├── PresenceManager.swift             # User online/offline status
│   │   ├── NotificationManager.swift         # Push notifications
│   │   ├── MediaManager.swift                # Image/video upload
│   │   └── LocalStorageManager.swift         # SwiftData persistence
│   │
│   ├── Services/
│   │   ├── MessageService.swift              # Message CRUD operations
│   │   ├── ConversationService.swift         # Conversation CRUD
│   │   ├── AIService.swift                   # Cloud Functions calls
│   │   └── SearchService.swift               # Search operations
│   │
│   ├── Extensions/
│   │   ├── Date+Extensions.swift             # Date formatting helpers
│   │   ├── String+Extensions.swift           # String utilities
│   │   ├── Color+Extensions.swift            # Custom colors
│   │   └── UIImage+Extensions.swift          # Image compression
│   │
│   ├── Utilities/
│   │   ├── Constants.swift                   # App constants
│   │   ├── FirestoreCollections.swift        # Collection names
│   │   └── NetworkMonitor.swift              # Network status
│   │
│   └── Assets.xcassets/                      # Images, colors, icons
│
├── GoogleService-Info.plist                  # Firebase config
├── Info.plist                                # App permissions
│
└── MessageAI-CloudFunctions/                 # Firebase Cloud Functions
    ├── package.json
    ├── .gitignore
    ├── functions/
    │   ├── index.js                          # Function exports
    │   ├── src/
    │   │   ├── ai/
    │   │   │   ├── summarization.js          # Thread summary
    │   │   │   ├── actionItems.js            # Action item extraction
    │   │   │   ├── decisions.js              # Decision tracking
    │   │   │   ├── priority.js               # Priority detection
    │   │   │   └── proactiveAssistant.js     # Scheduling assistant
    │   │   │
    │   │   ├── messaging/
    │   │   │   ├── sendNotification.js       # FCM notifications
    │   │   │   └── messageHandlers.js        # Message triggers
    │   │   │
    │   │   └── utils/
    │   │       ├── anthropic.js              # Claude API wrapper
    │   │       ├── pinecone.js               # Vector DB client
    │   │       ├── cache.js                  # Response caching
    │   │       └── rateLimit.js              # Rate limiting
    │   │
    │   └── config/
    │       └── firestore.rules               # Security rules
    │
    └── firestore.indexes.json                # Firestore indexes
```

---

## 🚀 PR Breakdown & Task Checklist

---

## **PR #1: Project Setup & Firebase Configuration**
**Branch:** `setup/project-init`  
**Goal:** Initialize Xcode project, add Firebase, configure basic structure  
**Estimated Time:** 2 hours

### Tasks:
- [ ] **1.1 Create Xcode Project**
  - Files: `MessageAI.xcodeproj`, `MessageAIApp.swift`, `ContentView.swift`
  - Create new iOS App project in Xcode
  - Set bundle ID: `com.yourname.MessageAI`
  - Set minimum iOS version: 17.0
  - Enable SwiftUI lifecycle

- [ ] **1.2 Create Firebase Project**
  - Go to Firebase Console
  - Create new project "MessageAI"
  - Enable Google Analytics (optional)
  - Add iOS app with bundle ID
  - Download `GoogleService-Info.plist`

- [ ] **1.3 Add Firebase SDK**
  - Files: `MessageAI.xcodeproj/project.pbxproj` (SPM)
  - Xcode → File → Add Package Dependencies
  - Add Firebase iOS SDK: `https://github.com/firebase/firebase-ios-sdk`
  - Select packages: FirebaseAuth, FirebaseFirestore, FirebaseStorage, FirebaseMessaging, FirebaseFunctions

- [ ] **1.4 Configure Firebase in App**
  - Files: `MessageAIApp.swift`, `GoogleService-Info.plist`
  - Add `GoogleService-Info.plist` to project root
  - Import Firebase in `MessageAIApp.swift`
  - Add `FirebaseApp.configure()` in init

- [ ] **1.5 Create Folder Structure**
  - Create all folders: Models/, ViewModels/, Views/, Managers/, Services/, Extensions/, Utilities/
  - Create empty `.swift` files as placeholders

- [ ] **1.6 Setup .gitignore**
  - Files: `.gitignore`
  - Add: `GoogleService-Info.plist`, `*.xcuserstate`, `.DS_Store`, `Pods/`

- [ ] **1.7 Enable Capabilities**
  - Files: Project settings
  - Enable: Push Notifications, Background Modes (Remote notifications, Background fetch)

**PR Checklist Before Merge:**
- [ ] Project builds without errors
- [ ] Firebase initializes successfully
- [ ] .gitignore excludes sensitive files
- [ ] All folder structure created

---

## **PR #2: Data Models & Firebase Schema**
**Branch:** `feature/data-models`  
**Goal:** Define all data models and Firestore structure  
**Estimated Time:** 2 hours

### Tasks:
- [ ] **2.1 Create User Model**
  - Files: `Models/User.swift`
  - Define `User` struct with Codable, Identifiable
  - Properties: id, displayName, email, profileImageURL, status, lastSeen, createdAt
  - Add `UserStatus` enum

- [ ] **2.2 Create Conversation Model**
  - Files: `Models/Conversation.swift`
  - Define `Conversation` struct with Codable, Identifiable
  - Properties: id, type, participants, participantDetails, name, imageURL, lastMessage, createdAt, updatedAt, unreadCount
  - Add `ConversationType` enum
  - Add `LastMessage` struct

- [ ] **2.3 Create Message Model**
  - Files: `Models/Message.swift`
  - Define `Message` struct with Codable, Identifiable
  - Properties: id, conversationID, senderID, text, mediaURL, mediaType, timestamp, status, readBy, replyTo, reactions, isEdited, isDeleted
  - Add `MessageStatus` enum
  - Add `MediaType` enum

- [ ] **2.4 Create AI Feature Models**
  - Files: `Models/ActionItem.swift`, `Models/Decision.swift`, `Models/AIFeature.swift`
  - Define `ActionItem` struct with task, assignee, deadline, status, messageID, context
  - Define `Decision` struct with decision, reasoning, alternatives, participants, timestamp
  - Define `AIFeature` for cache storage

- [ ] **2.5 Create Constants File**
  - Files: `Utilities/Constants.swift`
  - Define Firebase collection names
  - Define app-wide constants (page sizes, limits, etc.)

- [ ] **2.6 Create Firestore Collections Helper**
  - Files: `Utilities/FirestoreCollections.swift`
  - Enum with collection paths as static strings

**PR Checklist Before Merge:**
- [ ] All models compile without errors
- [ ] Models conform to Codable and Identifiable
- [ ] Enums have proper raw values
- [ ] No TODO comments left

---

## **PR #3: Authentication System**
**Branch:** `feature/authentication`  
**Goal:** Complete user authentication flow  
**Estimated Time:** 4 hours

### Tasks:
- [ ] **3.1 Create AuthManager**
  - Files: `Managers/AuthManager.swift`
  - Create singleton with `@Published var user: User?`
  - Add `@Published var isAuthenticated: Bool`
  - Implement `signUp(email:password:displayName:)` async
  - Implement `signIn(email:password:)` async
  - Implement `signOut()` async
  - Implement `resetPassword(email:)` async
  - Add auth state listener in init

- [ ] **3.2 Create AuthViewModel**
  - Files: `ViewModels/AuthViewModel.swift`
  - Create `@ObservableObject` class
  - Add `@Published` properties for email, password, displayName, error
  - Add loading states
  - Implement form validation methods
  - Call AuthManager methods

- [ ] **3.3 Create WelcomeView**
  - Files: `Views/Auth/WelcomeView.swift`
  - Design welcome screen UI
  - Add "Sign Up" and "Log In" buttons
  - Add app logo/branding

- [ ] **3.4 Create SignUpView**
  - Files: `Views/Auth/SignUpView.swift`
  - Email text field with validation
  - Password secure field with show/hide toggle
  - Display name text field
  - "Create Account" button
  - Error message display
  - Loading indicator

- [ ] **3.5 Create LoginView**
  - Files: `Views/Auth/LoginView.swift`
  - Email and password fields
  - "Log In" button
  - "Forgot Password?" link
  - Error message display
  - Loading indicator

- [ ] **3.6 Create ProfileSetupView**
  - Files: `Views/Auth/ProfileSetupView.swift`
  - Display name editor
  - Profile photo uploader (optional for MVP)
  - "Get Started" button
  - Save to Firestore users collection

- [ ] **3.7 Update ContentView**
  - Files: `ContentView.swift`
  - Add `@StateObject var authManager = AuthManager.shared`
  - Conditional rendering: show auth views if not authenticated, else main app

- [ ] **3.8 Add Firestore User Creation**
  - Files: `Managers/AuthManager.swift`
  - After Firebase Auth signup, create user document in Firestore
  - Save to `users/{userID}` collection

**PR Checklist Before Merge:**
- [ ] Can create new account
- [ ] Can log in with existing account
- [ ] Can log out
- [ ] User persists to Firestore
- [ ] Session persists on app restart
- [ ] Error messages display correctly

---

## **PR #4: Conversation List & Real-Time Sync**
**Branch:** `feature/conversation-list`  
**Goal:** Display list of conversations with real-time updates  
**Estimated Time:** 4 hours

### Tasks:
- [ ] **4.1 Create FirebaseManager**
  - Files: `Managers/FirebaseManager.swift`
  - Create singleton for Firestore access
  - Add computed property for `db: Firestore`
  - Add helper methods for common queries

- [ ] **4.2 Create ConversationService**
  - Files: `Services/ConversationService.swift`
  - Implement `createConversation(_:)` async
  - Implement `fetchConversations(for userID:)` async
  - Implement `listenToConversations(for userID:, completion:)`
  - Implement `updateLastMessage(_:)` async

- [ ] **4.3 Create ConversationListViewModel**
  - Files: `ViewModels/ConversationListViewModel.swift`
  - Add `@Published var conversations: [Conversation]`
  - Implement `startListening()` with Firestore listener
  - Implement `stopListening()` to remove listener
  - Add cleanup in deinit
  - Implement `saveLocally(_:)` for offline support

- [ ] **4.4 Create ConversationListView**
  - Files: `Views/Conversations/ConversationListView.swift`
  - NavigationStack with title "Chats"
  - List of conversations
  - Toolbar with "+" button for new chat
  - Pull to refresh (optional)
  - Empty state view

- [ ] **4.5 Create ConversationRow**
  - Files: `Views/Conversations/ConversationRow.swift`
  - Display avatar (AsyncImage or placeholder)
  - Display conversation name
  - Display last message preview
  - Display timestamp (relative format)
  - Display unread badge if count > 0
  - NavigationLink to ChatView

- [ ] **4.6 Create Date Extensions**
  - Files: `Extensions/Date+Extensions.swift`
  - Add `relativeTime` computed property
  - Format: "2m", "1h", "Yesterday", "Mon", "Jan 15"

- [ ] **4.7 Update ContentView with TabView**
  - Files: `ContentView.swift`
  - Add TabView with ConversationListView as first tab
  - Add tab items with icons

**PR Checklist Before Merge:**
- [ ] Conversation list displays (even if empty)
- [ ] Real-time listener works (test by adding conversation in Firestore Console)
- [ ] Timestamps format correctly
- [ ] Navigation structure works
- [ ] Memory leaks checked (listener removed in deinit)

---

## **PR #5: Core Messaging - Send & Receive**
**Branch:** `feature/core-messaging`  
**Goal:** Send and receive messages in real-time  
**Estimated Time:** 6 hours

### Tasks:
- [ ] **5.1 Create MessageService**
  - Files: `Services/MessageService.swift`
  - Implement `sendMessage(_:)` async
  - Implement `fetchMessages(for conversationID:)` async
  - Implement `listenToMessages(for conversationID:, completion:)`
  - Implement `updateMessageStatus(_:)` async
  - Implement `markAsRead(_:by userID:)` async

- [ ] **5.2 Create ChatViewModel**
  - Files: `ViewModels/ChatViewModel.swift`
  - Add `@Published var messages: [Message]`
  - Add `@Published var otherUserIsTyping: Bool`
  - Add `@Published var isLoadingSummary: Bool`
  - Implement `startListening()` for messages
  - Implement `sendMessage(text:)` with optimistic UI
  - Implement `markAsRead()`
  - Implement `updateTypingStatus(_:)`
  - Add cleanup in deinit

- [ ] **5.3 Create MessageBubble**
  - Files: `Views/Chat/MessageBubble.swift`
  - HStack with alignment based on sender
  - Text bubble with background color (blue for sent, gray for received)
  - Corner radius styling
  - Timestamp display (on tap/long press)
  - Status icon (sending, sent, delivered, read)

- [ ] **5.4 Create ChatView**
  - Files: `Views/Chat/ChatView.swift`
  - NavigationStack with conversation name in header
  - ScrollView with ScrollViewReader for auto-scroll
  - LazyVStack of MessageBubbles
  - TypingIndicator at bottom
  - MessageComposer at bottom
  - Call `startListening()` in onAppear
  - Call `markAsRead()` in onAppear
  - Auto-scroll to bottom on new message

- [ ] **5.5 Create MessageComposer**
  - Files: `Views/Chat/MessageComposer.swift`
  - TextField with `@Binding var messageText`
  - Send button (disabled if empty)
  - onChange to trigger typing indicator
  - Auto-grow text field (optional)

- [ ] **5.6 Create TypingIndicator**
  - Files: `Views/Chat/TypingIndicator.swift`
  - Display "Alice is typing..." if `otherUserIsTyping`
  - Animated dots (optional)

- [ ] **5.7 Implement Optimistic UI Updates**
  - Files: `ViewModels/ChatViewModel.swift`
  - When sending, immediately add message to `messages` array with status `.sending`
  - Save to local SwiftData first
  - Send to Firestore
  - Update status to `.sent` on success
  - Update status to `.failed` on error

- [ ] **5.8 Update ConversationRow Navigation**
  - Files: `Views/Conversations/ConversationRow.swift`
  - Add NavigationLink to ChatView
  - Pass conversation object

**PR Checklist Before Merge:**
- [ ] Can send text messages
- [ ] Messages appear instantly (optimistic UI)
- [ ] Messages sync to Firestore
- [ ] Receive messages in real-time (test with 2 devices/simulators)
- [ ] Typing indicator works
- [ ] Timestamps display correctly
- [ ] Message status icons show correctly

---

## **PR #6: Local Persistence with SwiftData**
**Branch:** `feature/local-persistence`  
**Goal:** Messages persist offline and survive app restarts  
**Estimated Time:** 3 hours

### Tasks:
- [ ] **6.1 Create LocalStorageManager**
  - Files: `Managers/LocalStorageManager.swift`
  - Setup SwiftData ModelContainer
  - Add ModelContext management
  - Implement CRUD operations for local storage

- [ ] **6.2 Create Local Models**
  - Files: `Managers/LocalStorageManager.swift`
  - Define `@Model class LocalMessage` with @Attribute
  - Define `@Model class LocalConversation` with @Attribute
  - Add conversion methods (from Message/Conversation)

- [ ] **6.3 Implement Message Persistence**
  - Files: `ViewModels/ChatViewModel.swift`
  - Save messages to SwiftData on receive
  - Load from SwiftData on app start
  - Sync with Firestore when online

- [ ] **6.4 Implement Conversation Persistence**
  - Files: `ViewModels/ConversationListViewModel.swift`
  - Save conversations to SwiftData
  - Load from local storage first
  - Update with Firestore data when available

- [ ] **6.5 Create NetworkMonitor**
  - Files: `Utilities/NetworkMonitor.swift`
  - Use NWPathMonitor to detect connectivity
  - Publish network status changes
  - Handle offline → online transitions

- [ ] **6.6 Implement Offline Message Queue**
  - Files: `Services/MessageService.swift`
  - Queue messages that fail to send
  - Retry when network returns
  - Update message status accordingly

- [ ] **6.7 Update MessageAIApp**
  - Files: `MessageAIApp.swift`
  - Add `.modelContainer` modifier with LocalMessage and LocalConversation

**PR Checklist Before Merge:**
- [ ] Messages persist after force-quit and reopen
- [ ] Conversations persist offline
- [ ] Offline messages queue and send when online
- [ ] Network status monitored correctly
- [ ] No duplicate messages on sync

---

## **PR #7: Group Chat Functionality**
**Branch:** `feature/group-chat`  
**Goal:** Create and participate in group chats  
**Estimated Time:** 4 hours

### Tasks:
- [ ] **7.1 Create UserSearchViewModel**
  - Files: `ViewModels/UserSearchViewModel.swift`
  - Add `@Published var users: [User]`
  - Add `@Published var searchText: String`
  - Implement Firestore query for user search
  - Filter by display name

- [ ] **7.2 Create NewChatView**
  - Files: `Views/Conversations/NewChatView.swift`
  - Picker for 1-on-1 vs Group
  - Group name TextField (if group)
  - User search TextField
  - List of users with checkboxes
  - "Create" button
  - Call ConversationService to create conversation

- [ ] **7.3 Create UserSearchRow**
  - Files: `Views/Conversations/UserSearchRow.swift`
  - Display user avatar and name
  - Checkmark if selected
  - Tap gesture to toggle selection

- [ ] **7.4 Update ConversationService**
  - Files: `Services/ConversationService.swift`
  - Handle group creation (3+ participants)
  - Set conversation type to `.group`
  - Save group name

- [ ] **7.5 Create GroupMessageBubble**
  - Files: `Views/Chat/GroupMessageBubble.swift`
  - Display sender name above bubble (for received messages)
  - Different styling than 1-on-1 messages

- [ ] **7.6 Update ChatView for Groups**
  - Files: `Views/Chat/ChatView.swift`
  - Use GroupMessageBubble when conversation.type == .group
  - Display participant count in header
  - Show multiple typing indicators

- [ ] **7.7 Create ChatDetailView**
  - Files: `Views/Chat/ChatDetailView.swift`
  - Display group name and icon
  - List of participants with avatars
  - "Add Member" button (optional for MVP)
  - "Leave Group" button (optional for MVP)

**PR Checklist Before Merge:**
- [ ] Can create 1-on-1 conversation
- [ ] Can create group with 3+ users
- [ ] Group messages display with sender names
- [ ] Group name shows in conversation list
- [ ] All group members receive messages

---

## **PR #8: User Presence & Read Receipts**
**Branch:** `feature/presence-read-receipts`  
**Goal:** Show online/offline status and read receipts  
**Estimated Time:** 3 hours

### Tasks:
- [ ] **8.1 Create PresenceManager**
  - Files: `Managers/PresenceManager.swift`
  - Create singleton
  - Implement `updateStatus(_:)` to write to Firestore
  - Implement `listenToUserPresence(userID:, completion:)`
  - Update on app lifecycle changes

- [ ] **8.2 Setup Firestore Presence Collection**
  - Files: `Utilities/FirestoreCollections.swift`
  - Add `userPresence` collection name
  - Structure: `userPresence/{userID}` with status and lastSeen

- [ ] **8.3 Update App Lifecycle Handling**
  - Files: `MessageAIApp.swift`
  - Add `@Environment(\.scenePhase)` observer
  - Update presence on active (online)
  - Update presence on background (away)

- [ ] **8.4 Display Online Status in ConversationRow**
  - Files: `Views/Conversations/ConversationRow.swift`
  - Listen to presence for conversation participants
  - Show green dot if online
  - Show "last seen X ago" if offline

- [ ] **8.5 Display Online Status in ChatView Header**
  - Files: `Views/Chat/ChatView.swift`
  - Show "online" or "last seen X ago" below name

- [ ] **8.6 Implement Read Receipts**
  - Files: `ViewModels/ChatViewModel.swift`
  - Update `markAsRead()` to add userID to message.readBy array
  - Batch update for efficiency

- [ ] **8.7 Update Message Status Icons**
  - Files: `Views/Chat/MessageBubble.swift`
  - Show blue checkmarks if message.readBy.count > 1
  - Show gray checkmarks if only sender in readBy

**PR Checklist Before Merge:**
- [ ] Online status displays correctly
- [ ] Status updates on app lifecycle changes
- [ ] Read receipts show when message is read
- [ ] "Last seen" timestamp displays correctly
- [ ] Performance acceptable (not too many listeners)

---

## **PR #9: Push Notifications**
**Branch:** `feature/push-notifications`  
**Goal:** Receive notifications for new messages  
**Estimated Time:** 4 hours

### Tasks:
- [ ] **9.1 Configure APNs in Firebase**
  - Go to Firebase Console → Project Settings → Cloud Messaging
  - Upload APNs Authentication Key or Certificate
  - Note: Requires Apple Developer account

- [ ] **9.2 Create NotificationManager**
  - Files: `Managers/NotificationManager.swift`
  - Create singleton conforming to `UNUserNotificationCenterDelegate`
  - Implement `requestAuthorization()` async
  - Implement `registerForRemoteNotifications()`
  - Handle FCM token registration
  - Save token to Firestore user document

- [ ] **9.3 Update AppDelegate Methods**
  - Files: `MessageAIApp.swift` (or create AppDelegate.swift)
  - Add `UIApplicationDelegateAdaptor` if using SwiftUI App
  - Implement `didRegisterForRemoteNotificationsWithDeviceToken`
  - Implement `didFailToRegisterForRemoteNotificationsWithError`
  - Set Messaging delegate

- [ ] **9.4 Implement Notification Handling**
  - Files: `Managers/NotificationManager.swift`
  - Implement `userNotificationCenter(_:willPresent:)` for foreground
  - Implement `userNotificationCenter(_:didReceive:)` for tap
  - Parse notification payload and navigate to conversation

- [ ] **9.5 Request Permission on First Launch**
  - Files: `ContentView.swift` or `ConversationListView.swift`
  - Call `NotificationManager.shared.requestAuthorization()` in onAppear

- [ ] **9.6 Setup Cloud Function for Notifications**
  - Files: `MessageAI-CloudFunctions/functions/src/messaging/sendNotification.js`
  - Create Firestore trigger on messages collection
  - Fetch recipient FCM tokens from users collection
  - Send FCM notification with message content
  - Include conversationID in data payload

- [ ] **9.7 Initialize Cloud Functions**
  - Files: `MessageAI-CloudFunctions/functions/index.js`, `package.json`
  - Run `firebase init functions`
  - Install dependencies: `firebase-admin`, `firebase-functions`
  - Export `sendMessageNotification` function

- [ ] **9.8 Deploy Cloud Functions**
  - Run `firebase deploy --only functions`
  - Verify function appears in Firebase Console

**PR Checklist Before Merge:**
- [ ] Notification permission requested
- [ ] FCM token saved to Firestore
- [ ] Cloud Function deployed successfully
- [ ] Notifications received in foreground
- [ ] Notifications received in background
- [ ] Tapping notification opens correct chat
- [ ] Notification content shows sender and message preview

---

## **PR #10: Media Support (Images)**
**Branch:** `feature/media-support`  
**Goal:** Send and receive images in chat  
**Estimated Time:** 3 hours

### Tasks:
- [ ] **10.1 Create MediaManager**
  - Files: `Managers/MediaManager.swift`
  - Create singleton with Firebase Storage reference
  - Implement `uploadImage(_:conversationID:)` async → returns URL
  - Implement image compression helper
  - Handle upload progress (optional)

- [ ] **10.2 Create Image Extensions**
  - Files: `Extensions/UIImage+Extensions.swift`
  - Add `compressed(maxSizeKB:)` method
  - JPEG compression with quality reduction loop

- [ ] **10.3 Create ImagePickerButton**
  - Files: `Views/Components/ImagePickerButton.swift`
  - Use PhotosPicker from PhotosUI
  - Binding to selected UIImage
  - Photo library access

- [ ] **10.4 Update MessageComposer**
  - Files: `Views/Chat/MessageComposer.swift`
  - Add ImagePickerButton
  - Show image preview if selected
  - Add "Remove" button for preview
  - Send button triggers image upload if image selected

- [ ] **10.5 Update ChatViewModel for Media**
  - Files: `ViewModels/ChatViewModel.swift`
  - Implement `sendImageMessage(image:)` async
  - Upload image to Storage first
  - Create message with mediaURL and mediaType
  - Show optimistic UI with placeholder

- [ ] **10.6 Create MediaMessageBubble**
  - Files: `Views/Chat/MediaMessageBubble.swift`
  - AsyncImage for loading from URL
  - Placeholder (ProgressView) while loading
  - Error state if load fails
  - Tap to view full screen (optional)
  - Support both image-only and image+text messages

- [ ] **10.7 Update ChatView**
  - Files: `Views/Chat/ChatView.swift`
  - Use MediaMessageBubble when message.mediaURL != nil
  - Else use regular MessageBubble

- [ ] **10.8 Add SDWebImage for Caching (Optional)**
  - Files: `MessageAI.xcodeproj/project.pbxproj`
  - Add SDWebImageSwiftUI via SPM
  - Replace AsyncImage with WebImage in MediaMessageBubble
  - Better caching and performance

**PR Checklist Before Merge:**
- [ ] Can select image from photo library
- [ ] Image compresses before upload
- [ ] Image uploads to Firebase Storage
- [ ] Image displays in chat bubble
- [ ] Both sender and receiver see image
- [ ] Images cached for performance
- [ ] Works in both 1-on-1 and group chats

---

## **PR #11: MVP Testing & Bug Fixes**
**Branch:** `fix/mvp-testing`  
**Goal:** Test all MVP features and fix critical bugs  
**Estimated Time:** 4 hours

### Tasks:
- [ ] **11.1 Two-Device Real-Time Test**
  - Test on 2 physical devices
  - Send 20+ messages rapidly
  - Verify all appear in correct order
  - Check delivery/read status
  - Test typing indicators
  - Document any issues

- [ ] **11.2 Offline Scenario Test**
  - Device A goes offline (airplane mode)
  - Device B sends 5 messages
  - Device A comes back online
  - Verify all messages sync correctly
  - Test both directions
  - Fix any sync issues

- [ ] **11.3 App Lifecycle Test**
  - Send message, immediately background app
  - Force quit during message send
  - Receive message while app closed
  - Test push notification tap
  - Verify no message loss
  - Fix any persistence issues

- [ ] **11.4 Group Chat Test**
  - Create group with 3 devices
  - Send messages simultaneously
  - Verify all members receive
  - Test read receipts in group
  - Test typing indicators
  - Fix any group-specific bugs

- [ ] **11.5 Poor Network Test**
  - Use Network Link Conditioner (3G)
  - Send messages on slow connection
  - Verify retry logic works
  - Check UI feedback (loading states)
  - Fix timeout issues

- [ ] **11.6 Memory Leak Check**
  - Files: Various ViewModels
  - Profile app in Xcode Instruments
  - Check for listener leaks
  - Verify deinit calls
  - Fix retain cycles

- [ ] **11.7 Error Handling**
  - Files: All ViewModels and Services
  - Test invalid inputs
  - Test network failures
  - Add user-friendly error messages
  - Implement retry mechanisms

- [ ] **11.8 UI Polish**
  - Files: Various View files
  - Fix layout issues
  - Add loading indicators
  - Improve animations
  - Add haptic feedback (optional)
  - Test on different screen sizes

**PR Checklist Before Merge:**
- [ ] All MVP requirements pass tests
- [ ] No critical bugs
- [ ] No memory leaks
- [ ] Error messages are user-friendly
- [ ] App performs well on real hardware
- [ ] Ready for demo video

---

## 🎯 **MVP COMPLETE CHECKPOINT**
**At this point, you should have:**
- ✅ Authentication working
- ✅ 1-on-1 and group chat
- ✅ Real-time messaging
- ✅ Offline persistence
- ✅ Push notifications
- ✅ Online/offline status
- ✅ Read receipts
- ✅ Image sending
- ✅ All features tested on physical devices

**Record MVP demo video now before proceeding to AI features!**

---

## **PR #12: AI Infrastructure Setup**
**Branch:** `feature/ai-infrastructure`  
**Goal:** Setup Cloud Functions, Anthropic API, and Pinecone  
**Estimated Time:** 3 hours

### Tasks:
- [ ] **12.1 Initialize Cloud Functions Project**
  - Files: `MessageAI-CloudFunctions/package.json`, `functions/index.js`
  - Run `firebase init functions` in project root
  - Choose Node.js
  - Install dependencies

- [ ] **12.2 Install AI Dependencies**
  - Files: `MessageAI-CloudFunctions/package.json`
  - `npm install @anthropic-ai/sdk`
  - `npm install @pinecone-database/pinecone`
  - `npm install openai` (for embeddings)

- [ ] **12.3 Setup Environment Variables**
  - Run `firebase functions:config:set anthropic.key="YOUR_KEY"`
  - Run `firebase functions:config:set pinecone.key="YOUR_KEY"`
  - Run `firebase functions:config:set openai.key="YOUR_KEY"`
  - Create `.env` file for local testing (add to .gitignore)

- [ ] **12.4 Create Anthropic Wrapper**
  - Files: `functions/src/utils/anthropic.js`
  - Create client initialization
  - Add helper method for messages.create
  - Add error handling and retries

- [ ] **12.5 Create Pinecone Client**
  - Files: `functions/src/utils/pinecone.js`
  - Initialize Pinecone client
  - Create index if not exists
  - Add upsert and query methods

- [ ] **12.6 Create Cache Utility**
  - Files: `functions/src/utils/cache.js`
  - Implement `getCachedOrGenerate(key, ttl, fn)`
  - Read from Firestore `aiCache` collection
  - Handle cache expiration

- [ ] **12.7 Create Rate Limiting**
  - Files: `functions/src/utils/rateLimit.js`
  - Implement `checkRateLimit(userID, feature, limit)`
  - Store in Firestore `rateLimits` collection
  - Reset daily counters

- [ ] **12.8 Create AIService in iOS**
  - Files: `Services/AIService.swift`
  - Add methods to call Cloud Functions
  - `summarizeThread(conversationID:messageCount:)` async
  - `extractActionItems(conversationID:)` async
  - Handle errors and loading states

**PR Checklist Before Merge:**
- [ ] Cloud Functions project initialized
- [ ] All AI dependencies installed
- [ ] API keys configured (not committed to git)
- [ ] Utility functions created and tested
- [ ] AIService can call functions from iOS
- [ ] Functions deploy successfully

---

## **PR #13: Thread Summarization**
**Branch:** `feature/thread-summarization`  
**Goal:** Summarize conversation threads with AI  
**Estimated Time:** 4 hours

### Tasks:
- [ ] **13.1 Create Summarization Cloud Function**
  - Files: `functions/src/ai/summarization.js`
  - Export `generateThreadSummary` as callable function
  - Verify user is conversation participant
  - Fetch messages from Firestore
  - Check cache first
  - Call Claude API with structured prompt
  - Parse and format response
  - Cache result for 1 hour
  - Return summary

- [ ] **13.2 Update Cloud Functions Index**
  - Files: `functions/index.js`
  - Import and export `generateThreadSummary`

- [ ] **13.3 Create Summary Prompt Template**
  - Files: `functions/src/ai/summarization.js`
  - Prompt focusing on: decisions, problems, questions, action items, tone
  - Format with emoji indicators
  - Test prompt with sample conversations

- [ ] **13.4 Update AIService**
  - Files: `Services/AIService.swift`
  - Implement `summarizeThread(conversationID:messageCount:)`
  - Call Cloud Function
  - Parse response
  - Return formatted summary string

- [ ] **13.5 Update ChatViewModel**
  - Files: `ViewModels/ChatViewModel.swift`
  - Add `@Published var currentSummary: String?`
  - Add `@Published var showSummary: Bool`
  - Add `@Published var isLoadingSummary: Bool`
  - Implement `summarizeThread()` method
  - Call AIService and update state

- [ ] **13.6 Create SummaryView**
  - Files: `Views/AIFeatures/SummaryView.swift`
  - NavigationStack with "Summary" title
  - ScrollView with formatted text
  - Support markdown rendering (optional)
  - "Done" button to dismiss
  - Copy to clipboard button (optional)

- [ ] **13.7 Add Summarize Button to ChatView**
  - Files: `Views/Chat/ChatView.swift`
  - Add toolbar menu with sparkles icon
  - "Summarize Conversation" menu item
  - Show loading indicator when processing
  - Present SummaryView as sheet

- [ ] **13.8 Add Analytics Tracking**
  - Files: `ViewModels/ChatViewModel.swift`
  - Track "ai_summary_requested" event
  - Track "ai_summary_viewed" event
  - Include message count and cache hit/miss

**PR Checklist Before Merge:**
- [ ] Cloud Function deployed and callable
- [ ] Summary generated successfully
- [ ] Cache working (second request faster)
- [ ] UI shows summary in readable format
- [ ] Loading states work correctly
- [ ] Error handling for API failures
- [ ] Rate limiting prevents abuse

---

## **PR #14: Action Item Extraction**
**Branch:** `feature/action-items`  
**Goal:** Extract tasks and action items from conversations  
**Estimated Time:** 4 hours

### Tasks:
- [ ] **14.1 Create Action Items Cloud Function**
  - Files: `functions/src/ai/actionItems.js`
  - Export `extractActionItems` as callable function
  - Fetch messages in date range
  - Define Claude tool use schema for structured extraction
  - Call Claude with tool use
  - Parse action items from response
  - Return array of ActionItem objects

- [ ] **14.2 Update Cloud Functions Index**
  - Files: `functions/index.js`
  - Import and export `extractActionItems`

- [ ] **14.3 Create ActionItemsViewModel**
  - Files: `ViewModels/ActionItemsViewModel.swift`
  - Add `@Published var actionItems: [ActionItem]`
  - Add `@Published var isLoading: Bool`
  - Implement `fetchActionItems(conversationID:)`
  - Implement `toggleActionItem(_:)` to mark done
  - Implement `addToReminders(_:)` for iOS Reminders integration

- [ ] **14.4 Create ActionItemsView**
  - Files: `Views/AIFeatures/ActionItemsView.swift`
  - NavigationStack with "Action Items" title
  - List of action items
  - Group by status (pending, completed)
  - Empty state if no items
  - Refresh button

- [ ] **14.5 Create ActionItemRow**
  - Files: `Views/AIFeatures/ActionItemRow.swift`
  - Checkbox button to mark done
  - Task description (with strikethrough if completed)
  - Assignee badge
  - Deadline indicator
  - Arrow button to jump to message context

- [ ] **14.6 Add Extract Action Items to ChatView**
  - Files: `Views/Chat/ChatView.swift`
  - Add menu item "Extract Action Items"
  - Show loading indicator
  - Present ActionItemsView as sheet

- [ ] **14.7 Implement Jump to Message**
  - Files: `ViewModels/ChatViewModel.swift`, `Views/AIFeatures/ActionItemsView.swift`
  - When arrow tapped, dismiss sheet
  - Scroll to specific message in chat
  - Highlight message briefly

- [ ] **14.8 Add iOS Reminders Integration (Optional)**
  - Files: `ViewModels/ActionItemsViewModel.swift`
  - Request EventKit permissions
  - Create reminder with task details
  - Set due date if available

**PR Checklist Before Merge:**
- [ ] Action items extracted accurately
- [ ] Tool use schema returns structured data
- [ ] UI displays items in list format
- [ ] Can mark items as done
- [ ] Jump to message context works
- [ ] Handles empty results gracefully

---

## **PR #15: Smart Search (Semantic + Keyword)**
**Branch:** `feature/smart-search`  
**Goal:** Search conversations with semantic and keyword search  
**Estimated Time:** 5 hours

### Tasks:
- [ ] **15.1 Create Message Embedding Function**
  - Files: `functions/src/ai/embeddings.js`
  - Create Firestore trigger on new message
  - Call OpenAI embeddings API
  - Store vector in Pinecone with metadata
  - Handle errors and retries

- [ ] **15.2 Create Search Cloud Function**
  - Files: `functions/src/ai/search.js`
  - Export `searchMessages` as callable function
  - Get query embedding from OpenAI
  - Search Pinecone for semantic matches
  - Also perform Firestore keyword search
  - Merge and rank results
  - Return combined results

- [ ] **15.3 Update Cloud Functions Index**
  - Files: `functions/index.js`
  - Export embedding trigger and search function

- [ ] **15.4 Create SearchService**
  - Files: `Services/SearchService.swift`
  - Implement `searchMessages(query:conversationID:)` async
  - Call Cloud Function
  - Parse search results
  - Return array of messages with relevance scores

- [ ] **15.5 Create SearchViewModel**
  - Files: `ViewModels/SearchViewModel.swift`
  - Add `@Published var results: [Message]`
  - Add `@Published var query: String`
  - Add `@Published var isSearching: Bool`
  - Implement `search(query:)` async
  - Debounce search input

- [ ] **15.6 Create SearchView**
  - Files: `Views/AIFeatures/SearchView.swift`
  - NavigationStack with "Search" title
  - TextField for query input
  - ProgressView while searching
  - List of SearchResultRows
  - Empty state for no results

- [ ] **15.7 Create SearchResultRow**
  - Files: `Views/AIFeatures/SearchResultRow.swift`
  - Display message text with search term highlighted
  - Show sender name and timestamp
  - Show conversation name/context
  - Tap to navigate to message in chat

- [ ] **15.8 Add Search to ConversationListView**
  - Files: `Views/Conversations/ConversationListView.swift`
  - Add search icon in toolbar
  - Present SearchView as sheet or NavigationLink
  - Pass selected conversation (optional: search within conversation)

**PR Checklist Before Merge:**
- [ ] Messages automatically embedded on creation
- [ ] Semantic search returns relevant results
- [ ] Keyword search works
- [ ] Results merged and ranked sensibly
- [ ] Search UI is responsive
- [ ] Can navigate to message from results
- [ ] Pinecone index created and populated

---

## **PR #16: Priority Message Detection**
**Branch:** `feature/priority-detection`  
**Goal:** Automatically detect and highlight priority messages  
**Estimated Time:** 4 hours

### Tasks:
- [ ] **16.1 Create Priority Detection Function**
  - Files: `functions/src/ai/priority.js`
  - Create scheduled function (runs every 30 min)
  - Fetch unread messages for each user
  - Call Claude to score priority (0-10)
  - Consider: @mentions, questions, urgency keywords, sentiment
  - Save priority messages to `userPriority/{userID}` collection

- [ ] **16.2 Create Priority Scoring Logic**
  - Files: `functions/src/ai/priority.js`
  - Heuristic scoring for fast checks
  - LLM scoring for nuanced analysis
  - Combine scores with weighted average
  - Flag messages with score > 6 as priority

- [ ] **16.3 Update Cloud Functions Index**
  - Files: `functions/index.js`
  - Export scheduled function
  - Deploy with proper schedule config

- [ ] **16.4 Update Conversation Model**
  - Files: `Models/Conversation.swift`
  - Add `priorityCount: Int?` property
  - Update from Firestore userPriority collection

- [ ] **16.5 Create PriorityViewModel**
  - Files: `ViewModels/AIFeaturesViewModel.swift` (or separate file)
  - Add `@Published var priorityConversations: [Conversation]`
  - Listen to `userPriority/{userID}` Firestore document
  - Fetch full conversation details

- [ ] **16.6 Update ConversationRow**
  - Files: `Views/Conversations/ConversationRow.swift`
  - Show red exclamation icon if priorityCount > 0
  - Display priority count badge

- [ ] **16.7 Create PriorityInboxView**
  - Files: `Views/AIFeatures/PriorityInboxView.swift`
  - NavigationStack with "Priority" title
  - List of conversations with priority messages
  - Show which specific messages are priority
  - Tap to jump to message in conversation

- [ ] **16.8 Create PriorityMessageRow**
  - Files: `Views/AIFeatures/PriorityMessageRow.swift`
  - Display message preview
  - Show priority reason (why it's flagged)
  - "Mark as Handled" button
  - Navigate to chat on tap

- [ ] **16.9 Add Priority Tab or Filter**
  - Files: `ContentView.swift` or `ConversationListView.swift`
  - Add "Priority" filter/tab
  - Badge count in tab if priorities exist
  - Navigate to PriorityInboxView

**PR Checklist Before Merge:**
- [ ] Scheduled function runs successfully
- [ ] Priority messages detected accurately
- [ ] UI shows priority indicators
- [ ] Priority inbox displays correctly
- [ ] Can mark messages as handled
- [ ] Performance acceptable (not too slow)

---

## **PR #17: Decision Tracking**
**Branch:** `feature/decision-tracking`  
**Goal:** Auto-detect and track team decisions  
**Estimated Time:** 4 hours

### Tasks:
- [ ] **17.1 Create Decision Detection Function**
  - Files: `functions/src/ai/decisions.js`
  - Create Firestore trigger on new messages
  - Check for decision language patterns
  - Fetch surrounding context (5 messages before)
  - Call Claude with tool use to extract decision
  - Save to `conversations/{id}/decisions` subcollection

- [ ] **17.2 Define Decision Tool Schema**
  - Files: `functions/src/ai/decisions.js`
  - Schema: decision, reasoning, alternatives, participants
  - Validate required fields
  - Handle null responses (no decision found)

- [ ] **17.3 Update Cloud Functions Index**
  - Files: `functions/index.js`
  - Export decision tracking trigger

- [ ] **17.4 Create DecisionsViewModel**
  - Files: `ViewModels/DecisionsViewModel.swift`
  - Add `@Published var decisions: [Decision]`
  - Implement `fetchDecisions(conversationID:)`
  - Listen to decisions subcollection
  - Sort by timestamp (most recent first)

- [ ] **17.5 Create DecisionsView**
  - Files: `Views/AIFeatures/DecisionsView.swift`
  - NavigationStack with "Decisions" title
  - ScrollView with LazyVStack of DecisionCards
  - Timeline visualization (optional)
  - Empty state if no decisions

- [ ] **17.6 Create DecisionCard**
  - Files: `Views/AIFeatures/DecisionCard.swift`
  - Display decision text prominently
  - Show date made
  - Show reasoning if available
  - List alternatives considered
  - Show participant avatars
  - Arrow button to jump to message

- [ ] **17.7 Add Decisions to ChatDetailView**
  - Files: `Views/Chat/ChatDetailView.swift`
  - Add "Decisions" section or tab
  - Show count of decisions made
  - Navigate to DecisionsView

- [ ] **17.8 Implement Jump to Decision**
  - Files: `ViewModels/ChatViewModel.swift`
  - Scroll to specific message by ID
  - Highlight message briefly
  - Dismiss DecisionsView sheet

**PR Checklist Before Merge:**
- [ ] Decisions auto-detected from conversations
- [ ] Structured data extracted correctly
- [ ] UI displays decisions timeline
- [ ] Can jump to original message context
- [ ] False positives minimized
- [ ] Performance acceptable

---

## **PR #18: Proactive Scheduling Assistant**
**Branch:** `feature/proactive-assistant`  
**Goal:** Auto-detect scheduling needs and suggest meeting times  
**Estimated Time:** 6 hours

### Tasks:
- [ ] **18.1 Create Scheduling Detection Function**
  - Files: `functions/src/ai/proactiveAssistant.js`
  - Create Firestore trigger on new messages
  - Detect scheduling keywords (meet, schedule, call, etc.)
  - Fetch conversation context
  - Call Claude to analyze intent with tool use
  - If scheduling detected, trigger assistant workflow

- [ ] **18.2 Create Intent Analysis Tool**
  - Files: `functions/src/ai/proactiveAssistant.js`
  - Tool schema: isScheduling, meetingType, duration, urgency, participants
  - Parse intent from conversation
  - Return null if not actually scheduling

- [ ] **18.3 Create Availability Checker (Mock)**
  - Files: `functions/src/ai/proactiveAssistant.js`
  - Mock availability for MVP (simulate checking calendars)
  - Return available time slots for participants
  - Note: Real calendar integration requires OAuth

- [ ] **18.4 Create Time Suggestion Generator**
  - Files: `functions/src/ai/proactiveAssistant.js`
  - Call Claude to find optimal meeting times
  - Consider: time zones, work hours, conflicts
  - Return 3 suggested time slots with availability breakdown

- [ ] **18.5 Send Assistant Message to Chat**
  - Files: `functions/src/ai/proactiveAssistant.js`
  - Create message with `isAssistantMessage: true`
  - Format suggestions with numbered options
  - Include availability and conflicts
  - Add to messages collection

- [ ] **18.6 Update Message Model**
  - Files: `Models/Message.swift`
  - Add `isAssistantMessage: Bool?` property
  - Add `suggestedTimes: [TimeSlot]?` property
  - Define `TimeSlot` struct with date, time, duration, available, conflicts

- [ ] **18.7 Create AssistantMessageBubble**
  - Files: `Views/AIFeatures/AssistantMessageBubble.swift`
  - Special styling (purple background)
  - Show "MessageBot" with sparkles icon
  - Display suggestion text
  - Interactive buttons for each time slot
  - Vote/select functionality

- [ ] **18.8 Update ChatView for Assistant Messages**
  - Files: `Views/Chat/ChatView.swift`
  - Detect `isAssistantMessage` flag
  - Render AssistantMessageBubble instead of regular bubble
  - Handle button interactions

- [ ] **18.9 Implement Voting Mechanism**
  - Files: `ViewModels/ChatViewModel.swift`
  - Method to vote for time slot
  - Send reaction or new message with vote
  - Update assistant message with vote count

- [ ] **18.10 Create Conflict Detection**
  - Files: `functions/src/ai/proactiveAssistant.js`
  - Function to check if proposed time conflicts with existing
  - Send proactive warning message
  - Suggest alternatives

**PR Checklist Before Merge:**
- [ ] Scheduling intent detected automatically
- [ ] Assistant sends proactive suggestions
- [ ] Suggestions display in chat
- [ ] Can vote on suggested times
- [ ] Assistant messages styled distinctly
- [ ] Mock availability works (real integration optional)

---

## **PR #19: Firestore Security Rules**
**Branch:** `feature/security-rules`  
**Goal:** Lock down Firestore with proper security rules  
**Estimated Time:** 2 hours

### Tasks:
- [ ] **19.1 Write User Collection Rules**
  - Files: `MessageAI-CloudFunctions/functions/config/firestore.rules`
  - Users can read any user document
  - Users can only write their own document
  - Validate data structure

- [ ] **19.2 Write Conversation Collection Rules**
  - Files: `firestore.rules`
  - Only participants can read conversation
  - Only participants can write to conversation
  - Participants can create conversations they're in

- [ ] **19.3 Write Messages Subcollection Rules**
  - Files: `firestore.rules`
  - Only participants can read messages
  - Only participants can create messages
  - Sender ID must match authenticated user

- [ ] **19.4 Write Decisions Subcollection Rules**
  - Files: `firestore.rules`
  - Only participants can read decisions
  - Only Cloud Functions can write (server-only)

- [ ] **19.5 Write User Presence Rules**
  - Files: `firestore.rules`
  - Anyone authenticated can read presence
  - Users can only write their own presence

- [ ] **19.6 Write AI Cache Rules**
  - Files: `firestore.rules`
  - Server-only (Cloud Functions)
  - No client read/write access

- [ ] **19.7 Write User Priority Rules**
  - Files: `firestore.rules`
  - Users can only read their own priority document
  - Only Cloud Functions can write

- [ ] **19.8 Deploy Security Rules**
  - Run `firebase deploy --only firestore:rules`
  - Test rules with Firebase Emulator
  - Verify in Firebase Console

**PR Checklist Before Merge:**
- [ ] All collections have security rules
- [ ] Rules tested and working
- [ ] No unauthorized access possible
- [ ] App still functions correctly with rules
- [ ] Rules deployed to production

---

## **PR #20: UI Polish & Animations**
**Branch:** `feature/ui-polish`  
**Goal:** Improve UI/UX with animations and polish  
**Estimated Time:** 3 hours

### Tasks:
- [ ] **20.1 Add Message Send Animation**
  - Files: `Views/Chat/ChatView.swift`
  - Animate new message appearing
  - Smooth scroll to bottom
  - Fade-in effect for new messages

- [ ] **20.2 Add Typing Indicator Animation**
  - Files: `Views/Chat/TypingIndicator.swift`
  - Animated dots (...)
  - Fade in/out transition

- [ ] **20.3 Add Pull-to-Refresh**
  - Files: `Views/Conversations/ConversationListView.swift`, `Views/Chat/ChatView.swift`
  - Add `.refreshable` modifier
  - Load older messages on pull
  - Show loading indicator

- [ ] **20.4 Add Haptic Feedback**
  - Files: Various View files
  - Success haptic on message sent
  - Light haptic on button taps
  - Error haptic on failures

- [ ] **20.5 Improve Loading States**
  - Files: `Views/Components/LoadingView.swift`
  - Create reusable loading component
  - Show skeleton loaders for content
  - Progress indicators for uploads

- [ ] **20.6 Add Empty States**
  - Files: Various View files
  - Empty conversation list message
  - Empty chat history message
  - Empty search results
  - Empty action items list

- [ ] **20.7 Improve Error Messages**
  - Files: `Views/Components/ErrorView.swift`
  - User-friendly error messages
  - Retry buttons where appropriate
  - Helpful guidance for common errors

- [ ] **20.8 Add Color Theme**
  - Files: `Extensions/Color+Extensions.swift`, `Assets.xcassets`
  - Define brand colors
  - Support dark mode
  - Consistent color usage throughout app

- [ ] **20.9 Improve Typography**
  - Files: Various View files
  - Consistent font sizes
  - Proper font weights
  - Readable text hierarchy

**PR Checklist Before Merge:**
- [ ] Animations smooth and performant
- [ ] Loading states clear and informative
- [ ] Empty states provide guidance
- [ ] Dark mode looks good
- [ ] Typography consistent
- [ ] App feels polished and professional

---

## **PR #21: Performance Optimization**
**Branch:** `feature/performance`  
**Goal:** Optimize app performance and reduce costs  
**Estimated Time:** 3 hours

### Tasks:
- [ ] **21.1 Implement Message Pagination**
  - Files: `ViewModels/ChatViewModel.swift`
  - Load messages in batches (50 at a time)
  - Implement `loadMoreMessages()` method
  - Track `lastDocument` for pagination
  - Add loading indicator at top

- [ ] **21.2 Optimize Image Loading**
  - Files: `Views/Chat/MediaMessageBubble.swift`
  - Lazy loading for images
  - Thumbnail generation (optional)
  - Memory management for large images

- [ ] **21.3 Implement AI Response Caching**
  - Files: `functions/src/utils/cache.js`
  - Cache summaries for 1 hour
  - Cache action items for 24 hours
  - Cache search results for 10 minutes
  - Implement cache invalidation

- [ ] **21.4 Add Rate Limiting to AI Features**
  - Files: `functions/src/utils/rateLimit.js`
  - Limit summaries to 10/day per user
  - Limit searches to 50/day per user
  - Show user their remaining quota

- [ ] **21.5 Optimize Firestore Queries**
  - Files: Various Service files
  - Use composite indexes where needed
  - Limit query results
  - Use `.limit()` for pagination
  - Monitor query costs in Firebase Console

- [ ] **21.6 Reduce Firestore Listeners**
  - Files: Various ViewModel files
  - Remove listeners when views dismissed
  - Use single listener per collection
  - Avoid redundant listeners

- [ ] **21.7 Profile with Instruments**
  - Profile app in Xcode Instruments
  - Check CPU usage
  - Check memory usage
  - Identify and fix bottlenecks

- [ ] **21.8 Create Firestore Indexes**
  - Files: `MessageAI-CloudFunctions/firestore.indexes.json`
  - Define composite indexes for complex queries
  - Deploy with `firebase deploy --only firestore:indexes`

**PR Checklist Before Merge:**
- [ ] Messages paginate smoothly
- [ ] Images load efficiently
- [ ] AI caching reduces API calls significantly
- [ ] Rate limits prevent abuse
- [ ] No performance issues on older devices
- [ ] Firestore costs reasonable

---

## **PR #22: Analytics & Monitoring**
**Branch:** `feature/analytics`  
**Goal:** Add Firebase Analytics and error tracking  
**Estimated Time:** 2 hours

### Tasks:
- [ ] **22.1 Add Firebase Analytics SDK**
  - Files: `MessageAI.xcodeproj/project.pbxproj`
  - Add FirebaseAnalytics via SPM
  - Import in `MessageAIApp.swift`

- [ ] **22.2 Add Crashlytics**
  - Files: `MessageAI.xcodeproj/project.pbxproj`
  - Add FirebaseCrashlytics via SPM
  - Upload dSYM files automatically
  - Test crash reporting

- [ ] **22.3 Track Key Events**
  - Files: Various ViewModel files
  - `message_sent` with conversation type
  - `ai_feature_used` with feature type
  - `conversation_created` with type
  - `login_success` and `signup_success`
  - `push_notification_tapped`

- [ ] **22.4 Track AI Feature Usage**
  - Files: `ViewModels/ChatViewModel.swift`, others
  - Track which AI features used most
  - Track cache hit rate
  - Track API latency
  - Track success/error rates

- [ ] **22.5 Log Custom Errors**
  - Files: Various Service files
  - Use `Crashlytics.crashlytics().record(error:)`
  - Add context with `.log()` method
  - Track non-fatal errors

- [ ] **22.6 Add Performance Monitoring**
  - Files: Various files
  - Track message load time
  - Track chat screen load time
  - Track AI function execution time
  - Use Firebase Performance SDK

- [ ] **22.7 Create Analytics Dashboard**
  - Go to Firebase Console → Analytics
  - Set up custom reports
  - Monitor key metrics
  - Set up alerts for errors

**PR Checklist Before Merge:**
- [ ] Analytics tracking events correctly
- [ ] Crashlytics capturing crashes
- [ ] Custom events appear in Firebase Console
- [ ] Performance traces visible
- [ ] No PII (personally identifiable information) logged

---

## **PR #23: Testing & Documentation**
**Branch:** `feature/testing-docs`  
**Goal:** Add tests and comprehensive documentation  
**Estimated Time:** 4 hours

### Tasks:
- [ ] **23.1 Write Unit Tests**
  - Files: `MessageAITests/` folder
  - Test User model encoding/decoding
  - Test Message model
  - Test Conversation model
  - Test date formatting extensions
  - Test image compression

- [ ] **23.2 Write ViewModel Tests**
  - Files: `MessageAITests/ViewModelTests.swift`
  - Test AuthViewModel login/signup logic
  - Test ChatViewModel message sending
  - Test ConversationListViewModel
  - Mock Firebase services

- [ ] **23.3 Write UI Tests**
  - Files: `MessageAIUITests/` folder
  - Test authentication flow
  - Test sending a message
  - Test creating a conversation
  - Test navigation

- [ ] **23.4 Create README.md**
  - Files: `README.md`
  - Project description
  - Features list
  - Tech stack
  - Screenshots
  - Setup instructions
  - Firebase configuration steps

- [ ] **23.5 Create Setup Guide**
  - Files: `SETUP.md`
  - Step-by-step Xcode setup
  - Firebase project creation
  - API keys configuration
  - Cloud Functions deployment
  - Troubleshooting common issues

- [ ] **23.6 Document File Structure**
  - Files: `ARCHITECTURE.md`
  - Explain folder organization
  - Describe each major component
  - Data flow diagrams
  - Architecture decisions

- [ ] **23.7 Create API Documentation**
  - Files: `API.md`
  - Document all Cloud Functions
  - Request/response formats
  - Error codes
  - Rate limits

- [ ] **23.8 Add Code Comments**
  - Files: All major Swift files
  - Add doc comments to public methods
  - Explain complex logic
  - Add MARK: comments for organization

**PR Checklist Before Merge:**
- [ ] Unit tests pass
- [ ] UI tests pass
- [ ] README clear and comprehensive
- [ ] Setup instructions tested on fresh machine
- [ ] Code well-commented
- [ ] Documentation up to date

---

## **PR #24: Final Testing & Bug Fixes**
**Branch:** `fix/final-testing`  
**Goal:** Comprehensive testing and bug fixes before deployment  
**Estimated Time:** 6 hours

### Tasks:
- [ ] **24.1 End-to-End Testing**
  - Test complete user journey on 3 devices
  - Sign up → create conversation → send messages → use AI features
  - Document any issues
  - Fix critical bugs

- [ ] **24.2 Cross-Device Testing**
  - Test on iPhone SE (small screen)
  - Test on iPhone 15 Pro Max (large screen)
  - Test on iPad (if supporting)
  - Fix layout issues

- [ ] **24.3 Network Conditions Testing**
  - Test on WiFi
  - Test on cellular (4G/5G)
  - Test on slow 3G
  - Test offline → online transitions
  - Fix sync issues

- [ ] **24.4 AI Features Testing**
  - Test each AI feature with edge cases
  - Empty conversations
  - Very long conversations (500+ messages)
  - Non-English text
  - Emoji-only messages
  - Fix parsing errors

- [ ] **24.5 Security Testing**
  - Try to access other users' conversations
  - Try to send messages as another user
  - Verify Firestore rules work
  - Test authentication edge cases

- [ ] **24.6 Performance Testing**
  - Test with 50+ conversations
  - Test with 1000+ messages in one chat
  - Test rapid message sending (100 messages)
  - Profile memory usage
  - Fix any performance issues

- [ ] **24.7 Error Scenario Testing**
  - Test with invalid API keys
  - Test with Firestore offline
  - Test with Storage upload failures
  - Test with AI function timeouts
  - Ensure graceful error handling

- [ ] **24.8 Final Bug Fixes**
  - Files: Various
  - Fix all critical bugs
  - Fix high-priority bugs
  - Document known issues (if any)

**PR Checklist Before Merge:**
- [ ] All features work end-to-end
- [ ] No critical bugs
- [ ] Performance acceptable on all tested devices
- [ ] Security verified
- [ ] Error handling robust
- [ ] Ready for TestFlight

---

## **PR #25: TestFlight Deployment**
**Branch:** `release/testflight`  
**Goal:** Build, archive, and deploy to TestFlight  
**Estimated Time:** 2 hours

### Tasks:
- [ ] **25.1 Update Version & Build Numbers**
  - Files: Project settings
  - Set version to 1.0.0
  - Set build number to 1
  - Update Info.plist

- [ ] **25.2 Configure App Icon**
  - Files: `Assets.xcassets/AppIcon.appiconset`
  - Add all required icon sizes
  - Verify icon displays correctly

- [ ] **25.3 Configure Launch Screen**
  - Files: `LaunchScreen.storyboard` or SwiftUI launch screen
  - Add app branding
  - Test on all devices

- [ ] **25.4 Update App Store Connect**
  - Create app listing in App Store Connect
  - Fill in app information
  - Add screenshots (placeholder OK for TestFlight)
  - Set up TestFlight beta testing

- [ ] **25.5 Archive Build**
  - Xcode → Product → Archive
  - Ensure Release scheme selected
  - Wait for archive to complete
  - Validate archive

- [ ] **25.6 Upload to App Store Connect**
  - Organizer → Distribute App
  - Select App Store Connect
  - Upload build
  - Wait for processing (~10-30 min)

- [ ] **25.7 Configure TestFlight**
  - Add internal testers
  - Enable public link (optional)
  - Add test notes
  - Submit for beta review (if needed)

- [ ] **25.8 Test TestFlight Installation**
  - Install TestFlight app on device
  - Accept invitation
  - Install MessageAI beta
  - Test basic functionality

- [ ] **25.9 Document TestFlight Link**
  - Files: `README.md`
  - Add TestFlight public link
  - Add installation instructions
  - Note any known issues

**PR Checklist Before Merge:**
- [ ] Build uploads successfully
- [ ] TestFlight build installs on device
- [ ] Basic smoke test passes
- [ ] TestFlight link documented
- [ ] Ready for demo and submission

---

## **PR #26: Demo Video & Submission Prep**
**Branch:** `feature/demo-submission`  
**Goal:** Create demo video and prepare final submission  
**Estimated Time:** 3 hours

### Tasks:
- [ ] **26.1 Record Demo Video (5-7 minutes)**
  - Real-time messaging demo (2 devices, 30 sec)
  - Group chat with 3 participants (1 min)
  - Offline scenario demonstration (1 min)
  - App lifecycle (background, force quit) (30 sec)
  - Thread summarization with real example (45 sec)
  - Action item extraction demo (45 sec)
  - Smart search demonstration (30 sec)
  - Priority message detection (30 sec)
  - Decision tracking feature (30 sec)
  - Proactive scheduling assistant (1 min)

- [ ] **26.2 Edit Demo Video**
  - Add title cards for each feature
  - Add narration or captions
  - Keep under 7 minutes
  - Export in high quality (1080p)
  - Upload to YouTube or Vimeo

- [ ] **26.3 Create Persona Brainlift Document**
  - Files: `PERSONA.md`
  - Describe Remote Team Professional persona
  - List specific pain points
  - Explain how each AI feature solves problems
  - Document key technical decisions
  - Add screenshots with annotations

- [ ] **26.4 Take Screenshots**
  - Conversation list with conversations
  - Active chat with messages
  - AI summary in action
  - Action items list
  - Priority inbox view
  - Decisions timeline
  - Proactive assistant suggestion
  - All UI states represented

- [ ] **26.5 Write Social Post**
  - Draft post for X/Twitter or LinkedIn
  - 2-3 sentences about the project
  - Highlight key features
  - Mention Remote Team Professional persona
  - Include demo video link or GIF
  - Add hashtags
  - Tag @GauntletAI

- [ ] **26.6 Finalize README**
  - Files: `README.md`
  - Add demo video embed
  - Add screenshots
  - Add TestFlight link
  - List all features
  - Include setup instructions
  - Add project structure overview
  - Link to persona document

- [ ] **26.7 Create Submission Package**
  - Ensure GitHub repo is public
  - Clean commit history (optional squash)
  - All sensitive files in .gitignore
  - README is comprehensive
  - Demo video uploaded and linked

- [ ] **26.8 Final Checklist Review**
  - [ ] GitHub repository public and clean
  - [ ] Demo video (5-7 min) complete
  - [ ] TestFlight link working
  - [ ] Persona brainlift document complete
  - [ ] Social post drafted
  - [ ] All MVP requirements met
  - [ ] All 5 required AI features working
  - [ ] Advanced AI feature (proactive assistant) working

**PR Checklist Before Merge:**
- [ ] Demo video complete and linked
- [ ] Persona document comprehensive
- [ ] Screenshots captured and added
- [ ] Social post ready
- [ ] Submission package complete
- [ ] Ready to submit

---

## 📊 **Project Progress Tracker**

### MVP Phase (PRs #1-11)
- [ ] PR #1: Project Setup & Firebase Configuration
- [ ] PR #2: Data Models & Firebase Schema
- [ ] PR #3: Authentication System
- [ ] PR #4: Conversation List & Real-Time Sync
- [ ] PR #5: Core Messaging - Send & Receive
- [ ] PR #6: Local Persistence with SwiftData
- [ ] PR #7: Group Chat Functionality
- [ ] PR #8: User Presence & Read Receipts
- [ ] PR #9: Push Notifications
- [ ] PR #10: Media Support (Images)
- [ ] PR #11: MVP Testing & Bug Fixes

**🎯 MVP Checkpoint: Demo video recorded, all requirements passing**

### AI Features Phase (PRs #12-18)
- [ ] PR #12: AI Infrastructure Setup
- [ ] PR #13: Thread Summarization
- [ ] PR #14: Action Item Extraction
- [ ] PR #15: Smart Search (Semantic + Keyword)
- [ ] PR #16: Priority Message Detection
- [ ] PR #17: Decision Tracking
- [ ] PR #18: Proactive Scheduling Assistant

### Polish & Deployment Phase (PRs #19-26)
- [ ] PR #19: Firestore Security Rules
- [ ] PR #20: UI Polish & Animations
- [ ] PR #21: Performance Optimization
- [ ] PR #22: Analytics & Monitoring
- [ ] PR #23: Testing & Documentation
- [ ] PR #24: Final Testing & Bug Fixes
- [ ] PR #25: TestFlight Deployment
- [ ] PR #26: Demo Video & Submission Prep

---

## ⏱️ **Time Estimates by Phase**

| Phase | PRs | Estimated Time | Focus |
|-------|-----|----------------|-------|
| **Setup** | 1-2 | 4 hours | Project foundation |
| **Auth** | 3 | 4 hours | User authentication |
| **Core Messaging** | 4-6 | 13 hours | Real-time chat & persistence |
| **Group & Presence** | 7-8 | 7 hours | Group chat & status |
| **Push & Media** | 9-10 | 7 hours | Notifications & images |
| **MVP Testing** | 11 | 4 hours | Comprehensive testing |
| **AI Setup** | 12 | 3 hours | Cloud Functions & APIs |
| **AI Features** | 13-18 | 27 hours | All AI capabilities |
| **Security & Polish** | 19-22 | 10 hours | Rules, UI, performance |
| **Testing & Docs** | 23-24 | 10 hours | Quality assurance |
| **Deployment** | 25-26 | 5 hours | TestFlight & submission |
| **Total** | 26 PRs | **94 hours** | ~12 full days |

---

## 🔄 **Git Workflow**

For each PR:

```bash
# 1. Create feature branch from main
git checkout main
git pull origin main
git checkout -b feature/branch-name

# 2. Make changes, commit frequently
git add .
git commit -m "feat: description of changes"

# 3. Push branch to GitHub
git push origin feature/branch-name

# 4. Create Pull Request on GitHub
# - Add description
# - Reference checklist items
# - Add screenshots if UI changes

# 5. Review and merge
# - Review your own code
# - Test functionality
# - Merge to main

# 6. Delete branch and move to next
git checkout main
git branch -d feature/branch-name
```

---

## 📝 **Commit Message Conventions**

Use semantic commit messages:

- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code refactoring
- `style:` UI/formatting changes
- `docs:` Documentation
- `test:` Tests
- `chore:` Build/config changes

Examples:
- `feat: add message sending with optimistic UI`
- `fix: resolve message ordering issue`
- `refactor: extract MessageBubble component`
- `style: improve chat screen layout`

---

## 🚨 **Critical Path Reminders**

1. **MVP First** - Don't start AI features until PRs #1-11 are complete and tested
2. **Test on Hardware** - Always test on physical devices, not just simulator
3. **Commit Often** - Small, focused commits are easier to debug
4. **One Feature Per PR** - Keep PRs focused and reviewable
5. **Test Before Merging** - Every PR should be tested before merging
6. **Document as You Go** - Update README and docs with each major feature

---

## 🎯 **Success Criteria**

Your project is complete when:
- [ ] All 26 PRs merged to main
- [ ] MVP demo video recorded (passes all checkpoints)
- [ ] All 5 required AI features working
- [ ] Proactive assistant (advanced feature) working
- [ ] TestFlight build deployed and installable
- [ ] Demo video (5-7 min) complete
- [ ] Persona brainlift document written
- [ ] GitHub repo public with comprehensive README
- [ ] Social post ready to share

---

## 💡 **Tips for Solo Development**

1. **Timebox Tasks** - If stuck on something >2 hours, move on and come back
2. **Use AI Coding Tools** - Claude, Cursor, GitHub Copilot for faster development
3. **Start Simple** - Get basic version working, then enhance
4. **Test Frequently** - Don't write 500 lines without testing
5. **Take Breaks** - Fresh eyes catch bugs faster
6. **Mock When Needed** - Mock calendar integration, don't build OAuth in week 1
7. **Focus on Core** - Skip nice-to-haves if running short on time
8. **Document Issues** - Keep a notes.md file for bugs and TODOs

---

## 📞 **When You Need Help**

If blocked on:
- **Firebase Setup** → Check Firebase docs, verify API keys
- **SwiftUI Issues** → Check Apple docs, use Xcode previews
- **Real-time Sync** → Test Firestore listeners in isolation
- **AI Responses** → Test prompts in Claude playground first
- **Deployment** → Check TestFlight status in App Store Connect

Good luck! 🚀

You've got a clear roadmap. Build one PR at a time, test thoroughly, and you'll have a production-quality AI messaging app in one week.