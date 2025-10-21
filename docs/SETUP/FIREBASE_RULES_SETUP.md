# Firebase Security Rules Setup

## What Are Security Rules?

Security Rules control who can read/write data in Firestore. Without proper rules:
- ❌ Typing indicators won't work
- ❌ Users might access data they shouldn't see
- ❌ App might have permission errors

## Quick Setup (2 minutes)

### Option 1: Copy-Paste in Firebase Console (Easiest)

1. **Go to Firebase Console**
   - https://console.firebase.google.com
   - Select your project

2. **Navigate to Firestore Rules**
   - Click "Firestore Database" in left sidebar
   - Click "Rules" tab at top

3. **Replace the rules**
   - Select all existing text
   - Copy the contents of `firestore.rules` file
   - Paste into the editor
   - Click "Publish"

4. **Wait for deployment**
   - Should take 10-30 seconds
   - You'll see "Rules published successfully"

### Option 2: Deploy via Firebase CLI (Advanced)

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project (if not already done)
firebase init firestore

# This will create:
# - firebase.json
# - firestore.rules
# - firestore.indexes.json

# Deploy rules
firebase deploy --only firestore:rules
```

## What These Rules Allow

### ✅ Users Collection
- **Read**: Any authenticated user (for displaying names, search)
- **Write**: Only your own user document

### ✅ Conversations Collection
- **Read**: Only conversation participants
- **Write**: Only conversation participants
- **Create**: If you're in the participants list

### ✅ Messages Subcollection
- **Read**: Conversation participants only
- **Create**: Participants only, must be the sender
- **Update**: Participants (for read receipts)
- **Delete**: Only your own messages

### ✅ Presence Subcollection (Typing Indicators)
- **Read**: Conversation participants
- **Write**: Only your own typing status

### ✅ AI Cache & Rate Limits
- **Read**: Authenticated users
- **Write**: Server only (Cloud Functions)

## Testing Your Rules

After deploying, test in your app:

### Test 1: Typing Indicator
```
1. Open app on 2 simulators
2. Start typing on device 1
3. Device 2 should see typing bubble
4. Check console for permission errors
```

If you see errors like:
```
Error: PERMISSION_DENIED: Missing or insufficient permissions
```

→ Rules aren't deployed yet or are incorrect

### Test 2: Create Conversation
```
1. Create new chat with another user
2. Should succeed without errors
3. Check Firestore Console to see the document
```

### Test 3: Send Message
```
1. Send a message in a chat
2. Should appear immediately
3. Other user should receive it
4. No permission errors in console
```

## Common Issues

### Issue: "PERMISSION_DENIED" errors

**Solution:**
- Make sure rules are published in Firebase Console
- Check that user is authenticated (`request.auth != null`)
- Verify user is in conversation participants

### Issue: Typing indicator still doesn't work

**Solution:**
1. Check Firestore Console → Data
2. Navigate to: `conversations/{id}/presence/`
3. Try typing - documents should appear/update
4. If not, rules aren't allowing writes
5. Re-deploy rules

### Issue: Can't create conversations

**Solution:**
- Check that `request.auth.uid` is in participants array
- Make sure user is logged in
- Check console for specific error message

### Issue: Rules too restrictive

**For development/testing only**, you can temporarily use:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **WARNING**: This allows any authenticated user to read/write everything. Only use for quick testing!

## Production Checklist

Before going live:
- [ ] Rules deployed and tested
- [ ] Typing indicators work
- [ ] Users can't access other users' private data
- [ ] Messages are participant-restricted
- [ ] No permission errors in console
- [ ] Rules are not overly permissive

## Monitoring

After deployment:
1. **Firebase Console** → **Firestore Database** → **Usage**
   - Monitor read/write operations
   - Check for denied requests

2. **Check denied requests**:
   - High denied request count = rules too restrictive
   - Should be near zero in production

## Rule Updates

When you add new features, update rules:
1. Edit `firestore.rules` file
2. Test locally if possible
3. Deploy: `firebase deploy --only firestore:rules`
4. Monitor for errors

## Summary

✅ **Rules file created**: `firestore.rules`  
✅ **Ready to deploy**: Copy to Firebase Console  
✅ **Enables**: Typing indicators, proper security  
✅ **Deployment time**: ~30 seconds  

---

**Next Step**: Deploy these rules to Firebase Console! 🚀

