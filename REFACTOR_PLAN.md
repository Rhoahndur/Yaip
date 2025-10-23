# 🔧 Offline/Online & Image Handling Refactor Plan

## 📊 Current Issues Analysis

### 1. **Network State Propagation Problems**
**Issue**: Network state not updating smoothly across the app
**Root Causes**:
- `NetworkMonitor.shared` used inconsistently (`@StateObject` vs `@ObservedObject`)
- `onChange` handlers not always firing
- Network state checks scattered throughout code
- No single source of truth for "effective connectivity" (network + Firestore reachability)

**Affected Files**:
- `ChatView.swift` - Uses `@ObservedObject`
- `ConversationRow.swift` - Uses `@ObservedObject`
- `ChatDetailView.swift` - Uses `@ObservedObject`
- `ChatViewModel.swift` - Direct reference to `networkMonitor`

---

### 2. **Image Upload/Handling Complexity**
**Issue**: Images not syncing properly between online/offline states
**Root Causes**:
- **3 different code paths** for image handling:
  1. Upload when online (in `sendMessage`)
  2. Skip upload when offline (in `sendMessage`)
  3. Retry upload when reconnecting (in `retryMessage`)
- Image state stored in **multiple places**:
  1. `LocalStorageManager` image cache (file system)
  2. `Message.mediaURL` (Firestore URL)
  3. `MessageBubble.cachedImage` (@State)
- **No unified state machine** for image upload lifecycle

**Complex Flow**:
```
Send Message → Cache Image → Upload Image? → Update URL → Send to Firestore → Update UI
                ↓                ↓
           (if offline)    (if fails)
                ↓                ↓
           Keep in .sending → Mark .failed → Retry later
```

---

### 3. **Message Status State Management**
**Issue**: Message status inconsistent, retry logic conflicts
**Root Causes**:
- **4 message states**: `.sending`, `.sent`, `.delivered`, `.failed`, `.read`
- Status updated in **multiple places**:
  1. `sendMessage()` - initially `.sending`
  2. Firestore upload success → `.sent`
  3. Firestore upload failure → `.failed`
  4. `retryMessage()` → `.sending` → `.sent` or `.failed`
  5. Firestore listener → may overwrite local state
- **Race conditions**: 
  - Local retry happens while Firestore listener updates arrive
  - UI shows "uploading" but message already sent
  - Message appears/disappears during merge

**Example Race**:
```
T=0: Send message (status: .sending)
T=1: Offline, stays .sending
T=2: Reconnect, trigger retry
T=3: Firestore listener fires with old data → overwrites local state!
T=4: Retry completes → status set to .sent
T=5: Firestore listener fires again → message duplicated or state wrong
```

---

### 4. **Smart Merge Complexity**
**Issue**: Message merge logic is complex and has edge cases
**Current Logic** (lines 87-137 in `ChatViewModel`):
```swift
// 1. Get Firestore messages
// 2. Get local pending messages (status=.sending or .failed, not in Firestore)
// 3. Merge them
// 4. If pending messages + online → trigger auto-retry
```

**Edge Cases**:
- What if Firestore has the message but local is still `.sending`?
- What if image uploaded but Firestore send failed?
- What if retry is in-flight when listener fires?
- What if message was sent from another device?

---

## 🎯 Refactoring Goals

1. **Single Source of Truth** for network state
2. **Unified State Machine** for image uploads
3. **Predictable Message Lifecycle** with no race conditions
4. **Simplified Retry Logic** that's idempotent
5. **Clear Separation** of concerns (UI, Storage, Network, Sync)

---

## 📋 Proposed Architecture

### Phase 1: Network State Centralization ✅
**Goal**: Make network state consistent and reactive everywhere

**Changes**:
1. ✅ Keep `NetworkMonitor.shared` as singleton
2. ✅ All views use `@ObservedObject` (never `@StateObject` for singletons)
3. ✅ Add `NetworkStateView` modifier for consistent network banners
4. ✅ Add `.onNetworkReconnect` view modifier for auto-retry

**Benefits**:
- One place to handle network state changes
- Consistent UI across all views
- Easier to test and debug

---

### Phase 2: Image Upload State Machine 🔄
**Goal**: Unified, predictable image handling

**New Component**: `ImageUploadManager`
```swift
@MainActor
class ImageUploadManager: ObservableObject {
    enum ImageState {
        case notStarted
        case caching(UIImage)           // Saving locally
        case cached(UIImage, localPath) // Saved, ready to upload
        case uploading(progress: Double) // Uploading to Firebase
        case uploaded(url: String)       // Success
        case failed(error: Error)        // Failed (retryable)
    }
    
    @Published var imageStates: [String: ImageState] = [:] // messageID -> state
    
    func handleImage(for messageID: String, image: UIImage, isOnline: Bool) async -> String?
    func retryUpload(for messageID: String) async -> String?
    func cleanupImage(for messageID: String)
}
```

**Changes**:
1. ✅ Create `ImageUploadManager`
2. ✅ Move all image logic out of `ChatViewModel`
3. ✅ `MessageBubble` observes `ImageUploadManager.imageStates[messageID]`
4. ✅ Single upload path (no conditional logic in `sendMessage`)

**Benefits**:
- Clear state transitions
- Single upload code path
- Easy retry logic
- Progress tracking built-in

---

### Phase 3: Message Lifecycle Simplification 🔄
**Goal**: Predictable message states, no race conditions

**New Approach**:
```swift
enum MessageLifecycle {
    case composing                  // User is typing
    case staged(Message)            // Ready to send (has ID, saved locally)
    case sending(Message)           // Uploading image/sending to Firestore
    case sent(Message)              // Successfully sent
    case synced(Message)            // Confirmed by Firestore listener
    case failed(Message, Error)     // Failed (retryable)
}
```

**Changes**:
1. ✅ Separate "staged" state (before network operations)
2. ✅ "synced" state (after Firestore confirmation)
3. ✅ Firestore listener ONLY updates `.sent` → `.synced` (never overwrites `.sending` or `.failed`)
4. ✅ Retry logic only touches `.failed` messages
5. ✅ Clear separation: local operations vs network operations

**Benefits**:
- No race conditions
- Clear state ownership
- Idempotent retry
- Easy to visualize in UI

---

### Phase 4: Simplified Merge Logic 🔄
**Goal**: Reliable Firestore ↔ Local sync

**New Approach**:
```swift
func mergeMessages(firestore: [Message], local: [Message]) -> [Message] {
    var result: [Message] = []
    let firestoreIDs = Set(firestore.map { $0.id })
    
    // Rule 1: Firestore is source of truth for synced messages
    result.append(contentsOf: firestore)
    
    // Rule 2: Keep local pending if NOT in Firestore AND lifecycle is pre-sync
    for localMsg in local {
        guard let id = localMsg.id else { continue }
        
        if !firestoreIDs.contains(id) {
            switch localMsg.status {
            case .sending, .failed:
                result.append(localMsg) // Keep it
            case .sent, .delivered, .read:
                // Firestore should have it - delete local
                try? localStorage.deleteMessage(id: id)
            }
        } else {
            // Firestore has it - trust Firestore, delete local
            try? localStorage.deleteMessage(id: id)
        }
    }
    
    return result.sorted { $0.timestamp < $1.timestamp }
}
```

**Benefits**:
- Clear rules
- No complex conditions
- Automatic cleanup
- Idempotent

---

## 🚀 Implementation Steps

### Step 1: Network State Refactor (30min)
**Files to modify**:
- ✅ Keep `NetworkMonitor.swift` as-is
- ✅ Add `NetworkStateViewModifier.swift` (new file)
- ✅ Update `ChatView`, `ConversationListView`, `ChatDetailView`

**Actions**:
1. Create `.onNetworkReconnect { }` view modifier
2. Create `.networkStateBanner()` view modifier
3. Remove duplicate network banner code from views
4. Ensure all views use `@ObservedObject var networkMonitor = NetworkMonitor.shared`

**Testing**:
- Turn WiFi off → banner appears everywhere
- Turn WiFi on → banner disappears, retry triggers

---

### Step 2: Image Upload Manager (1-2 hours)
**Files to create**:
- ✅ `ImageUploadManager.swift` (new)

**Files to modify**:
- ✅ `ChatViewModel.swift` - remove image logic, delegate to `ImageUploadManager`
- ✅ `MessageBubble.swift` - observe `ImageUploadManager.imageStates`
- ✅ `GroupMessageBubble.swift` - observe `ImageUploadManager.imageStates`

**Actions**:
1. Create `ImageUploadManager` singleton
2. Move `saveImage`, `loadImage`, `deleteImage` coordination here
3. Implement state machine transitions
4. Update `sendMessage()` to use `ImageUploadManager`
5. Update `retryMessage()` to use `ImageUploadManager`
6. Update UI to observe `imageStates`

**Testing**:
- Send image online → see progress → success
- Send image offline → cached → reconnect → auto-upload
- Failed upload → tap to retry → success

---

### Step 3: Message Lifecycle (1 hour)
**Files to modify**:
- ✅ `Message.swift` - add `.staged` and `.synced` states
- ✅ `ChatViewModel.swift` - update state transitions
- ✅ `MessageBubble.swift` - update UI for new states

**Actions**:
1. Add new `MessageStatus` cases
2. Update `sendMessage()` flow:
   ```swift
   // 1. Create message (status: .staged)
   // 2. Save locally
   // 3. Update to .sending
   // 4. Network operations
   // 5. Update to .sent on success, .failed on error
   ```
3. Update Firestore listener to only update `.sent` → `.synced`
4. Update retry logic to only target `.failed`

**Testing**:
- Send message online → see .sending → .sent → .synced transitions
- Send offline → see .sending → stays .sending → reconnect → .sent → .synced
- Fail message → see .failed → tap retry → .sending → .sent

---

### Step 4: Simplified Merge (30min)
**Files to modify**:
- ✅ `ChatViewModel.swift` - `startListening()` merge logic

**Actions**:
1. Implement new `mergeMessages()` function
2. Replace existing merge logic
3. Add cleanup for orphaned local messages

**Testing**:
- Send message → appears locally → syncs to Firestore → no duplicates
- Send offline → appears locally → reconnect → syncs → no duplicates
- Send from device A → appears on device B → no local copy on A

---

### Step 5: Polish & Testing (30min)
**Files to modify**:
- ✅ Remove debug `print` statements (keep essential ones)
- ✅ Remove debug UI elements (e.g., "Monitor: ON/OFF" in banner)
- ✅ Add comprehensive error handling

**Testing**:
- ✅ Full offline → online flow
- ✅ Multiple failed messages retry
- ✅ Image + text messages
- ✅ Group chats vs 1-on-1
- ✅ Device switching (message from device A shows on device B)

---

## 🎯 Success Criteria

### Must Work:
- ✅ Send text message online → instant delivery
- ✅ Send text message offline → appears locally → sends when reconnected
- ✅ Send image online → shows progress → displays image
- ✅ Send image offline → shows cached image → uploads when reconnected
- ✅ Send image+text offline → both sync together when reconnected
- ✅ Failed message → tap to retry → succeeds
- ✅ Network banner → shows accurately → disappears when online
- ✅ Status indicators → accurate → update in real-time

### Should Work:
- ✅ Multiple failed messages → retry all at once
- ✅ Large images → compression → progress bar
- ✅ Network flaky (on/off/on) → graceful handling
- ✅ Message sent from device A → appears on device B

---

## 🤔 Questions for User

1. **How aggressive should retry be?**
   - Option A: Auto-retry immediately on reconnect (current)
   - Option B: Show "tap to retry" button, no auto-retry
   - Option C: Auto-retry once, then show button

2. **Image caching policy?**
   - Keep cached images forever? (eat storage)
   - Delete after successful upload? (current)
   - Delete after 7 days?

3. **Should we show upload progress?**
   - Current: Spinner only
   - Proposed: Progress bar (0-100%)

4. **Failed message UI?**
   - Current: Red icon + "tap to retry"
   - Proposed: Red background + explicit "Retry" button?

5. **Network detection accuracy?**
   - Current: Uses NWPathMonitor (may be inaccurate in simulator)
   - Should we add Firestore ping to confirm connectivity?

---

## 📦 Estimated Time
- **Phase 1**: 30 minutes
- **Phase 2**: 1-2 hours  
- **Phase 3**: 1 hour
- **Phase 4**: 30 minutes
- **Phase 5**: 30 minutes
- **Total**: ~3.5-4.5 hours

---

## 🚦 Recommendation

I recommend we proceed with:
1. **Phase 1** (Network State) first - quick win, helps debug other issues
2. **Phase 2** (Image Manager) next - biggest impact on reliability  
3. **Phase 3 & 4** together - they're related
4. **Phase 5** last - polish

We can pause after each phase for testing and feedback.

**Alternative**: If time is tight, we could do Phase 1 + simplified Phase 2 (just fix the most critical image bugs without full refactor).

What do you think? Should we proceed with the full refactor, or start with Phase 1 and see how it goes?

