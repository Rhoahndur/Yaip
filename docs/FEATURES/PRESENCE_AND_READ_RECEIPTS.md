# Online Status & Read Receipts Guide

## ✅ What's Been Added

### 1. Online Status Indicators
- **Green dot** = Online
- **Orange dot** = Away
- **Gray dot** = Offline

### 2. Read Receipts
- **Single gray checkmark** = Sent
- **Double gray checkmarks** = Delivered
- **Double blue checkmarks** = Read
- **"Read" text** appears for read messages (1-on-1)
- **Read count** appears in group chats (e.g., "✓✓ 3")

---

## 📍 Where You'll See Them

### Conversation List View
**Location**: Next to user avatars in chat list

**What you'll see**:
```
┌──────────────────────────────┐
│ [Avatar●]  Alice Smith       │  ← Green dot = Online
│            Hey there! 😊      │
│                        2m ago │
├──────────────────────────────┤
│ [Avatar●]  Bob Jones         │  ← Orange dot = Away
│            Sounds good       │
│                      15m ago │
├──────────────────────────────┤
│ [Avatar●]  Carol White       │  ← Gray dot = Offline
│            See you tomorrow  │
│                Last seen 2h  │
└──────────────────────────────┘
```

**Features**:
- Colored badge overlays avatar (bottom-right)
- Only shows for 1-on-1 conversations
- Group chats show count instead

### Chat View Header
**Location**: Below the conversation name

**For 1-on-1 chats**:
```
┌──────────────────────────────┐
│         Alice Smith      (i) │
│      ● Online                │  ← Status indicator
├──────────────────────────────┤
│                              │
│  Hey there!           ✓✓ Read│  ← Read receipt
```

**For Group chats**:
```
┌──────────────────────────────┐
│       Project Team       (i) │
│      5 participants          │  ← Participant count
├──────────────────────────────┤
```

**Shows**:
- Current online status (Online/Away/Offline)
- "Last seen X ago" if offline
- Participant count for groups

### Message Bubbles
**Location**: Bottom-right of each sent message

**Status progression**:
```
Sending:    [🕐]
Sent:       [✓]
Delivered:  [✓✓]
Read:       [✓✓] (blue + "Read")
Failed:     [⚠️] (red)
```

**In 1-on-1**:
- Shows "Read" text when message is read

**In Groups**:
- Shows read count: "✓✓ 3" (3 people read it)
- Doesn't show names (just count)

---

## 🎨 Visual Design

### Status Colors

| Status  | Color  | Meaning                    |
|---------|--------|----------------------------|
| Online  | 🟢 Green | Active right now          |
| Away    | 🟠 Orange | Idle for a few minutes   |
| Offline | ⚫️ Gray  | Not active                |

### Read Receipt States

| Icon | Color | Status | Meaning |
|------|-------|--------|---------|
| 🕐 | Gray | Sending | Uploading to server |
| ✓ | Gray | Sent | Delivered to server |
| ✓✓ | Gray | Delivered | Reached recipient device |
| ✓✓ | Blue | Read | Recipient opened & saw it |
| ⚠️ | Red | Failed | Send error - will retry |

---

## 🔧 How It Works

### Online Status System

**Status Updates**:
1. User opens app → Status set to "Online"
2. User backgrounds app → Status stays "Online" briefly
3. After 5 minutes idle → Status changes to "Away"
4. User closes app → Status set to "Offline"
5. `lastSeen` timestamp updated on each change

**Data Location**:
```
Firestore: users/{userId}
Fields:
- status: "online" | "away" | "offline"
- lastSeen: Timestamp
```

**Update Triggers**:
- `PresenceService.setOnline()` - On login, app active
- `PresenceService.setOffline()` - On logout, app closed
- Automatic on app lifecycle changes

### Read Receipts System

**Flow**:
1. **Message sent** → `status: .sending`
2. **Firestore confirms** → `status: .sent`
3. **Recipient device receives** → `status: .delivered`
4. **Recipient opens chat** → `ChatViewModel.markAsRead()`
5. **Message updated** → `status: .read`, `readBy: [userId]`

**Data Structure**:
```swift
Message {
    status: .read,
    readBy: ["user1", "user2"], // Who has read it
}
```

**Read Detection**:
- Triggered when user opens `ChatView`
- Calls `markAsRead()` in `onAppear`
- Batch updates all unread messages
- Updates Firestore with user ID in `readBy` array

---

## 🧪 Testing

### Test Online Status

**Setup**:
1. Create 2 test accounts: Alice & Bob
2. Run on 2 simulators

**Test**:
```
Simulator 1 (Alice):
1. Open app (login)
2. Go to conversation list
3. Should see Bob with status dot

Simulator 2 (Bob):
1. Stay logged in = Green dot
2. Close app = Gray dot after ~30sec
3. Reopen = Green dot again
```

**Expected**:
- Status updates within 5-10 seconds
- Dot color changes match actual status
- "Last seen" shows when offline

### Test Read Receipts

**Setup**:
1. Alice and Bob in same chat
2. Both have chat open

**Test 1-on-1**:
```
Alice (Sender):
1. Send message: "Hello!"
2. See: 🕐 (sending)
3. Wait: ✓ (sent)
4. When Bob reads: ✓✓ Read (blue)

Bob (Receiver):
1. Message appears
2. Automatically marked as read
3. Alice sees blue checkmarks
```

**Test Groups**:
```
Group with 3 people (Alice, Bob, Carol):

Alice sends: "Meeting at 3pm"
- Initially: ✓ (sent)
- Bob reads: ✓✓ 1 (blue)
- Carol reads: ✓✓ 2 (blue)
- Everyone read: ✓✓ 3 (blue)
```

---

## 🐛 Troubleshooting

### "Online status not showing"

**Check**:
1. **Is user logged in?**
   - Only works for authenticated users
   
2. **Is it a 1-on-1 chat?**
   - Groups don't show individual status

3. **Are Firebase Rules deployed?**
   - Need proper read permissions for `users` collection

4. **Is UserService working?**
   - Check console for errors
   - Verify Firestore has user documents

**Fix**:
```swift
// Check console for:
"Error loading user status: ..."

// If permission denied:
→ Deploy firestore.rules
→ Restart app
```

### "Read receipts not updating"

**Check**:
1. **Is `markAsRead()` being called?**
   - Should trigger in `ChatView.onAppear`

2. **Are messages being updated in Firestore?**
   - Check console → messages collection
   - Look for `readBy` array

3. **Is the listener working?**
   - Real-time updates require active listener
   - Check `ChatViewModel.startListening()`

**Fix**:
```swift
// In ChatView, verify:
.onAppear {
    viewModel.startListening()  // ← Must be called
    viewModel.markAsRead()      // ← Must be called
}
```

### "Status shows wrong color"

**Issue**: User is online but shows offline

**Causes**:
1. Stale cache in `UserService`
2. Firestore data not updated
3. App didn't call `setOnline()`

**Fix**:
```swift
// Clear UserService cache:
UserService.shared.clearCache()

// Force presence update:
try? await PresenceService.shared.setOnline(userID: currentUserID)
```

### "Read receipts delayed"

**Expected Behavior**:
- 1-3 second delay is normal
- Requires network round-trip
- Firestore listener propagation

**If > 10 seconds**:
- Check network connection
- Verify Firestore listeners active
- Check for console errors

---

## 🔐 Privacy Considerations

### What Users See

**Online Status**:
- ✅ Anyone can see your online status
- ✅ "Last seen" is visible when offline
- ❌ Can't hide status (future feature)

**Read Receipts**:
- ✅ Senders see when you read messages
- ✅ You see when others read yours
- ❌ Can't disable (future feature)

### Future Privacy Features

Consider adding:
1. **"Hide online status"** setting
2. **"Disable read receipts"** toggle
3. **"Last seen" privacy** (hide from non-contacts)
4. **"Read receipts"** per-conversation toggle

---

## 📊 Implementation Details

### Files Created/Modified

**New Files**:
- ✅ `OnlineStatusBadge.swift` - Reusable status indicator components
  - `OnlineStatusBadge` - Colored dot
  - `OnlineStatusText` - Status with label

**Modified Files**:
- ✅ `ConversationRow.swift` - Added status badge to avatars
- ✅ `ChatView.swift` - Added status in header
- ✅ `MessageBubble.swift` - Enhanced read receipts
- ✅ `GroupMessageBubble.swift` - Added read count

**Services Used**:
- `PresenceService` - Updates user status
- `UserService` - Fetches user data with caching
- `MessageService` - Handles read receipts

### Performance Optimizations

**Caching**:
- User data cached in `UserService`
- Reduces Firestore reads
- Cache cleared on logout

**Batch Operations**:
- Multiple messages marked read in single batch
- Reduces Firestore write operations
- Better performance & cost

**Real-time Updates**:
- Uses Firestore listeners for instant updates
- No polling required
- Efficient data sync

---

## 🚀 What's Next

### Potential Enhancements

1. **Real-time Presence**
   - Live updates without refresh
   - Listener on user documents

2. **Detailed Read Receipts**
   - Tap to see who read (groups)
   - Show read timestamps
   - "Seen by X, Y, and Z"

3. **Typing + Online Combined**
   - "Alice is typing..." (online)
   - More context

4. **Status Customization**
   - Custom status messages
   - "In a meeting", "At gym", etc.

5. **Privacy Controls**
   - Settings page for online status
   - Per-contact read receipt control

---

## ✅ Summary

**Online Status**:
- ✅ Shows in conversation list (colored dot)
- ✅ Shows in chat header (text + dot)
- ✅ Shows in chat details (all participants)
- ✅ Colors: Green (online), Orange (away), Gray (offline)
- ✅ Auto-updates on app lifecycle

**Read Receipts**:
- ✅ Shows in message bubbles (checkmarks)
- ✅ Gray checkmarks = Delivered
- ✅ Blue checkmarks = Read
- ✅ "Read" text in 1-on-1 chats
- ✅ Read count in group chats
- ✅ Auto-marks read when chat opened

**Both features are**:
- ✅ Fully implemented
- ✅ Visually polished
- ✅ Performance optimized
- ✅ Ready to test!

---

**Status**: Ready for User Testing 🎉

