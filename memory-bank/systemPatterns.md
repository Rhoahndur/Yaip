# System Patterns: Yaip

## Architecture Overview

### High-Level Architecture
```
iOS App (SwiftUI/Swift)
    ↕️ Real-time listeners + HTTPS calls
Firebase Backend
    ↕️ Triggers + Callable functions
Cloud Functions (Node.js)
    ↕️ API calls
External AI Services (Claude, OpenAI, Pinecone)
```

## iOS App Architecture

### Layer Structure (MVVM + Services)

```
Views (UI Layer)
  ↓ bindings
ViewModels (Presentation Logic)
  ↓ business logic
Services (Data Operations)
  ↓ network/storage calls
Managers (System Interfaces)
  ↓ Firebase/Apple APIs
Firebase/Local Storage
```

### Key Architectural Patterns

#### 1. MVVM (Model-View-ViewModel)
**Why**: SwiftUI's reactive nature pairs perfectly with MVVM

**Implementation**:
- **Models**: Pure data structures (Codable, Identifiable)
- **Views**: SwiftUI views (declarative UI)
- **ViewModels**: `ObservableObject` classes with `@Published` properties

**Example**:
```swift
// Model
struct Message: Codable, Identifiable { ... }

// ViewModel
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    private let messageService: MessageService
    
    func sendMessage(text: String) { ... }
}

// View
struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    var body: some View { ... }
}
```

#### 2. Service Layer Pattern
**Why**: Separate data operations from presentation logic

**Services**:
- `MessageService`: CRUD operations for messages
- `ConversationService`: CRUD for conversations
- `AIService`: Calls to Cloud Functions
- `SearchService`: Search operations

**Responsibilities**:
- Network calls to Firebase
- Data transformation
- Error handling
- Business logic that's reusable across ViewModels

#### 3. Manager (Singleton) Pattern
**Why**: System-wide state and Apple API interfaces

**Managers**:
- `AuthManager`: Current user state, auth operations
- `PresenceService`: User online/offline status
- `LocalNotificationManager`: Local notification handling (in-app + system)
- `ImageUploadManager`: Unified image lifecycle management (NEW)
- `LocalStorageManager`: SwiftData operations + image caching
- `NetworkMonitor`: Network connectivity state (NEW)

**Pattern**:
```swift
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var user: User?
    @Published var isAuthenticated = false
    private init() { ... }
}
```

#### 4. Image Upload State Machine Pattern (NEW)
**Why**: Unified image handling with clear states and retry logic

**ImageUploadManager** manages the full lifecycle:
```swift
enum ImageState {
    case notStarted
    case cached(UIImage)           // Saved to disk, ready to upload
    case uploading(progress: Double) // Currently uploading
    case uploaded(url: String)      // Successfully uploaded
    case failed(error: String, retryCount: Int) // Failed, can retry
}

class ImageUploadManager: ObservableObject {
    static let shared = ImageUploadManager()
    @Published private var imageStates: [String: ImageState] = [:]
    
    func cacheImage(_ image: UIImage, for messageID: String)
    func uploadImage(for messageID: String, conversationID: String) async -> String?
    func retryUpload(for messageID: String, conversationID: String) async -> String?
    func getCachedImage(for messageID: String) -> UIImage?
    func cleanup(for messageID: String)
}
```

**Flow**:
1. User selects image → `cacheImage()` → saved to disk
2. Online: `uploadImage()` → `.uploading` → `.uploaded` (cleanup) or `.failed`
3. Offline: stays `.cached`, retries automatically on reconnect
4. Manual retry: user taps "Tap to retry" → `retryUpload()`

**Benefits**:
- Single source of truth for image state
- Observable states for UI updates
- Automatic cleanup after upload
- Max 3 retry attempts
- Survives app restarts (cached to disk)

#### 5. Repository Pattern (Local + Remote)
**Why**: Offline-first architecture with sync

**Pattern**:
```swift
class MessageService {
    func sendMessage(_ message: Message) async throws {
        // 1. Save locally first (optimistic UI)
        await localStorage.save(message)
        
        // 2. Send to Firebase
        try await firestore.collection("messages").addDocument(from: message)
        
        // 3. Update status
        message.status = .sent
    }
}
```

#### 6. Message Lifecycle State Ownership Pattern (NEW)
**Why**: Clear rules for who owns message state at each stage

**State Ownership**:
- **Local States** (Device owns):
  - `.staged`: Created, saved locally, ready to send
  - `.sending`: Currently uploading/sending
  - `.failed`: Send failed, needs retry

- **Network States** (Firestore owns):
  - `.sent`: Successfully saved to Firestore
  - `.delivered`: Confirmed by recipient's listener
  - `.read`: Recipient opened chat

**MessageStatus Enum**:
```swift
enum MessageStatus: String, Codable {
    case staged, sending, failed  // Local states
    case sent, delivered, read     // Network states
    
    var isLocal: Bool { 
        [.staged, .sending, .failed].contains(self) 
    }
    var isRetryable: Bool { 
        self == .failed 
    }
    var isSynced: Bool { 
        [.sent, .delivered, .read].contains(self) 
    }
}
```

**Merge Logic** (ChatViewModel.startListening):
```swift
// Lifecycle-aware merge: local pending + Firestore synced
let firestoreByID = Dictionary(uniqueKeysWithValues: firestoreMessages.map { ($0.id, $0) })
var localByID: [String: Message] = [:]
for msg in oldMessages {
    localByID[msg.id] = msg
}

var merged: [Message] = []
for (id, firestoreMsg) in firestoreByID {
    if let localMsg = localByID[id], localMsg.status.isLocal {
        // Prefer local if still pending
        merged.append(localMsg)
    } else {
        // Use Firestore version (source of truth for synced messages)
        merged.append(firestoreMsg)
    }
}

// Add local-only messages not yet in Firestore
for (id, localMsg) in localByID where firestoreByID[id] == nil && localMsg.status.isLocal {
    merged.append(localMsg)
}
```

**Benefits**:
- Prevents race conditions (Firestore doesn't overwrite pending local messages)
- Clear ownership rules
- Local changes always visible until confirmed
- Firestore is source of truth for synced data

#### 7. Network State View Modifier Pattern (NEW)
**Why**: Centralized network state management across views

**Problem**: Previously, every view had duplicate network monitoring code, leading to:
- Inconsistent offline banners
- Scattered reconnection logic
- Difficulty testing network scenarios

**Solution**: Custom SwiftUI `ViewModifier`s for declarative network handling

**Implementation** (NetworkStateViewModifier.swift):
```swift
// 1. Network Status Banner
struct NetworkStateBannerModifier: ViewModifier {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if !networkMonitor.isConnected {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("No internet - Messages will send when reconnected")
                        .font(.caption)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.orange)
            }
            content
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }
}

// 2. Reconnection Action Trigger
struct OnNetworkReconnectModifier: ViewModifier {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    let action: () async -> Void
    @State private var initialCheckDone = false
    
    func body(content: Content) -> some View {
        content
            .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
                if initialCheckDone && !oldValue && newValue {
                    Task { await action() }
                }
            }
            .onAppear {
                DispatchQueue.main.async { initialCheckDone = true }
            }
    }
}

// View Extensions
extension View {
    func networkStateBanner() -> some View {
        modifier(NetworkStateBannerModifier())
    }
    
    func onNetworkReconnect(perform action: @escaping () async -> Void) -> some View {
        modifier(OnNetworkReconnectModifier(action: action))
    }
}
```

**Usage**:
```swift
struct ConversationListView: View {
    @StateObject private var viewModel = ConversationListViewModel()
    
    var body: some View {
        NavigationStack {
            // ... content ...
        }
        .networkStateBanner()  // Automatic offline banner
        .onNetworkReconnect {   // Automatic data refresh
            await viewModel.fetchConversations()
        }
    }
}
```

**Benefits**:
- Declarative, SwiftUI-native approach
- No duplicate code across views
- Consistent UX
- Easy to test
- Only triggers on reconnect (not initial load)

## Data Flow Patterns

### 1. Real-Time Listener Pattern
**For**: Conversations, Messages, Presence

**Pattern**:
```swift
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    private var listener: ListenerRegistration?
    
    func startListening() {
        listener = db.collection("messages")
            .whereField("conversationID", isEqualTo: conversationID)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.messages = snapshot?.documents.compactMap { 
                    try? $0.data(as: Message.self) 
                } ?? []
            }
    }
    
    deinit {
        listener?.remove()  // Critical: prevent memory leaks
    }
}
```

### 2. Optimistic UI Pattern
**For**: Message sending, status updates

**Pattern**:
```swift
func sendMessage(text: String) {
    let newMessage = Message(id: UUID(), text: text, status: .sending)
    
    // 1. Update UI immediately
    messages.append(newMessage)
    
    // 2. Save locally
    Task {
        await localStorage.save(newMessage)
        
        // 3. Send to server
        do {
            try await messageService.send(newMessage)
            // Update status to .sent
            updateMessageStatus(newMessage.id, to: .sent)
        } catch {
            // Update status to .failed
            updateMessageStatus(newMessage.id, to: .failed)
        }
    }
}
```

### 3. Cache-First Pattern
**For**: AI feature responses

**Pattern**:
```javascript
async function generateSummary(conversationID) {
    const cacheKey = `summary_${conversationID}`;
    
    // 1. Check cache
    const cached = await getCached(cacheKey);
    if (cached && !isExpired(cached, 60 * 60)) {
        return cached.data;
    }
    
    // 2. Generate fresh
    const summary = await callClaude(...);
    
    // 3. Cache it
    await setCache(cacheKey, summary, ttl: 3600);
    
    return summary;
}
```

## Firebase Patterns

### Firestore Schema Design

#### 1. Document Structure
```
users/{userID}
  - displayName: string
  - email: string
  - status: string
  - lastSeen: timestamp

conversations/{conversationID}
  - type: "oneOnOne" | "group"
  - participants: [userID1, userID2, ...]
  - lastMessage: { text, senderID, timestamp }
  - updatedAt: timestamp
  
  messages/{messageID}  // Subcollection
    - senderID: string
    - text: string
    - timestamp: timestamp
    - status: string
    - readBy: [userID1, ...]
  
  decisions/{decisionID}  // Subcollection
    - decision: string
    - reasoning: string
    - timestamp: timestamp

userPresence/{userID}
  - status: "online" | "offline" | "away"
  - lastSeen: timestamp

aiCache/{cacheKey}
  - data: any
  - timestamp: number
```

#### 2. Query Patterns

**Conversations for User**:
```swift
db.collection("conversations")
  .whereField("participants", arrayContains: currentUserID)
  .order(by: "updatedAt", descending: true)
```

**Messages in Conversation**:
```swift
db.collection("conversations/{id}/messages")
  .order(by: "timestamp", descending: false)
  .limit(to: 50)
```

**Unread Messages**:
```swift
db.collection("conversations/{id}/messages")
  .whereField("readBy", not: arrayContains: currentUserID)
```

### Security Rules Pattern
**Principle**: Participants-only access

```javascript
match /conversations/{conversationID} {
  allow read: if request.auth.uid in resource.data.participants;
  allow write: if request.auth.uid in resource.data.participants;
  
  match /messages/{messageID} {
    allow read: if request.auth.uid in 
      get(/databases/$(database)/documents/conversations/$(conversationID)).data.participants;
    allow create: if request.auth.uid == request.resource.data.senderID;
  }
}
```

## AI Integration Patterns

### 1. Callable Cloud Function Pattern
**For**: On-demand AI features (summarization, action items)

**iOS Side**:
```swift
func summarizeThread() async throws -> String {
    let functions = Functions.functions()
    let callable = functions.httpsCallable("generateThreadSummary")
    
    let result = try await callable.call([
        "conversationID": conversationID,
        "messageCount": 200
    ])
    
    guard let data = result.data as? [String: Any],
          let summary = data["summary"] as? String else {
        throw AIError.invalidResponse
    }
    
    return summary
}
```

**Cloud Function**:
```javascript
exports.generateThreadSummary = functions.https.onCall(async (data, context) => {
    // 1. Verify auth
    if (!context.auth) throw new HttpsError('unauthenticated');
    
    // 2. Verify permissions
    const conv = await db.collection('conversations').doc(data.conversationID).get();
    if (!conv.data().participants.includes(context.auth.uid)) {
        throw new HttpsError('permission-denied');
    }
    
    // 3. Fetch data
    const messages = await fetchMessages(data.conversationID, data.messageCount);
    
    // 4. Call AI
    const summary = await callClaude(messages);
    
    return { summary };
});
```

### 2. Firestore Trigger Pattern
**For**: Automatic AI processing (decisions, embeddings, priority)

```javascript
exports.detectDecision = functions.firestore
    .document('conversations/{convID}/messages/{msgID}')
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        
        // 1. Check if message might contain decision
        if (!containsDecisionKeywords(message.text)) return;
        
        // 2. Fetch context
        const context = await fetchPreviousMessages(context.params.convID, 5);
        
        // 3. Call AI to extract decision
        const decision = await extractDecision(message, context);
        
        // 4. Save to subcollection
        if (decision) {
            await db.collection('conversations')
                .doc(context.params.convID)
                .collection('decisions')
                .add(decision);
        }
    });
```

### 3. Scheduled Function Pattern
**For**: Background processing (priority detection)

```javascript
exports.detectPriorityMessages = functions.pubsub
    .schedule('every 30 minutes')
    .onRun(async (context) => {
        const users = await db.collection('users').get();
        
        for (const userDoc of users.docs) {
            const unreadMessages = await getUnreadMessages(userDoc.id);
            const priorityMessages = await scorePriority(unreadMessages);
            
            if (priorityMessages.length > 0) {
                await db.collection('userPriority')
                    .doc(userDoc.id)
                    .set({ priorityMessages });
            }
        }
    });
```

### 4. Tool Use Pattern (Structured Output)
**For**: Action items, decisions, scheduling

```javascript
const response = await anthropic.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    tools: [{
        name: 'extract_action_items',
        description: 'Extract tasks from conversation',
        input_schema: {
            type: 'object',
            properties: {
                action_items: {
                    type: 'array',
                    items: {
                        type: 'object',
                        properties: {
                            task: { type: 'string' },
                            assignee: { type: 'string' },
                            deadline: { type: 'string' }
                        }
                    }
                }
            }
        }
    }],
    messages: [...]
});

const toolUse = response.content.find(c => c.type === 'tool_use');
const actionItems = toolUse.input.action_items;
```

## Error Handling Patterns

### 1. Graceful Degradation
```swift
func fetchMessages() async {
    do {
        // Try remote first
        messages = try await messageService.fetchRemote()
    } catch {
        // Fall back to local cache
        messages = await localStorage.fetchMessages()
        showOfflineBanner = true
    }
}
```

### 2. Retry with Exponential Backoff
```swift
func sendWithRetry(message: Message, maxRetries: Int = 3) async throws {
    var retryCount = 0
    var delay: TimeInterval = 1.0
    
    while retryCount < maxRetries {
        do {
            try await messageService.send(message)
            return
        } catch {
            retryCount += 1
            if retryCount == maxRetries { throw error }
            
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            delay *= 2  // Exponential backoff
        }
    }
}
```

### 3. User-Friendly Error Messages
```swift
enum AppError: LocalizedError {
    case networkUnavailable
    case authenticationFailed
    case messageSendFailed
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "You're offline. Messages will send when connected."
        case .authenticationFailed:
            return "Login failed. Please check your credentials."
        case .messageSendFailed:
            return "Message couldn't be sent. Tap to retry."
        }
    }
}
```

## Component Relationships

### Dependency Flow (Unidirectional)
```
View
  ↓ owns
ViewModel
  ↓ calls
Service
  ↓ uses
Manager → Firebase
  ↓ calls
Firebase APIs
```

**Rules**:
- Views never call Services directly (always through ViewModel)
- Services never import Views (one-way dependency)
- Managers are singletons, shared across services
- Models are dumb data structures (no business logic)

## Performance Patterns

### 1. Pagination
```swift
func loadMoreMessages() {
    guard !isLoadingMore, let lastDoc = lastDocument else { return }
    
    db.collection("messages")
        .order(by: "timestamp", descending: true)
        .start(afterDocument: lastDoc)
        .limit(to: 50)
        .getDocuments { ... }
}
```

### 2. Lazy Loading
```swift
LazyVStack {
    ForEach(messages) { message in
        MessageBubble(message: message)
            .onAppear {
                if message == messages.last {
                    viewModel.loadMoreMessages()
                }
            }
    }
}
```

### 3. Image Caching
```swift
// Using SDWebImage for automatic caching
WebImage(url: URL(string: message.mediaURL))
    .resizable()
    .placeholder { ProgressView() }
    .frame(maxWidth: 200, maxHeight: 200)
```

## Key Design Decisions

1. **MVVM over MVC**: Better separation, testability with SwiftUI
2. **Firebase over custom backend**: Proven, scalable, fast to implement
3. **SwiftData over Core Data**: Modern, type-safe, less boilerplate
4. **Cloud Functions over iOS AI**: Cost control, API key security
5. **Firestore over Realtime Database**: Better querying, structure
6. **Subcollections for messages**: Better scaling, query performance
7. **Optimistic UI**: Better UX, perceived performance
8. **Offline-first**: Reliability over always-online requirement

