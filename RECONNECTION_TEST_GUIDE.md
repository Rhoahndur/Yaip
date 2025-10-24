# Reconnection Test Guide

## What Was Fixed

### Previous Issues:
1. ❌ Early return prevented offline messages from being saved properly
2. ❌ Offline messages tried to send to Firestore immediately (and failed)
3. ❌ Image retry logic only handled `.failed` state, not `.cached` state

### New Flow:
1. ✅ Messages stay in `.staged` state when offline
2. ✅ Images are cached locally
3. ✅ No attempt to send to Firestore when offline
4. ✅ Network reconnect notification triggers immediate retry
5. ✅ Images upload before Firestore send

---

## Test Scenario 1: Text Message Offline → Online

### Steps:
1. **Go offline** (Settings → Airplane Mode ON)
2. **Send text message**: "Test offline text"
3. **Watch console** for:
```
📴 Skipping Firestore send - offline with text message
   Message will be sent when connection is restored
```
4. **Message should appear** in UI with "Sending..." or pending indicator
5. **Go online** (Airplane Mode OFF)
6. **Watch console** for:
```
🎉 CONNECTION RESTORED - Triggering reconnect notifications
🔄 Network reconnected - immediately retrying pending messages
🔄 retryAllFailedMessages() called
   Network connected: true
   📋 Found staged message: <ID>
   📊 Found 1 messages to retry
   🔁 Retrying message: <ID>
📤 Sending message to Firestore:
   ✅ Retry complete
```
7. **Message should sync** within 1-2 seconds

### Expected Result:
✅ Message appears immediately in UI when offline
✅ Stays in pending state
✅ Syncs automatically when online
✅ Other users receive the message

---

## Test Scenario 2: Image Message Offline → Online

### Steps:
1. **Go offline** (Airplane Mode ON)
2. **Send image message** with text "Test offline image"
3. **Watch console** for:
```
💾 Image cached for message: <ID>
📴 Offline - image message staying in .staged state
   Message will be retried when connection is restored
📴 Skipping Firestore send - offline with image message
   Message will be sent when connection is restored
```
4. **Image should appear** in UI (from local cache)
5. **Go online** (Airplane Mode OFF)
6. **Watch console** for:
```
🎉 CONNECTION RESTORED - Triggering reconnect notifications
🔄 Network reconnected - immediately retrying pending messages
🔄 retryAllFailedMessages() called
   📋 Found staged message: <ID>
   📊 Found 1 messages to retry
   🔁 Retrying message: <ID>
📤 Retrying image upload for message: <ID>
   Image state: cached(<UIImage>)
   Found cached image, uploading...
   ✅ Image uploaded: <URL>
📤 Sending message to Firestore:
   ✅ Retry complete
```
7. **Image should upload** and sync within 5-10 seconds

### Expected Result:
✅ Image appears immediately from cache
✅ Stays in pending state
✅ Uploads automatically when online
✅ Other users receive the image

---

## Test Scenario 3: Multiple Messages Offline

### Steps:
1. **Go offline**
2. **Send 3 messages**:
   - Text: "First"
   - Image: (any photo)
   - Text: "Third"
3. **All should appear** in UI with pending indicator
4. **Go online**
5. **Watch console** for:
```
🔄 retryAllFailedMessages() called
   📋 Found staged message: <ID1>
   📋 Found staged message: <ID2>
   📋 Found staged message: <ID3>
   📊 Found 3 messages to retry
```
6. **All messages should sync** within 5-10 seconds

### Expected Result:
✅ All messages appear immediately
✅ All stay in pending state
✅ All sync in correct order
✅ Image uploads successfully

---

## Test Scenario 4: Manual Retry

### Steps:
1. **Go offline**
2. **Send image message**
3. **Stay offline** for 30+ seconds
4. **Tap "Tap to retry"** button
5. **Watch console** for:
```
📤 Retrying image upload for message: <ID>
   Image state: cached(<UIImage>)
   Found cached image, uploading...
```
6. Should show "No connection" or similar error
7. **Go online**
8. **Tap retry again**
9. **Image should upload**

### Expected Result:
✅ Retry button appears
✅ Clicking while offline shows appropriate feedback
✅ Clicking when online uploads the image

---

## Debugging Checklist

If messages don't sync, check console for:

### 1. Was the notification posted?
Look for:
```
🎉 CONNECTION RESTORED - Triggering reconnect notifications
```

If missing → Network detection issue

### 2. Was notification received?
Look for:
```
🔄 Network reconnected - immediately retrying pending messages
```

If missing → ChatViewModel not listening to notification

### 3. Did retry find messages?
Look for:
```
📋 Found staged message: <ID>
📊 Found X messages to retry
```

If 0 messages → Messages not in `.staged` state

### 4. Did messages actually saved offline?
Look for:
```
📴 Skipping Firestore send - offline with...
```

If missing → Messages tried to send when offline (wrong!)

### 5. For images - was it cached?
Look for:
```
💾 Image cached for message: <ID>
```

If missing → Image not saved locally

### 6. For images - did upload work?
Look for:
```
   Found cached image, uploading...
   ✅ Image uploaded: <URL>
```

If failed → Check Storage permissions or network

---

## Common Issues

### Issue: "Network reconnected" notification never fires
**Cause**: Network detection not working
**Fix**: 
1. Try toggling WiFi instead of airplane mode
2. Check console for network status changes
3. Wait 5 seconds for polling to detect

### Issue: Messages found but not retrying
**Cause**: Retry logic issue
**Fix**: Check console for specific error messages

### Issue: Image cached but not uploading
**Cause**: ImageUploadManager state issue
**Fix**: 
1. Check image state in logs
2. Verify Storage service is working
3. Check Firebase Storage rules

### Issue: Messages sync but take 10+ seconds
**Cause**: Polling delay
**Fix**: This is expected if notification doesn't fire - polling checks every 5s

---

## Expected Performance

| Scenario | Expected Time | Notes |
|----------|--------------|-------|
| Text message sync | 1-2 seconds | Via notification |
| Image message sync | 5-10 seconds | Upload + send |
| Multiple messages | 5-15 seconds | Retries sequentially |
| Manual retry | Immediate | If online |
| Polling detection | 5 seconds | Fallback if notification fails |

---

## Success Criteria

✅ Text messages sync within 2 seconds
✅ Image messages sync within 10 seconds
✅ No messages lost
✅ No duplicate messages
✅ Manual retry works
✅ Works with multiple messages
✅ Works in group chats
✅ Other users receive messages

---

## Quick Test Command

Run this test quickly:
1. Airplane mode ON
2. Send: "test" + image + "done"
3. Airplane mode OFF
4. Count seconds until all sync
5. Should be < 15 seconds total

If it takes longer, check console logs for where it's stuck!

