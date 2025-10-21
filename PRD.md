# MessageAI - Product Requirements Document
## Swift + Firebase Implementation

**Version:** 1.0  
**Last Updated:** October 20, 2025  
**Target Persona:** Remote Team Professional  
**Builder:** Solo Developer  
**AI Approach:** Contextual AI embedded in conversations + Proactive Assistant

---

## Executive Summary

MessageAI is an AI-enhanced messaging app for remote software teams struggling with information overload and async coordination. Built with Swift/SwiftUI and Firebase, it delivers WhatsApp-quality messaging with intelligent features that surface priority messages, extract action items, and proactively assist with scheduling.

**Core Value Prop:** Reliable messaging infrastructure + contextual AI that makes team communication actionable without leaving the conversation flow.

---

## MVP Requirements - CRITICAL PATH

This is your hard gate. Everything here must work reliably before moving to AI features.

### MVP Success Criteria
✅ Two physical devices can chat in real-time with <500ms latency  
✅ Messages persist after force-quit and reopen  
✅ Offline mode: messages queue and send on reconnect  
✅ Group chat with 3 people works smoothly  
✅ No message loss in any scenario  
✅ All features work on actual iPhone hardware (not just simulator)

---

## MVP Phase 1: Authentication & Profiles

### User Authentication
**Must Have:**
- Email/password registration with validation
- Email/password login
- "Forgot password" flow
- Automatic login (persisted session)

**User Model:**
```swift
struct User: Codable, Identifiable {
    let id: String              // Firebase Auth UID
    var displayName: String     // Required, 2-30 chars
    var email: String
    var profileImageURL: String?
    var status: UserStatus      // online, offline, away
    var lastSeen: Date
    var createdAt: Date
}

enum UserStatus: String, Codable {
    case online, offline, away
}
```

**Firestore Schema:**
```
users/{userID}
  - displayName: String
  - email: String
  - profileImageURL: String (optional)
  - status: String ("online", "offline", "away")
  - lastSeen: Timestamp
  - createdAt: Timestamp
```

**UI Screens:**
1. **Welcome Screen** → "Sign Up" or "Log In" buttons
2. **Registration Screen:**
   - Email input
   - Password input (min 8 chars, show/hide toggle)
   - Display name input
   - "Create Account" button
3. **Login Screen:**
   - Email input
   - Password input
   - "Log In" button
   - "Forgot Password?" link
4. **Profile Setup (after registration):**
   - Display name (editable)
   - Optional: Upload profile photo
   - "Get Started" button → Main app

**Implementation Details:**
```swift
// Firebase Auth setup
import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    func signUp(email: String, password: String, displayName: String) async throws {
        // 1. Create Firebase Auth user
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // 2. Create Firestore user document
        let user = User(
            id: result.user.uid,
            displayName: displayName,
            email: email,
            status: .online,
            lastSeen: Date(),
            createdAt: Date()
        )
        try await Firestore.firestore().collection("users").document(user.id).setData(from: user)
        
        // 3. Update state
        self.user = user
        self.isAuthenticated = true
    }
    
    func signIn(email: String, password: String) async throws {
        // Similar flow: Auth.auth().signIn() then fetch user doc
    }
}
```

**Testing Checkpoints:**
- Create account, force quit app, reopen → should stay logged in
- Invalid email/password shows clear error
- Display name appears in Firestore

---

## MVP Phase 2: Core Messaging

### Conversation Data Model

```swift
struct Conversation: Codable, Identifiable {
    let id: String
    var type: ConversationType
    var participants: [String]       // User IDs
    var participantDetails: [User]   // Cached for display
    var name: String?                // For groups only
    var imageURL: String?            // Group icon
    var lastMessage: LastMessage?
    var createdAt: Date
    var updatedAt: Date
    var unreadCount: [String: Int]   // [userID: count]
}

enum ConversationType: String, Codable {
    case oneOnOne, group
}

struct LastMessage: Codable {
    let text: String
    let senderID: String
    let timestamp: Date
}
```

**Firestore Schema:**
```
conversations/{conversationID}
  - type: String ("oneOnOne", "group")
  - participants: Array<String>
  - name: String (optional, for groups)
  - imageURL: String (optional)
  - lastMessage: Map {text, senderID, timestamp}
  - createdAt: Timestamp
  - updatedAt: Timestamp
  - unreadCount: Map {userID: Int}
  
  messages/ (subcollection)
    {messageID}/
      - conversationID: String
      - senderID: String
      - text: String
      - timestamp: Timestamp
      - status: String ("sending", "sent", "delivered", "read")
      - readBy: Array<String>
```

### Message Data Model

```swift
struct Message: Codable, Identifiable {
    let id: String
    let conversationID: String
    let senderID: String
    var text: String
    var timestamp: Date
    var status: MessageStatus
    var readBy: [String]             // User IDs who read
    
    // Computed property for display
    var isFromCurrentUser: Bool {
        senderID == AuthManager.shared.currentUserID
    }
}

enum MessageStatus: String, Codable {
    case sending    // Optimistic UI - not yet sent
    case sent       // Saved to Firestore
    case delivered  // Other user's device received
    case read       // Other user opened chat
    case failed     // Send failed, needs retry
}
```

### SwiftData Local Storage

```swift
import SwiftData

@Model
class LocalMessage {
    @Attribute(.unique) var id: String
    var conversationID: String
    var senderID: String
    var text: String
    var timestamp: Date
    var status: String
    var isSynced: Bool
    
    init(from message: Message) {
        self.id = message.id
        self.conversationID = message.conversationID
        self.senderID = message.senderID
        self.text = message.text
        self.timestamp = message.timestamp
        self.status = message.status.rawValue
        self.isSynced = true
    }
}

@Model
class LocalConversation {
    @Attribute(.unique) var id: String
    var type: String
    var participants: [String]
    var name: String?
    var lastMessageText: String?
    var lastMessageTimestamp: Date?
    var updatedAt: Date
    
    init(from conversation: Conversation) {
        self.id = conversation.id
        self.type = conversation.type.rawValue
        self.participants = conversation.participants
        self.name = conversation.name
        self.lastMessageText = conversation.lastMessage?.text
        self.lastMessageTimestamp = conversation.lastMessage?.timestamp
        self.updatedAt = conversation.updatedAt
    }
}
```

### Conversation List Screen (Chat Home)

**UI Layout:**
```
Navigation Stack
  ├─ Header: "Chats" + [+ New Chat] button
  ├─ Search Bar (for finding conversations)
  └─ List of Conversations
      └─ ConversationRow
          ├─ Avatar (profile pic or group icon)
          ├─ Name (participant name or group name)
          ├─ Last message preview (truncated to 1 line)
          ├─ Timestamp (relative: "2m", "1h", "Yesterday")
          └─ Badge (unread count if > 0)
```

**Implementation:**
```swift
struct ConversationListView: View {
    @StateObject private var viewModel = ConversationListViewModel()
    @State private var showNewChat = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(destination: ChatView(conversation: conversation)) {
                        ConversationRow(conversation: conversation)
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewChat = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showNewChat) {
                NewChatView()
            }
        }
        .onAppear {
            viewModel.startListening()
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: conversation.imageURL ?? "")) { image in
                image.resizable()
            } placeholder: {
                Circle().fill(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.name ?? "Unknown")
                        .font(.headline)
                    Spacer()
                    Text(conversation.lastMessage?.timestamp.relativeTime ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(conversation.lastMessage?.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            if let unread = conversation.unreadCount[AuthManager.shared.currentUserID], unread > 0 {
                Text("\(unread)")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(.blue)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 4)
    }
}
```

**ViewModel with Real-Time Listener:**
```swift
class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func startListening() {
        let userID = AuthManager.shared.currentUserID
        
        listener = db.collection("conversations")
            .whereField("participants", arrayContains: userID)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                self?.conversations = documents.compactMap { doc in
                    try? doc.data(as: Conversation.self)
                }
                
                // Save to SwiftData for offline
                Task {
                    await self?.saveLocally(self?.conversations ?? [])
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
}
```

### Chat Screen (Message View)

**UI Layout:**
```
Navigation Stack
  ├─ Header
  │   ├─ Back Button
  │   ├─ Conversation Name
  │   ├─ Status Indicator ("online" or "last seen X ago")
  │   └─ Info Button → Chat Details
  │
  ├─ Messages List (ScrollView)
  │   └─ MessageBubble
  │       ├─ Text content
  │       ├─ Timestamp (on tap/long press)
  │       └─ Status (✓, ✓✓, blue ✓✓ for read)
  │
  ├─ Typing Indicator ("Alice is typing...")
  │
  └─ Message Composer
      ├─ Text Input Field
      └─ Send Button
```

**Message Bubbles:**
```swift
struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                HStack(spacing: 4) {
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if isFromCurrentUser {
                        statusIcon
                    }
                }
            }
            
            if !isFromCurrentUser { Spacer() }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    var statusIcon: some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock")
        case .sent:
            Image(systemName: "checkmark")
        case .delivered:
            Image(systemName: "checkmark.checkmark")
        case .read:
            Image(systemName: "checkmark.checkmark")
                .foregroundStyle(.blue)
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.red)
        }
    }
}
```

**Chat View Implementation:**
```swift
struct ChatView: View {
    let conversation: Conversation
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var isTyping = false
    
    init(conversation: Conversation) {
        self.conversation = conversation
        self._viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.isFromCurrentUser
                            )
                            .id(message.id)
                        }
                    }
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // Typing indicator
            if viewModel.otherUserIsTyping {
                HStack {
                    Text("typing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    Spacer()
                }
            }
            
            // Composer
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: messageText) { _, newValue in
                        viewModel.updateTypingStatus(!newValue.isEmpty)
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle(conversation.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startListening()
            viewModel.markAsRead()
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        viewModel.sendMessage(text: messageText)
        messageText = ""
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}
```

### Chat ViewModel with Real-Time & Optimistic Updates

```swift
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var otherUserIsTyping = false
    
    private let conversation: Conversation
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init(conversation: Conversation) {
        self.conversation = conversation
    }
    
    func startListening() {
        listener = db.collection("conversations")
            .document(conversation.id)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                self?.messages = documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }
                
                // Save locally
                Task {
                    await self?.saveMessagesLocally()
                }
            }
        
        // Listen for typing indicator
        listenForTypingIndicator()
    }
    
    func sendMessage(text: String) {
        let messageID = UUID().uuidString
        let currentUserID = AuthManager.shared.currentUserID
        
        // 1. Create message with "sending" status (optimistic)
        var newMessage = Message(
            id: messageID,
            conversationID: conversation.id,
            senderID: currentUserID,
            text: text,
            timestamp: Date(),
            status: .sending,
            readBy: [currentUserID]
        )
        
        // 2. Add to UI immediately (optimistic update)
        messages.append(newMessage)
        
        // 3. Save locally first
        Task {
            await saveMessageLocally(newMessage)
        }
        
        // 4. Send to Firestore
        Task {
            do {
                // Save message
                try db.collection("conversations")
                    .document(conversation.id)
                    .collection("messages")
                    .document(messageID)
                    .setData(from: newMessage)
                
                // Update conversation lastMessage
                try await db.collection("conversations")
                    .document(conversation.id)
                    .updateData([
                        "lastMessage": [
                            "text": text,
                            "senderID": currentUserID,
                            "timestamp": Timestamp(date: Date())
                        ],
                        "updatedAt": Timestamp(date: Date())
                    ])
                
                // Update status to "sent"
                newMessage.status = .sent
                if let index = messages.firstIndex(where: { $0.id == messageID }) {
                    messages[index] = newMessage
                }
                
            } catch {
                // Update status to "failed"
                if let index = messages.firstIndex(where: { $0.id == messageID }) {
                    messages[index].status = .failed
                }
            }
        }
    }
    
    func markAsRead() {
        let currentUserID = AuthManager.shared.currentUserID
        
        Task {
            // Mark all messages as read
            let batch = db.batch()
            
            for message in messages where !message.readBy.contains(currentUserID) {
                let ref = db.collection("conversations")
                    .document(conversation.id)
                    .collection("messages")
                    .document(message.id)
                
                batch.updateData(["readBy": FieldValue.arrayUnion([currentUserID])], forDocument: ref)
            }
            
            try? await batch.commit()
        }
    }
    
    func updateTypingStatus(_ isTyping: Bool) {
        let currentUserID = AuthManager.shared.currentUserID
        
        Task {
            try? await db.collection("conversations")
                .document(conversation.id)
                .collection("presence")
                .document(currentUserID)
                .setData([
                    "isTyping": isTyping,
                    "timestamp": Timestamp(date: Date())
                ])
        }
    }
    
    private func listenForTypingIndicator() {
        let currentUserID = AuthManager.shared.currentUserID
        let otherUserIDs = conversation.participants.filter { $0 != currentUserID }
        
        guard let otherUserID = otherUserIDs.first else { return }
        
        db.collection("conversations")
            .document(conversation.id)
            .collection("presence")
            .document(otherUserID)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let data = snapshot?.data(),
                      let isTyping = data["isTyping"] as? Bool else {
                    self?.otherUserIsTyping = false
                    return
                }
                
                self?.otherUserIsTyping = isTyping
            }
    }
}
```

---

## MVP Phase 3: Group Chat (Hours 12-16)

### Group Chat Creation

**New Chat Flow:**
```swift
struct NewChatView: View {
    @State private var selectedUsers: Set<User> = []
    @State private var groupName = ""
    @State private var isGroupChat = false
    @StateObject private var viewModel = UserSearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // Toggle: 1-on-1 vs Group
                Picker("Chat Type", selection: $isGroupChat) {
                    Text("Direct Message").tag(false)
                    Text("Group Chat").tag(true)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Group name (if group)
                if isGroupChat {
                    TextField("Group Name", text: $groupName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }
                
                // User search
                TextField("Search users", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                // User list
                List(viewModel.users) { user in
                    HStack {
                        Text(user.displayName)
                        Spacer()
                        if selectedUsers.contains(user) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedUsers.contains(user) {
                            selectedUsers.remove(user)
                        } else {
                            selectedUsers.insert(user)
                        }
                    }
                }
            }
            .navigationTitle("New Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createConversation()
                    }
                    .disabled(!canCreate)
                }
            }
        }
    }
    
    private var canCreate: Bool {
        if isGroupChat {
            return selectedUsers.count >= 2 && !groupName.isEmpty
        } else {
            return selectedUsers.count == 1
        }
    }
    
    private func createConversation() {
        let currentUserID = AuthManager.shared.currentUserID
        var participants = selectedUsers.map { $0.id }
        participants.append(currentUserID)
        
        let conversation = Conversation(
            id: UUID().uuidString,
            type: isGroupChat ? .group : .oneOnOne,
            participants: participants,
            name: isGroupChat ? groupName : selectedUsers.first?.displayName,
            createdAt: Date(),
            updatedAt: Date(),
            unreadCount: [:]
        )
        
        Task {
            try? await Firestore.firestore()
                .collection("conversations")
                .document(conversation.id)
                .setData(from: conversation)
            
            dismiss()
        }
    }
}
```

### Group Chat Features

**Must Have for MVP:**
- Display all participant names in header
- Show sender name above each message bubble (in groups only)
- Support 3+ users in one conversation
- All messages properly attributed to sender

**Message Bubble for Groups:**
```swift
struct GroupMessageBubble: View {
    let message: Message
    let senderName: String
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name (for received messages in groups)
                if !isFromCurrentUser {
                    Text(senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 12)
                }
                
                Text(message.text)
                    .padding(12)
                    .background(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp.relativeTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !isFromCurrentUser { Spacer() }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}
```

---

## MVP Phase 4: Online Status & Read Receipts (Hours 16-20)

### User Presence System

**Firestore Schema:**
```
userPresence/{userID}
  - status: String ("online", "offline", "away")
  - lastSeen: Timestamp
```

**Presence Manager:**
```swift
class PresenceManager {
    static let shared = PresenceManager()
    private let db = Firestore.firestore()
    
    func updateStatus(_ status: UserStatus) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("userPresence").document(userID).setData([
            "status": status.rawValue,
            "lastSeen": Timestamp(date: Date())
        ])
    }
    
    func listenToUserPresence(userID: String, completion: @escaping (UserStatus, Date) -> Void) {
        db.collection("userPresence").document(userID)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data(),
                      let statusString = data["status"] as? String,
                      let status = UserStatus(rawValue: statusString),
                      let lastSeenTimestamp = data["lastSeen"] as? Timestamp else {
                    return
                }
                
                completion(status, lastSeenTimestamp.dateValue())
            }
    }
}

// Update status on app lifecycle
struct MessageAIApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                PresenceManager.shared.updateStatus(.online)
            case .inactive, .background:
                PresenceManager.shared.updateStatus(.away)
            @unknown default:
                break
            }
        }
    }
}
```

### Read Receipts

**Implementation (already in ChatViewModel above):**
- When user opens a chat, call `markAsRead()`
- Updates Firestore message documents: add current user to `readBy` array
- Other users see blue checkmarks when their messages are read

**Display Logic:**
```swift
// In MessageBubble
var statusIcon: some View {
    if message.readBy.count > 1 { // More than just sender
        Image(systemName: "checkmark.checkmark")
            .foregroundStyle(.blue)
    } else if message.status == .delivered {
        Image(systemName: "checkmark.checkmark")
    } else {
        Image(systemName: "checkmark")
    }
}
```

---

## MVP Phase 5: Push Notifications (Hours 20-22)

### Firebase Cloud Messaging Setup

**1. Enable FCM in Firebase Console**
- Download `GoogleService-Info.plist`
- Enable Push Notifications in Xcode capabilities
- Upload APNs certificate to Firebase

**2. Request Notification Permission:**
```swift
import UserNotifications

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    func requestAuthorization() async throws {
        let granted = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
        
        if granted {
            await registerForRemoteNotifications()
        }
    }
    
    @MainActor
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
}

// In AppDelegate
func application(_ application: UIApplication, 
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    
    // Get FCM token
    Messaging.messaging().token { token, error in
        guard let token = token else { return }
        // Save token to Firestore for this user
        self.saveFCMToken(token)
    }
}

func saveFCMToken(_ token: String) {
    guard let userID = Auth.auth().currentUser?.uid else { return }
    
    Firestore.firestore().collection("users").document(userID).updateData([
        "fcmToken": token
    ])
}
```

**3. Cloud Function to Send Notifications:**
```javascript
// Cloud Function (Node.js)
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendMessageNotification = functions.firestore
    .document('conversations/{conversationID}/messages/{messageID}')
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        const conversationID = context.params.conversationID;
        
        // Get conversation to find recipients
        const conversationDoc = await admin.firestore()
            .collection('conversations')
            .doc(conversationID)
            .get();
        
        const conversation = conversationDoc.data();
        const recipients = conversation.participants.filter(id => id !== message.senderID);
        
        // Get sender name
        const senderDoc = await admin.firestore().collection('users').doc(message.senderID).get();
        const senderName = senderDoc.data().displayName;
        
        // Get FCM tokens for recipients
        const userDocs = await admin.firestore()
            .collection('users')
            .where(admin.firestore.FieldPath.documentId(), 'in', recipients)
            .get();
        
        const tokens = userDocs.docs
            .map(doc => doc.data().fcmToken)
            .filter(token => token != null);
        
        if (tokens.length === 0) return;
        
        // Send notification
        const payload = {
            notification: {
                title: senderName,
                body: message.text,
                sound: 'default'
            },
            data: {
                conversationID: conversationID,
                type: 'new_message'
            }
        };
        
        await admin.messaging().sendToDevice(tokens, payload);
    });
```

**4. Handle Notification Tap:**
```swift
extension NotificationManager: UNUserNotificationCenterDelegate {
    // Foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // User tapped notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let conversationID = userInfo["conversationID"] as? String {
            // Navigate to chat screen
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenConversation"),
                object: conversationID
            )
        }
        
        completionHandler()
    }
}

// In main app
struct ContentView: View {
    @State private var selectedConversationID: String?
    
    var body: some View {
        TabView {
            ConversationListView(selectedConversationID: $selectedConversationID)
                .tabItem { Label("Chats", systemImage: "message") }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenConversation"))) { notification in
            if let conversationID = notification.object as? String {
                selectedConversationID = conversationID
            }
        }
    }
}
```

---

## MVP Phase 6: Media Support (Hours 22-24)

### Image Sending

**1. Image Picker:**
```swift
import PhotosUI

struct ImagePickerButton: View {
    @Binding var selectedImage: UIImage?
    @State private var showPicker = false
    
    var body: some View {
        Button {
            showPicker = true
        } label: {
            Image(systemName: "photo")
        }
        .photosPicker(isPresented: $showPicker, selection: $selectedItem)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
    
    @State private var selectedItem: PhotosPickerItem?
}
```

**2. Upload to Firebase Storage:**
```swift
import FirebaseStorage

class MediaManager {
    static let shared = MediaManager()
    private let storage = Storage.storage()
    
    func uploadImage(_ image: UIImage, conversationID: String) async throws -> String {
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw MediaError.compressionFailed
        }
        
        // Create reference
        let fileName = UUID().uuidString + ".jpg"
        let ref = storage.reference()
            .child("conversations")
            .child(conversationID)
            .child(fileName)
        
        // Upload
        let _ = try await ref.putDataAsync(imageData)
        
        // Get download URL
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}

enum MediaError: Error {
    case compressionFailed
}
```

**3. Update Message Model:**
```swift
struct Message: Codable, Identifiable {
    let id: String
    let conversationID: String
    let senderID: String
    var text: String?              // Optional now
    var mediaURL: String?          // New
    var mediaType: MediaType?      // New
    var timestamp: Date
    var status: MessageStatus
    var readBy: [String]
}

enum MediaType: String, Codable {
    case image, video
}
```

**4. Send Message with Image:**
```swift
// In ChatViewModel
func sendImageMessage(image: UIImage) {
    let messageID = UUID().uuidString
    
    // Create placeholder message
    var newMessage = Message(
        id: messageID,
        conversationID: conversation.id,
        senderID: AuthManager.shared.currentUserID,
        text: nil,
        mediaURL: nil,
        mediaType: .image,
        timestamp: Date(),
        status: .sending,
        readBy: [AuthManager.shared.currentUserID]
    )
    
    messages.append(newMessage)
    
    Task {
        do {
            // Upload image
            let url = try await MediaManager.shared.uploadImage(image, conversationID: conversation.id)
            
            // Update message with URL
            newMessage.mediaURL = url
            newMessage.status = .sent
            
            // Save to Firestore
            try db.collection("conversations")
                .document(conversation.id)
                .collection("messages")
                .document(messageID)
                .setData(from: newMessage)
            
            // Update local
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index] = newMessage
            }
            
        } catch {
            if let index = messages.firstIndex(where: { $0.id == messageID }) {
                messages[index].status = .failed
            }
        }
    }
}
```

**5. Display Image in Chat:**
```swift
struct MediaMessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if let mediaURL = message.mediaURL {
                    AsyncImage(url: URL(string: mediaURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 200, height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: 200, maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            Image(systemName: "photo.fill")
                                .foregroundStyle(.gray)
                                .frame(width: 200, height: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                if let text = message.text {
                    Text(text)
                        .padding(12)
                        .background(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(isFromCurrentUser ? .white : .primary)
                        .cornerRadius(16)
                }
            }
            
            if !isFromCurrentUser { Spacer() }
        }
        .padding(.horizontal)
    }
}
```

**6. Update Composer:**
```swift
struct MessageComposer: View {
    @Binding var messageText: String
    @State private var selectedImage: UIImage?
    let onSendText: (String) -> Void
    let onSendImage: (UIImage) -> Void
    
    var body: some View {
        VStack {
            // Image preview
            if let image = selectedImage {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                    
                    Button("Remove") {
                        selectedImage = nil
                    }
                }
                .padding(.horizontal)
            }
            
            HStack {
                ImagePickerButton(selectedImage: $selectedImage)
                
                TextField("Message", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    if let image = selectedImage {
                        onSendImage(image)
                        selectedImage = nil
                    } else if !messageText.isEmpty {
                        onSendText(messageText)
                        messageText = ""
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(messageText.isEmpty && selectedImage == nil)
            }
            .padding()
        }
    }
}
```

---

## MVP Phase 7: Testing & Bug Fixes (Final Hours)

### Critical Testing Scenarios

**1. Two-Device Real-Time Test:**
```
Setup: Two physical iPhones, both logged in with different accounts

Test 1: Basic Messaging
- Device A sends "Hello"
- Device B receives within 500ms
- Device B replies "Hi"
- Device A receives within 500ms
✅ Pass: All messages appear instantly

Test 2: Rapid Fire
- Device A sends 20 messages quickly
- Device B receives all in order
- No messages lost
✅ Pass: All messages delivered correctly

Test 3: Typing Indicators
- Device A starts typing
- Device B shows "Alice is typing..."
- Device A stops typing
- Indicator disappears on Device B
✅ Pass: Typing status works
```

**2. Offline Scenario:**
```
Setup: Device A online, Device B offline (airplane mode)

Test:
1. Device B goes offline
2. Device A sends 5 messages
3. Device B comes back online
4. Device B receives all 5 messages
5. Messages appear in correct order with timestamps

✅ Pass: Messages queued and delivered on reconnect
```

**3. App Lifecycle:**
```
Test 1: Background Message
- Device A sends message
- Device B is in background
- Device B receives push notification
- Tap notification → opens to correct chat
✅ Pass: Background notifications work

Test 2: Force Quit
- Device A force quits app
- Device B sends message
- Device A reopens app
- Message appears in chat list
✅ Pass: Messages persist after force quit

Test 3: Message During Send
- Device A starts sending message
- Before confirmation, force quit app
- Reopen app
- Message should retry and send
✅ Pass: No message loss on crash
```

**4. Group Chat:**
```
Setup: 3 devices - Alice, Bob, Charlie in one group

Test:
- Alice sends "Meeting at 3pm"
- Bob and Charlie receive
- Bob replies "Sounds good"
- All 3 see Bob's message with his name
- Charlie reacts with 👍
- All see reaction

✅ Pass: Group messaging works correctly
```

**5. Poor Network:**
```
Setup: Use Network Link Conditioner to simulate 3G

Test:
- Send 10 messages on slow connection
- All show "sending" status
- Eventually all confirm as "sent"
- No failures or duplicates

✅ Pass: Handles poor network gracefully
```

### Common Issues & Fixes

**Issue: Messages not appearing in real-time**
```swift
// Fix: Ensure listener is set up correctly
func startListening() {
    listener = db.collection("conversations")
        .document(conversation.id)
        .collection("messages")
        .order(by: "timestamp", descending: false)
        .addSnapshotListener { [weak self] snapshot, error in
            // Important: Use includeMetadataChanges to catch pending writes
            guard let documents = snapshot?.documents else { return }
            self?.messages = documents.compactMap { try? $0.data(as: Message.self) }
        }
}
```

**Issue: App crashes on force quit**
```swift
// Fix: Proper cleanup in deinit
deinit {
    listener?.remove()
    typingListener?.remove()
}
```

**Issue: Messages out of order**
```swift
// Fix: Ensure consistent timestamp source
// Use Firestore server timestamp, not device time
func sendMessage(text: String) {
    let data: [String: Any] = [
        "id": messageID,
        "conversationID": conversationID,
        "senderID": senderID,
        "text": text,
        "timestamp": FieldValue.serverTimestamp(), // Use server time
        "status": "sent"
    ]
}
```

**Issue: High Firestore read count**
```swift
// Fix: Implement pagination
func loadMoreMessages() {
    guard let oldestMessage = messages.first else { return }
    
    db.collection("conversations")
        .document(conversationID)
        .collection("messages")
        .order(by: "timestamp", descending: true)
        .start(after: [oldestMessage.timestamp])
        .limit(to: 50)
        .getDocuments { snapshot, error in
            // Append older messages
        }
}
```

---

## Post-MVP: AI Features (Days 2-5)

Now that messaging infrastructure is solid, add AI capabilities.

### AI Architecture: Contextual Features

**Design Pattern:**
All AI features are embedded contextually in the chat interface, not a separate AI chat. Users access AI through:
1. **Long-press on message** → Quick actions menu
2. **Toolbar button in chat** → Chat-level AI actions  
3. **Automatic background processing** → Proactive features

### Phase 1: Thread Summarization

**User Flow:**
1. User opens a chat with 200 unread messages
2. Banner appears: "📊 Summarize 200 messages"
3. Tap banner → Loading state
4. Summary appears as a special message bubble at top of chat

**Implementation:**
```swift
// In ChatView toolbar
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
            Button {
                viewModel.summarizeThread()
            } label: {
                Label("Summarize Conversation", systemImage: "doc.text")
            }
            
            // Other AI actions...
        } label: {
            Image(systemName: "sparkles")
        }
    }
}

// In ChatViewModel
func summarizeThread() {
    isLoadingSummary = true
    
    Task {
        do {
            // 1. Get last N messages
            let recentMessages = messages.suffix(200)
            
            // 2. Call Cloud Function
            let functions = Functions.functions()
            let callable = functions.httpsCallable("generateThreadSummary")
            let result = try await callable.call([
                "conversationID": conversation.id,
                "messageCount": 200
            ])
            
            // 3. Parse summary
            guard let data = result.data as? [String: Any],
                  let summary = data["summary"] as? String else {
                throw AIError.invalidResponse
            }
            
            // 4. Display in UI
            self.currentSummary = summary
            self.showSummary = true
            
        } catch {
            self.summaryError = error.localizedDescription
        }
        
        isLoadingSummary = false
    }
}
```

**Cloud Function:**
```javascript
exports.generateThreadSummary = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }
    
    const { conversationID, messageCount } = data;
    const userID = context.auth.uid;
    
    // Verify user is participant
    const conversationDoc = await admin.firestore()
        .collection('conversations')
        .doc(conversationID)
        .get();
    
    const conversation = conversationDoc.data();
    if (!conversation.participants.includes(userID)) {
        throw new functions.https.HttpsError('permission-denied', 'Not a participant');
    }
    
    // Check cache first
    const cacheKey = `summary_${conversationID}_${messageCount}`;
    const cacheDoc = await admin.firestore()
        .collection('aiCache')
        .doc(cacheKey)
        .get();
    
    if (cacheDoc.exists) {
        const cached = cacheDoc.data();
        const ageMinutes = (Date.now() - cached.timestamp) / 1000 / 60;
        
        // Return cached if less than 1 hour old
        if (ageMinutes < 60) {
            return { summary: cached.summary, cached: true };
        }
    }
    
    // Fetch messages
    const messagesSnapshot = await admin.firestore()
        .collection('conversations')
        .doc(conversationID)
        .collection('messages')
        .orderBy('timestamp', 'desc')
        .limit(messageCount)
        .get();
    
    const messages = messagesSnapshot.docs.map(doc => ({
        sender: doc.data().senderID,
        text: doc.data().text,
        timestamp: doc.data().timestamp.toDate()
    }));
    
    // Call Claude API
    const Anthropic = require('@anthropic-ai/sdk');
    const anthropic = new Anthropic({
        apiKey: functions.config().anthropic.key
    });
    
    const message = await anthropic.messages.create({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 1024,
        messages: [{
            role: 'user',
            content: `You are analyzing a work team conversation. Provide a concise summary focusing on:
            
1. Key decisions made
2. Problems or blockers discussed
3. Open questions
4. Action items mentioned
5. Overall tone (urgent, collaborative, casual, etc.)

Format as structured text with emoji indicators.

Conversation (${messages.length} messages):
${messages.map(m => `[${m.timestamp}] ${m.sender}: ${m.text}`).join('\n')}

Provide summary:`
        }]
    });
    
    const summary = message.content[0].text;
    
    // Cache result
    await admin.firestore()
        .collection('aiCache')
        .doc(cacheKey)
        .set({
            summary: summary,
            timestamp: Date.now(),
            conversationID: conversationID
        });
    
    return { summary: summary, cached: false };
});
```

**UI Display:**
```swift
struct SummaryView: View {
    let summary: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(summary)
                    .padding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// Show as sheet
.sheet(isPresented: $viewModel.showSummary) {
    SummaryView(summary: viewModel.currentSummary)
}
```

### Phase 2: Action Item Extraction

**User Flow:**
1. User taps AI toolbar button
2. Select "Extract Action Items"
3. See list of all tasks mentioned in conversation
4. Tap action item → jump to message context
5. Mark as done or add to Apple Reminders

**Implementation:**
```swift
struct ActionItem: Codable, Identifiable {
    let id: String
    var task: String
    var assignee: String?
    var deadline: Date?
    var status: TaskStatus
    var messageID: String  // Link back to original message
    var context: String    // Surrounding text
}

enum TaskStatus: String, Codable {
    case pending, inProgress, completed
}

// In ChatViewModel
func extractActionItems() {
    Task {
        let functions = Functions.functions()
        let callable = functions.httpsCallable("extractActionItems")
        
        let result = try await callable.call([
            "conversationID": conversation.id,
            "dateRange": "7d"  // Last 7 days
        ])
        
        guard let data = result.data as? [String: Any],
              let itemsJSON = data["actionItems"] as? [[String: Any]] else {
            return
        }
        
        self.actionItems = itemsJSON.compactMap { dict in
            try? JSONDecoder().decode(ActionItem.self, from: JSONSerialization.data(withJSONObject: dict))
        }
        
        self.showActionItems = true
    }
}
```

**Cloud Function with Tool Use:**
```javascript
exports.extractActionItems = functions.https.onCall(async (data, context) => {
    // Auth check...
    
    const { conversationID, dateRange } = data;
    
    // Fetch recent messages
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 7);
    
    const messagesSnapshot = await admin.firestore()
        .collection('conversations')
        .doc(conversationID)
        .collection('messages')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(cutoffDate))
        .orderBy('timestamp', 'asc')
        .get();
    
    const messages = messagesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
    }));
    
    // Call Claude with tool use
    const response = await anthropic.messages.create({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 2048,
        tools: [{
            name: 'extract_action_items',
            description: 'Extract action items and tasks from conversation',
            input_schema: {
                type: 'object',
                properties: {
                    action_items: {
                        type: 'array',
                        items: {
                            type: 'object',
                            properties: {
                                task: { type: 'string', description: 'The task to be done' },
                                assignee: { type: 'string', description: 'Person assigned (name or "unassigned")' },
                                deadline: { type: 'string', description: 'Deadline if mentioned (ISO date or null)' },
                                priority: { type: 'string', enum: ['low', 'medium', 'high'] },
                                messageID: { type: 'string', description: 'ID of message containing this task' },
                                context: { type: 'string', description: 'Brief context (1 sentence)' }
                            },
                            required: ['task', 'messageID', 'context']
                        }
                    }
                },
                required: ['action_items']
            }
        }],
        messages: [{
            role: 'user',
            content: `Extract all action items, tasks, and TODOs from this work conversation.

Conversation:
${messages.map(m => `[${m.id}] ${m.senderID}: ${m.text}`).join('\n')}

Identify tasks where someone:
- Explicitly says they'll do something ("I'll update the docs")
- Is assigned a task ("Can you review the PR?")
- Mentions a TODO or action item
- Sets a deadline or due date

Use the extract_action_items tool.`
        }]
    });
    
    // Parse tool use response
    const toolUse = response.content.find(c => c.type === 'tool_use');
    const actionItems = toolUse?.input?.action_items || [];
    
    return { actionItems };
});
```

**Action Items List UI:**
```swift
struct ActionItemsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.actionItems) { item in
                    ActionItemRow(item: item, onToggle: {
                        viewModel.toggleActionItem(item)
                    }, onTap: {
                        viewModel.jumpToMessage(item.messageID)
                        dismiss()
                    })
                }
            }
            .navigationTitle("Action Items")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ActionItemRow: View {
    let item: ActionItem
    let onToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: item.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.status == .completed ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.task)
                    .strikethrough(item.status == .completed)
                
                HStack {
                    if let assignee = item.assignee {
                        Text(assignee)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if let deadline = item.deadline {
                        Text(deadline.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        onTap()
                    } label: {
                        Image(systemName: "arrow.right.circle")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
```

### Phase 3: Smart Search (Semantic + Keyword)

**User Flow:**
1. User taps search icon in chat
2. Types query: "Q4 budget discussion"
3. Results show both exact matches + semantically similar messages
4. Tap result → jump to message in context

**Implementation requires Pinecone vector database:**

**Setup Pinecone:**
```javascript
// In Cloud Functions
const { Pinecone } = require('@pinecone-database/pinecone');

const pinecone = new Pinecone({
    apiKey: functions.config().pinecone.key
});

const index = pinecone.index('message-embeddings');

// Function to embed messages (triggered on new message)
exports.embedMessage = functions.firestore
    .document('conversations/{convID}/messages/{msgID}')
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        const messageID = context.params.msgID;
        const conversationID = context.params.convID;
        
        // Get embedding from OpenAI
        const openai = new OpenAI({ apiKey: functions.config().openai.key });
        
        const embeddingResponse = await openai.embeddings.create({
            model: 'text-embedding-3-small',
            input: message.text
        });
        
        const embedding = embeddingResponse.data[0].embedding;
        
        // Store in Pinecone
        await index.upsert([{
            id: messageID,
            values: embedding,
            metadata: {
                conversationID: conversationID,
                senderID: message.senderID,
                text: message.text,
                timestamp: message.timestamp.toMillis()
            }
        }]);
    });

// Search function
exports.searchMessages = functions.https.onCall(async (data, context) => {
    const { query, conversationID } = data;
    
    // Get query embedding
    const embeddingResponse = await openai.embeddings.create({
        model: 'text-embedding-3-small',
        input: query
    });
    
    const queryEmbedding = embeddingResponse.data[0].embedding;
    
    // Search Pinecone
    const searchResults = await index.query({
        vector: queryEmbedding,
        topK: 10,
        filter: { conversationID: conversationID },
        includeMetadata: true
    });
    
    // Also do keyword search in Firestore
    const keywordResults = await admin.firestore()
        .collection('conversations')
        .doc(conversationID)
        .collection('messages')
        .where('text', '>=', query)
        .where('text', '<=', query + '\uf8ff')
        .limit(5)
        .get();
    
    // Merge and rank results
    const combined = mergeResults(searchResults.matches, keywordResults.docs);
    
    return { results: combined };
});
```

**Search UI:**
```swift
struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    @State private var query = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search messages", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onSubmit {
                        viewModel.search(query: query)
                    }
                
                if viewModel.isSearching {
                    ProgressView()
                } else {
                    List(viewModel.results) { result in
                        SearchResultRow(result: result) {
                            // Jump to message
                        }
                    }
                }
            }
            .navigationTitle("Search")
        }
    }
}
```

### Phase 4: Priority Message Detection

**Background Processing:**
```javascript
// Scheduled function - runs every 30 minutes
exports.detectPriorityMessages = functions.pubsub
    .schedule('every 30 minutes')
    .onRun(async (context) => {
        // Get all users
        const usersSnapshot = await admin.firestore().collection('users').get();
        
        for (const userDoc of usersSnapshot.docs) {
            const userID = userDoc.id;
            
            // Get user's conversations
            const conversationsSnapshot = await admin.firestore()
                .collection('conversations')
                .where('participants', 'array-contains', userID)
                .get();
            
            for (const convDoc of conversationsSnapshot.docs) {
                const conversationID = convDoc.id;
                
                // Get unread messages
                const messagesSnapshot = await admin.firestore()
                    .collection('conversations')
                    .doc(conversationID)
                    .collection('messages')
                    .where('readBy', 'not-in', [[userID]])
                    .orderBy('timestamp', 'desc')
                    .limit(50)
                    .get();
                
                const messages = messagesSnapshot.docs.map(d => d.data());
                
                // Score each message
                const priorityMessages = await scoreMessages(messages, userID);
                
                // Update Firestore
                if (priorityMessages.length > 0) {
                    await admin.firestore()
                        .collection('userPriority')
                        .doc(userID)
                        .set({
                            [conversationID]: {
                                count: priorityMessages.length,
                                messages: priorityMessages.map(m => m.id)
                            }
                        }, { merge: true });
                }
            }
        }
    });

async function scoreMessages(messages, userID) {
    // Call Claude to score priority
    const response = await anthropic.messages.create({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 1024,
        messages: [{
            role: 'user',
            content: `You are analyzing messages for user ${userID}. Score each message for priority (0-10).

High priority indicators:
- Direct @mentions of the user
- Questions directed at the user
- Urgent keywords ("ASAP", "urgent", "blocker", "deadline")
- Decision requests ("What do you think?", "Can you approve?")
- Frustrated tone
- Rapid message velocity (many messages in short time)

Messages:
${messages.map((m, i) => `[${i}] ${m.senderID}: ${m.text}`).join('\n')}

Return JSON array: [{"index": 0, "score": 8, "reason": "Direct question to user"}]`
        }]
    });
    
    // Parse scores and filter high priority (score > 6)
    const scores = JSON.parse(response.content[0].text);
    return messages.filter((_, i) => scores[i]?.score > 6);
}
```

**Display Priority Badge:**
```swift
// In ConversationRow
if let priorityCount = conversation.priorityCount, priorityCount > 0 {
    HStack {
        Image(systemName: "exclamationmark.circle.fill")
            .foregroundStyle(.red)
        Text("\(priorityCount)")
            .font(.caption)
    }
}
```

**Priority Inbox View:**
```swift
struct PriorityInboxView: View {
    @StateObject private var viewModel = PriorityViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.priorityConversations) { conversation in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(conversation.name ?? "Unknown")
                            .font(.headline)
                        
                        ForEach(conversation.priorityMessages) { message in
                            PriorityMessageRow(message: message)
                        }
                    }
                }
            }
            .navigationTitle("Priority")
        }
    }
}
```

### Phase 5: Decision Tracking

**Auto-Detection:**
```javascript
exports.trackDecisions = functions.firestore
    .document('conversations/{convID}/messages/{msgID}')
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        const conversationID = context.params.convID;
        
        // Check if message contains decision language
        const decisionPatterns = [
            'let\'s go with',
            'we decided',
            'decision:',
            'agreed',
            'we\'ll move forward',
            'final decision'
        ];
        
        const lowerText = message.text.toLowerCase();
        const mightBeDecision = decisionPatterns.some(pattern => 
            lowerText.includes(pattern)
        );
        
        if (!mightBeDecision) return;
        
        // Get surrounding context (5 messages before)
        const contextSnapshot = await admin.firestore()
            .collection('conversations')
            .doc(conversationID)
            .collection('messages')
            .where('timestamp', '<', message.timestamp)
            .orderBy('timestamp', 'desc')
            .limit(5)
            .get();
        
        const context = contextSnapshot.docs.map(d => d.data());
        
        // Call Claude to extract decision
        const response = await anthropic.messages.create({
            model: 'claude-3-5-sonnet-20241022',
            max_tokens: 1024,
            tools: [{
                name: 'extract_decision',
                description: 'Extract a decision from conversation',
                input_schema: {
                    type: 'object',
                    properties: {
                        decision: { type: 'string', description: 'The decision made' },
                        reasoning: { type: 'string', description: 'Why this decision was made' },
                        alternatives: { 
                            type: 'array', 
                            items: { type: 'string' },
                            description: 'Other options that were considered'
                        },
                        participants: {
                            type: 'array',
                            items: { type: 'string' },
                            description: 'Who was involved in the decision'
                        }
                    },
                    required: ['decision']
                }
            }],
            messages: [{
                role: 'user',
                content: `Context messages:
${context.map(m => `${m.senderID}: ${m.text}`).join('\n')}

Decision message:
${message.senderID}: ${message.text}

Extract the decision that was made using the extract_decision tool. If no clear decision, return null.`
            }]
        });
        
        const toolUse = response.content.find(c => c.type === 'tool_use');
        if (!toolUse?.input?.decision) return;
        
        // Save decision
        await admin.firestore()
            .collection('conversations')
            .doc(conversationID)
            .collection('decisions')
            .add({
                ...toolUse.input,
                messageID: context.params.msgID,
                timestamp: message.timestamp,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
    });
```

**Decisions Timeline UI:**
```swift
struct DecisionsView: View {
    @StateObject private var viewModel: DecisionsViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.decisions) { decision in
                        DecisionCard(decision: decision) {
                            viewModel.jumpToDecision(decision)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Decisions")
        }
    }
}

struct DecisionCard: View {
    let decision: Decision
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(decision.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: onTap) {
                    Image(systemName: "arrow.right.circle")
                }
            }
            
            Text(decision.decision)
                .font(.headline)
            
            if let reasoning = decision.reasoning {
                Text(reasoning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if !decision.alternatives.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alternatives considered:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(decision.alternatives, id: \.self) { alt in
                        Text("• \(alt)")
                            .font(.caption)
                    }
                }
            }
            
            if !decision.participants.isEmpty {
                HStack {
                    ForEach(decision.participants.prefix(3), id: \.self) { participant in
                        Text(participant)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
```

---

## Advanced AI: Proactive Assistant (Option B)

**Capability:** Automatically detects scheduling needs and suggests meeting times, handles conflicts, and coordinates across time zones.

### Architecture

**Proactive Agent runs in background:**
1. Monitors conversation for scheduling language
2. Analyzes participant availability
3. Suggests optimal meeting times
4. Sends proactive suggestions to chat

### Implementation

**1. Trigger Detection:**
```javascript
exports.detectSchedulingIntent = functions.firestore
    .document('conversations/{convID}/messages/{msgID}')
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        const conversationID = context.params.convID;
        
        // Detect scheduling keywords
        const schedulingPatterns = [
            'let\'s meet',
            'schedule a call',
            'find time',
            'when are you free',
            'meeting',
            'sync up',
            'catch up'
        ];
        
        const lowerText = message.text.toLowerCase();
        const isScheduling = schedulingPatterns.some(p => lowerText.includes(p));
        
        if (!isScheduling) return;
        
        // Get conversation context
        const contextSnapshot = await admin.firestore()
            .collection('conversations')
            .doc(conversationID)
            .collection('messages')
            .orderBy('timestamp', 'desc')
            .limit(10)
            .get();
        
        const context = contextSnapshot.docs.map(d => d.data());
        
        // Analyze intent with Claude
        const response = await anthropic.messages.create({
            model: 'claude-3-5-sonnet-20241022',
            max_tokens: 1024,
            tools: [{
                name: 'analyze_scheduling_intent',
                description: 'Analyze if users are trying to schedule a meeting',
                input_schema: {
                    type: 'object',
                    properties: {
                        isScheduling: { type: 'boolean' },
                        meetingType: { 
                            type: 'string',
                            enum: ['one_on_one', 'team_meeting', 'informal_catchup']
                        },
                        duration: { 
                            type: 'number',
                            description: 'Estimated duration in minutes'
                        },
                        urgency: {
                            type: 'string',
                            enum: ['today', 'this_week', 'next_week', 'flexible']
                        },
                        participants: {
                            type: 'array',
                            items: { type: 'string' }
                        }
                    },
                    required: ['isScheduling']
                }
            }],
            messages: [{
                role: 'user',
                content: `Analyze this conversation to determine if people are trying to schedule a meeting.

${context.map(m => `${m.senderID}: ${m.text}`).join('\n')}

Use the analyze_scheduling_intent tool.`
            }]
        });
        
        const toolUse = response.content.find(c => c.type === 'tool_use');
        if (!toolUse?.input?.isScheduling) return;
        
        // Trigger proactive assistant
        await triggerSchedulingAssistant(conversationID, toolUse.input);
    });
```

**2. Proactive Scheduling Agent:**
```javascript
async function triggerSchedulingAssistant(conversationID, intent) {
    // Get conversation participants
    const convDoc = await admin.firestore()
        .collection('conversations')
        .doc(conversationID)
        .get();
    
    const conversation = convDoc.data();
    const participants = conversation.participants;
    
    // Simulate availability check (in production, integrate with Calendar API)
    const availability = await checkAvailability(participants, intent.urgency);
    
    // Find optimal time slots
    const suggestions = await findOptimalTimes(availability, intent);
    
    // Send proactive message to chat
    const assistantMessage = {
        id: admin.firestore().collection('_').doc().id,
        conversationID: conversationID,
        senderID: 'assistant',
        text: formatSchedulingSuggestion(suggestions, intent),
        timestamp: admin.firestore.Timestamp.now(),
        status: 'sent',
        readBy: [],
        isAssistantMessage: true,
        suggestedTimes: suggestions
    };
    
    await admin.firestore()
        .collection('conversations')
        .doc(conversationID)
        .collection('messages')
        .add(assistantMessage);
}

function formatSchedulingSuggestion(suggestions, intent) {
    return `🤖 I noticed you're trying to schedule a ${intent.meetingType}. Here are some times that work for everyone:

${suggestions.map((s, i) => 
    `${i + 1}. ${s.date} at ${s.time} (${s.duration} min)
    Available: ${s.available.join(', ')}
    ${s.conflicts.length > 0 ? `⚠️ Conflicts: ${s.conflicts.join(', ')}` : '✅ No conflicts'}`
).join('\n\n')}

React with 1️⃣, 2️⃣, or 3️⃣ to vote on a time!`;
}

async function findOptimalTimes(availability, intent) {
    // Use Claude to analyze complex availability
    const response = await anthropic.messages.create({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 2048,
        messages: [{
            role: 'user',
            content: `Given this availability data, suggest 3 optimal meeting times.

Availability:
${JSON.stringify(availability, null, 2)}

Requirements:
- Duration: ${intent.duration} minutes
- Urgency: ${intent.urgency}
- Meeting type: ${intent.meetingType}

Consider:
- Time zone differences
- Work hours (9am-6pm local time)
- Lunch breaks (12pm-1pm)
- Minimize conflicts

Return 3 suggestions as JSON array.`
        }]
    });
    
    return JSON.parse(response.content[0].text);
}
```

**3. UI for Assistant Messages:**
```swift
struct AssistantMessageBubble: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("MessageBot")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            Text(message.text)
                .font(.body)
            
            // Interactive buttons for suggested times
            if let suggestions = message.suggestedTimes {
                VStack(spacing: 8) {
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        Button {
                            // Vote for this time
                            voteForTime(suggestion)
                        } label: {
                            HStack {
                                Text("\(index + 1)️⃣")
                                VStack(alignment: .leading) {
                                    Text(suggestion.date)
                                        .fontWeight(.semibold)
                                    Text("\(suggestion.available.count) available")
                                        .font(.caption)
                                }
                                Spacer()
                                if suggestion.conflicts.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding()
                            .background(.purple.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.purple.opacity(0.05))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
```

**4. Conflict Detection:**
```javascript
async function detectSchedulingConflict(userID, proposedTime) {
    // Check if user already has commitment at this time
    const existingMeetings = await getUserMeetings(userID, proposedTime);
    
    if (existingMeetings.length > 0) {
        // Proactively warn in conversation
        const warningMessage = {
            senderID: 'assistant',
            text: `⚠️ @${userID} has a conflict at ${proposedTime}. Would you like me to suggest alternative times?`,
            timestamp: admin.firestore.Timestamp.now(),
            isAssistantMessage: true
        };
        
        // Send to relevant conversations
        // ...
    }
}
```

---

## Deployment & Testing

### Firebase Configuration

**1. Firebase Project Setup:**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize project
firebase init

# Select:
# - Firestore
# - Functions
# - Storage
# - Hosting
```

**2. Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users
    match /users/{userID} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userID;
    }
    
    // Conversations
    match /conversations/{conversationID} {
      allow read: if request.auth.uid in resource.data.participants;
      allow create: if request.auth.uid in request.resource.data.participants;
      allow update: if request.auth.uid in resource.data.participants;
      
      // Messages subcollection
      match /messages/{messageID} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationID)).data.participants;
        allow create: if request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationID)).data.participants
                      && request.auth.uid == request.resource.data.senderID;
      }
      
      // Decisions subcollection
      match /decisions/{decisionID} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationID)).data.participants;
      }
    }
    
    // User presence
    match /userPresence/{userID} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userID;
    }
    
    // AI Cache (server only)
    match /aiCache/{cacheID} {
      allow read: if false;
      allow write: if false;
    }
  }
}
```

**3. Storage Security Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /conversations/{conversationID}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024  // 5MB limit
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

### Xcode Project Setup

**1. Install Dependencies:**
```swift
// Package.swift or SPM in Xcode
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
]

// Add to target:
- FirebaseAuth
- FirebaseFirestore
- FirebaseStorage
- FirebaseMessaging
- FirebaseFunctions
```

**2. Configure Firebase:**
```swift
// AppDelegate or App struct
import Firebase

@main
struct MessageAIApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**3. Enable Background Modes:**
- Open Xcode project settings
- Select target → Signing & Capabilities
- Add Background Modes capability
- Check: "Background fetch" and "Remote notifications"

### TestFlight Deployment

**1. Archive Build:**
```
Xcode → Product → Archive
Wait for build to complete
Window → Organizer opens automatically
```

**2. Upload to App Store Connect:**
```
Select archive → Distribute App
Select "App Store Connect"
Upload
Wait for processing (~10 minutes)
```

**3. Create TestFlight Build:**
```
Go to App Store Connect
Select app → TestFlight tab
Select build
Add internal testers
Send invitations
```

**4. Share TestFlight Link:**
```
Public Link: Enable public link in TestFlight
Copy link to share with testers
```

---

## Performance Optimization

### Message Loading

**Pagination:**
```swift
class ChatViewModel: ObservableObject {
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 50
    
    func loadMoreMessages() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        var query = db.collection("conversations")
            .document(conversation.id)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { [weak self] snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            let newMessages = documents.compactMap { try? $0.data(as: Message.self) }
            self?.messages.insert(contentsOf: newMessages, at: 0)
            self?.lastDocument = documents.last
            self?.isLoadingMore = false
        }
    }
}
```

### Image Optimization

**Compression:**
```swift
extension UIImage {
    func compressed(maxSizeKB: Int = 500) -> Data? {
        var compression: CGFloat = 1.0
        var imageData = self.jpegData(compressionQuality: compression)
        
        while let data = imageData, data.count > maxSizeKB * 1024 && compression > 0.1 {
            compression -= 0.1
            imageData = self.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
}
```

### Caching

**SDWebImage for remote images:**
```swift
// Add to Package Dependencies
.package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI", from: "2.0.0")

// Use in views
import SDWebImageSwiftUI

WebImage(url: URL(string: message.mediaURL))
    .resizable()
    .placeholder { ProgressView() }
    .indicator(.activity)
    .transition(.fade)
    .aspectRatio(contentMode: .fill)
    .frame(maxWidth: 200, maxHeight: 200)
    .clipped()
```

### AI Cost Optimization

**Response Caching:**
```javascript
// Cache strategy: 1 hour for summaries, 24 hours for decisions
async function getCachedOrGenerate(cacheKey, ttlMinutes, generateFn) {
    const cacheDoc = await admin.firestore()
        .collection('aiCache')
        .doc(cacheKey)
        .get();
    
    if (cacheDoc.exists) {
        const cached = cacheDoc.data();
        const ageMinutes = (Date.now() - cached.timestamp) / 1000 / 60;
        
        if (ageMinutes < ttlMinutes) {
            return { data: cached.data, cached: true };
        }
    }
    
    // Generate new
    const result = await generateFn();
    
    // Cache it
    await admin.firestore()
        .collection('aiCache')
        .doc(cacheKey)
        .set({
            data: result,
            timestamp: Date.now()
        });
    
    return { data: result, cached: false };
}
```

**Rate Limiting:**
```javascript
// Limit AI requests per user
async function checkRateLimit(userID, featureType) {
    const rateLimitDoc = await admin.firestore()
        .collection('rateLimits')
        .doc(userID)
        .get();
    
    const limits = rateLimitDoc.data() || {};
    const today = new Date().toDateString();
    
    if (!limits[today]) {
        limits[today] = {};
    }
    
    const count = limits[today][featureType] || 0;
    
    // Max 10 summaries per day
    if (featureType === 'summary' && count >= 10) {
        throw new Error('Daily limit reached');
    }
    
    // Update count
    limits[today][featureType] = count + 1;
    
    await admin.firestore()
        .collection('rateLimits')
        .doc(userID)
        .set(limits);
}
```

---

## Success Metrics & Monitoring

### Technical Metrics

**Track in Firebase Analytics:**
```swift
import FirebaseAnalytics

// Message delivery
Analytics.logEvent("message_sent", parameters: [
    "conversation_type": conversation.type.rawValue,
    "has_media": message.mediaURL != nil
])

// AI feature usage
Analytics.logEvent("ai_feature_used", parameters: [
    "feature_type": "summary",
    "message_count": 200,
    "cached": false
])

// Performance
Analytics.logEvent("message_load_time", parameters: [
    "duration_ms": loadTime,
    "message_count": messages.count
])
```

### Error Tracking

**Crashlytics:**
```swift
import FirebaseCrashlytics

// Log custom errors
func sendMessage(text: String) {
    Task {
        do {
            try await messageSender.send(text)
        } catch {
            Crashlytics.crashlytics().record(error: error)
            Crashlytics.crashlytics().log("Failed to send message: \(text)")
        }
    }
}
```

---

## Final Submission Checklist

### Code & Documentation
- [ ] GitHub repository with clear README
- [ ] Setup instructions (Firebase config, API keys)
- [ ] Environment variables documented
- [ ] Code comments on complex logic
- [ ] SwiftUI previews for main screens

### Demo Video (5-7 minutes)
- [ ] Real-time messaging between 2 devices (30 sec)
- [ ] Offline scenario (go offline, receive messages, reconnect) (1 min)
- [ ] Group chat with 3+ participants (1 min)
- [ ] App lifecycle (background, force quit) (30 sec)
- [ ] All 5 AI features with real examples (2-3 min)
- [ ] Proactive Assistant demo (1 min)

### Deployment
- [ ] TestFlight build uploaded
- [ ] TestFlight public link generated
- [ ] Test installation on fresh device
- [ ] Firebase backend deployed and working

### Persona Document
- [ ] Remote Team Professional persona explained
- [ ] Pain points addressed
- [ ] Each AI feature mapped to specific problem
- [ ] Technical decisions justified
- [ ] Screenshots or diagrams included

### Social Post
- [ ] 2-3 sentence description
- [ ] Key features highlighted
- [ ] Demo video or GIF attached
- [ ] @GauntletAI tagged
- [ ] Link to GitHub repo

---

## Troubleshooting Guide

### Common Issues

**Issue: "Firebase not configured"**
```
Solution: Ensure GoogleService-Info.plist is in Xcode project
- Download from Firebase Console
- Drag to Xcode (Copy if needed)
- Verify in Bundle Resources
```

**Issue: "Push notifications not working"**
```
Solution: Check APNs certificate
- Firebase Console → Project Settings → Cloud Messaging
- Upload APNs Authentication Key or Certificate
- Enable Push Notifications in Xcode Capabilities
```

**Issue: "Messages not syncing in real-time"**
```
Solution: Check Firestore listener
- Verify listener is active (not removed prematurely)
- Check Firestore security rules
- Test Firestore connection in Firebase Console
```

**Issue: "AI functions timing out"**
```
Solution: Increase Cloud Function timeout
// In functions/index.js
exports.generateSummary = functions
    .runWith({ timeoutSeconds: 300 })  // 5 minutes
    .https.onCall(async (data, context) => { ... });
```

**Issue: "High Firebase costs"**
```
Solution: Optimize queries
- Use pagination (limit + startAfter)
- Cache AI responses
- Use indexes for common queries
- Monitor usage in Firebase Console
```

---

## Cost Breakdown (1000 Active Users/Month)

### Firebase
- **Firestore:**
  - Reads: 1M reads × $0.06/100K = $0.60
  - Writes: 500K writes × $0.18/100K = $0.90
  - Storage: 10GB × $0.18/GB = $1.80
  - **Subtotal: $3.30**

- **Storage:**
  - 50GB images × $0.026/GB = $1.30
  - **Subtotal: $1.30**

- **Cloud Functions:**
  - 100K invocations × $0.40/M = $0.04
  - **Subtotal: $0.04**

- **FCM:** Free

### AI Services
- **Claude API:**
  - 50 requests/user/month = 50K requests
  - Average 1K tokens/request
  - $3 per million input tokens
  - **Cost: $150**

- **Pinecone:**
  - 1M vectors × $0.096/1M = $0.096
  - **Cost: $70/month (starter plan)**

### Total Monthly Cost
**~$225 for 1000 users = $0.23/user/month**

### Ways to Reduce Costs
1. Cache AI responses (1-hour TTL saves ~60%)
2. Rate limit AI features (10/day per user)
3. Use cheaper models for simple tasks
4. Batch embeddings to reduce Pinecone costs
5. Implement lazy loading for messages

---

## Next Steps After MVP

### Week 2 Enhancements
- Voice messages
- Video support
- Message forwarding
- Starred/pinned messages
- Dark mode
- Custom notification sounds

### Week 3 Advanced Features
- End-to-end encryption
- Message scheduling
- AI conversation insights dashboard
- Team analytics
- Integration with calendar apps
- Slack/Discord import

### Week 4 Polish
- Onboarding flow
- App Store optimization
- Performance improvements
- A/B testing AI prompts
- User feedback collection
- Beta testing with real teams

---

## Resources

### Documentation
- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Anthropic Claude API](https://docs.anthropic.com/)
- [Pinecone Vector Database](https://docs.pinecone.io/)

### Example Code
- [Firebase Samples](https://github.com/firebase/quickstart-ios)
- [SwiftUI Chat Examples](https://github.com/topics/chat-app-swiftui)

### Tools
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite) - Local testing
- [Network Link Conditioner](https://developer.apple.com/download/all/) - Network testing
- [Postman](https://www.postman.com/) - API testing

---

## Conclusion

This PRD provides a complete roadmap for building MessageAI in one week. The MVP focuses exclusively on core messaging reliability - the foundation everything else builds on. Only after messaging is rock-solid do you add AI features that genuinely help remote teams work better together.

Key Success Factors:
1. **MVP First:** Get messaging working perfectly before touching AI
2. **Test on Hardware:** Simulators lie - use real devices
3. **Build Vertically:** Complete one feature before starting the next
4. **Focus on UX:** AI features must feel natural, not gimmicky
5. **Monitor Costs:** Cache aggressively, rate limit appropriately

Remember: A reliable messaging app with useful AI beats a feature-rich app with flaky delivery. Build something remote teams would actually choose over Slack.

Good luck! 🚀