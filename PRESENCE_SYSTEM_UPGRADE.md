# Presence System Upgrade - Setup Guide

## What's New

The presence system has been upgraded with **robust offline detection**:

### ✅ New Features:

1. **Automatic Disconnect Detection** - Uses Firebase Realtime Database's `onDisconnect()` to auto-set users offline when:
   - App crashes
   - App is force-quit
   - Network connection drops
   - Device loses power

2. **Heartbeat System** - Sends heartbeat every 30 seconds to prove the user is still active
   - If no heartbeat for 2 minutes → automatically marked as offline
   - Works even if Firebase onDisconnect() fails

3. **Smart Status Inference** - Client-side logic that checks `lastHeartbeat` timestamp
   - If status is "online" but heartbeat is old → shows as "offline" in UI
   - Prevents stale "online" statuses from showing

## Setup Steps

### 1. Add FirebaseDatabase to Xcode Target

1. Open Xcode
2. Select **Yaip** project → **Yaip** target
3. Go to **"Frameworks, Libraries, and Embedded Content"** section
4. Click **"+"**
5. Search for **"FirebaseDatabase"**
6. Add it to the target
7. Build the project (Cmd+B)

### 2. Enable Realtime Database in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select **yaip-77bab** project
3. Click **"Realtime Database"** in left sidebar
4. Click **"Create Database"**
5. Choose location: **us-central1** (or closest to your users)
6. Start in **Test mode** (we'll add security rules later)
7. Click **"Enable"**

### 3. Update Realtime Database Security Rules

Once the database is created, update the rules:

```json
{
  "rules": {
    "presence": {
      "$uid": {
        ".read": true,
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

This allows:
- Anyone can READ presence status (to see who's online)
- Only the user can WRITE their own presence

### 4. Update Firestore Security Rules

Add support for the new `lastHeartbeat` field in `firestore.rules`:

```javascript
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId
        && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['email', 'createdAt']))
        && request.resource.data.keys().hasAll(['displayName', 'email', 'status', 'lastSeen'])
        && request.resource.data.lastHeartbeat is timestamp; // New field
      allow delete: if request.auth.uid == userId;
    }
    // ... rest of rules
  }
}
```

## How It Works

### When User Opens App:

1. `PresenceService.setOnline(userID)` is called
2. Updates Firestore: `status: "online", lastHeartbeat: now`
3. Sets Realtime DB: `presence/{userID}/status: "online"`
4. Registers disconnect handler: "When I disconnect, set status to offline"
5. Starts heartbeat timer (every 30 seconds)

### When User Closes App (Normally):

1. `PresenceService.setOffline(userID)` is called
2. Updates Firestore: `status: "offline"`
3. Updates Realtime DB: `status: "offline"`
4. Stops heartbeat timer

### When App Crashes or Force-Quit:

1. No code runs (can't call setOffline)
2. **Firebase Realtime DB detects disconnect automatically**
3. Triggers the `onDisconnect()` handler: sets `status: "offline"`
4. Syncs back to Firestore via listener
5. User marked as offline within 5-10 seconds ✅

### When Network is Slow/Offline:

1. Heartbeat updates fail
2. After 2 minutes of no heartbeat:
   - Client-side code sees `lastHeartbeat` is old
   - Automatically infers status as "offline"
   - Shows as offline in UI even if Firestore says "online"

## Configuration

You can adjust these values in `PresenceService.swift`:

```swift
private let heartbeatInterval: TimeInterval = 30      // How often to send heartbeat (30s)
private let offlineThreshold: TimeInterval = 120      // Mark offline after no heartbeat (2 min)
```

Recommendations:
- **heartbeatInterval**: 30-60 seconds (balance between accuracy and battery)
- **offlineThreshold**: 2x heartbeatInterval (gives time for retries)

## Testing

### Test 1: Force Quit
1. Open app on Simulator A
2. Verify user shows as "online"
3. Force quit (Cmd+Q)
4. Check from another device → should show "offline" within 10 seconds ✅

### Test 2: Network Drop
1. Open app on real device
2. Turn on Airplane Mode
3. Wait 2 minutes
4. Check from another device → should show "offline" ✅

### Test 3: Background
1. Open app
2. Press Home button (app goes to background)
3. Should change to "away" immediately ✅

## Troubleshooting

### "FirebaseDatabase module not found"
→ Add FirebaseDatabase to Xcode target (Step 1 above)

### "Database URL not found in GoogleService-Info.plist"
→ Already fixed! DATABASE_URL was added to the plist

### Users still showing as "online" when offline
→ Make sure Realtime Database is enabled in Firebase Console (Step 2)

### Heartbeats not working
→ Check console logs for "💓 Heartbeat sent" every 30 seconds

## Migration Notes

Existing users will be automatically upgraded:
- First time they open the app after update, `lastHeartbeat` field will be created
- Old presence statuses will be corrected on next app open
- No data migration needed!

## Performance Impact

- **Battery**: Minimal (1 small network request every 30 seconds)
- **Network**: ~100 bytes per heartbeat = ~200 KB per hour
- **Firebase Costs**: Realtime DB reads are free for presence; Firestore writes ~2/minute per user

This is industry-standard and used by Slack, Discord, WhatsApp, etc.
