# Offline Handling & Badge Count Guide

## 🔢 Badge Count Feature

### Dynamic Badge Count
- **Before**: Always showed "1" ❌
- **After**: Shows actual unread message count ✅

### Implementation
```swift
// Calculates total unread across all conversations
private func getTotalUnreadCount(for userID: String) async -> Int {
    // Fetches all conversations
    // Sums up unreadCount[userID] from each
    // Returns total (capped at 99 for display)
}
```

### Badge Behavior
- **1 unread message**: Badge shows "1"
- **5 unread messages**: Badge shows "5"
- **100+ unread messages**: Badge shows "99" (iOS convention)
- **When app opens**: Badge clears automatically

### Console Output
```
🔢 Total unread messages for alice-123: 7
🔢 Setting badge count to: 7
```

---

## 📡 Offline Handling

### How It Works

#### 1. **Network Monitoring**
```swift
NetworkMonitor.shared.startMonitoring()
```
- Monitors WiFi/cellular connectivity
- Updates `isConnected` property in real-time
- Shows orange banner when offline

#### 2. **Outgoing Messages (Sending)**

**When Online** ✅:
```
User sends message
   ↓
MessageService.sendMessage()
   ↓
Saves to Firestore immediately
   ↓
Message appears instantly (optimistic UI)
```

**When Offline** 📴:
```
User sends message
   ↓
MessageService tries to send
   ↓
Fails (no internet)
   ↓
Message saved to LocalStorageManager
   ↓
Shown in UI with "sending" status
   ↓
When reconnected:
   ↓
YaipApp.syncPendingMessages()
   ↓
Retries sending all pending messages
   ↓
Updates to "sent" status
```

#### 3. **Incoming Messages (Receiving)**

**Firestore Real-time Listeners**:
- Automatically reconnect when back online
- Queue missed messages
- Deliver all when reconnected

**Flow**:
```
Phone offline 📴
   ↓
Bob sends 3 messages to Alice
   ↓
Messages stored in Firestore
   ↓
Alice's phone comes online 📶
   ↓
Firestore listener reconnects automatically
   ↓
All 3 messages delivered at once
   ↓
Notifications triggered for each
```

---

## 🎨 User Experience

### Offline Indicator
```
┌────────────────────────────────────┐
│ 📶❌ Offline - Messages will send  │ ← Orange banner
│     when reconnected               │
├────────────────────────────────────┤
│ 👤 Alice                           │
├────────────────────────────────────┤
│ Conversations...                   │
```

### Message Status Icons
- ⏰ **Clock**: Sending (queued offline)
- ✓ **Single check**: Sent (delivered to server)
- ✓✓ **Double check**: Delivered
- ✓✓ **Blue double check**: Read

---

## 🔄 Sync Strategy

### When App Becomes Active
```swift
case .active:
    // 1. Clear badge
    LocalNotificationManager.shared.clearBadge()
    
    // 2. Sync pending messages
    await syncPendingMessages()
```

### syncPendingMessages()
```swift
1. Get all pending messages from local storage
2. For each message:
   - Try to send to Firestore
   - If success: Mark as synced
   - If fail: Keep in queue
3. Retry on next activation
```

---

## 📱 Scenarios

### Scenario 1: Send Message While Offline

**User Action**:
1. Phone loses WiFi
2. User types "Hello"
3. Taps send

**App Behavior**:
```
✅ Message appears in chat immediately (optimistic UI)
⏰ Shows "sending" icon
💾 Saved to local storage
📴 Orange "Offline" banner visible

[User closes app]

📶 Phone reconnects to WiFi
📱 User opens app
🔄 App syncs pending messages
✅ Message sent to Firestore
✓ Icon changes to "sent"
```

---

### Scenario 2: Receive Messages While Offline

**User Action**:
1. Alice's phone offline
2. Bob sends 3 messages
3. Alice reconnects

**App Behavior**:
```
📴 Alice offline - listeners paused
💬 Bob sends: "Hey", "How are you?", "Call me"
💾 Messages stored in Firestore

📶 Alice reconnects
🔄 Firestore listeners reconnect automatically
📬 All 3 messages delivered:
   Message 1: "Hey"
   Message 2: "How are you?"
   Message 3: "Call me"
🔔 3 notifications triggered
🔢 Badge shows "3"
```

---

### Scenario 3: Simultaneous Offline on Both Sides

**Setup**:
- Both Alice and Bob offline
- Each sends messages

**Flow**:
```
Alice (offline) → "Message 1" → Local storage
Bob (offline) → "Message A" → Local storage

[Both reconnect]

Alice's phone:
   🔄 Syncs "Message 1" to Firestore
   📬 Receives "Message A" from Firestore

Bob's phone:
   🔄 Syncs "Message A" to Firestore
   📬 Receives "Message 1" from Firestore

✅ Result: Both see complete conversation
```

---

## ⚙️ Technical Details

### LocalStorageManager (SwiftData)
```swift
// Stores messages that failed to send
- savePendingMessage(message: Message)
- getPendingMessages() -> [Message]
- markMessageSynced(id: String)
```

### Firestore Automatic Reconnection
- Built into Firebase SDK
- Handles reconnection automatically
- Caches writes while offline
- Syncs when reconnected

### Network Monitoring
```swift
NetworkMonitor.shared
   ↓
@Published var isConnected: Bool
   ↓
UI updates automatically
```

---

## 🎯 Key Features

### Badge Count
- ✅ Dynamic count (not always "1")
- ✅ Accurate across all conversations
- ✅ Capped at 99 for display
- ✅ Clears when app opens

### Offline Sending
- ✅ Messages queued locally
- ✅ Auto-sync when reconnected
- ✅ Visual status indicators
- ✅ No messages lost

### Offline Receiving
- ✅ Firestore queues messages
- ✅ Auto-deliver when reconnected
- ✅ All messages received
- ✅ Proper notification counts

### Network Status
- ✅ Real-time monitoring
- ✅ Visual indicator (orange banner)
- ✅ Automatic reconnection
- ✅ Seamless UX

---

## 📊 Console Logging

### Badge Count
```
🔢 Total unread messages for alice-123: 7
🔢 Setting badge count to: 7
```

### Network Status
```
📶 Network status changed: Connected
📴 Network status changed: Disconnected
```

### Message Sync
```
📤 Found 3 pending messages to sync
✅ Synced message: msg-123
✅ Synced message: msg-456
✅ Synced message: msg-789
```

---

## ✨ Summary

**Badge Count**:
- Shows real count, not always "1"
- Caps at 99 for very large counts
- Clears when app opens

**Offline Handling**:
- Messages queue when offline
- Auto-sync when reconnected
- Firestore handles receiving automatically
- Orange banner shows offline status
- No messages lost!

**User Experience**:
- Transparent offline handling
- Clear visual feedback
- Reliable message delivery
- Professional behavior

**Everything works seamlessly - users can send/receive messages even when offline!** 🎉

