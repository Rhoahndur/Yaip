# Firebase Storage Rules Setup

## 🚨 Problem

**Images can't be uploaded because Firebase Storage has no security rules configured.**

By default, Firebase Storage blocks all uploads for security. You need to deploy storage rules to allow authenticated users to upload images.

---

## ✅ Solution: Deploy Storage Rules

### **Option 1: Firebase Console (Recommended - Quick)**

1. **Go to Firebase Console**
   ```
   https://console.firebase.google.com/
   ```

2. **Select your project** (Yaip)

3. **Navigate to Storage**
   ```
   Left sidebar → Build → Storage
   ```

4. **Click on "Rules" tab**
   ```
   Top navigation → Rules
   ```

5. **Replace the default rules** with this:
   ```
   rules_version = '2';
   
   service firebase.storage {
     match /b/{bucket}/o {
       
       // Profile images: Users can upload/update their own
       match /profile_images/{userID}/{imageID} {
         allow read: if request.auth != null;
         allow write: if request.auth != null 
                      && request.auth.uid == userID 
                      && request.resource.contentType.matches('image/.*')
                      && request.resource.size < 5 * 1024 * 1024;
       }
       
       // Chat images: Any authenticated user can upload and read
       match /chat_images/{conversationID}/{imageID} {
         allow read: if request.auth != null;
         allow write: if request.auth != null 
                      && request.resource.contentType.matches('image/.*')
                      && request.resource.size < 5 * 1024 * 1024;
       }
       
       // Default: Deny all other access
       match /{allPaths=**} {
         allow read, write: if false;
       }
     }
   }
   ```

6. **Click "Publish"**

7. **Wait 10-30 seconds** for rules to propagate

8. **Test image upload in your app!**

---

### **Option 2: Firebase CLI (Advanced)**

If you have Firebase CLI installed:

```bash
# From your project root
firebase deploy --only storage
```

The rules are already in `storage.rules` file in your project root.

---

## 🧪 Testing

### **After deploying rules:**

1. **Open your app in simulator**
2. **Go to any chat (1-on-1 or group)**
3. **Tap the photo icon** (📷 button)
4. **Select an image** from photo library
5. **Image preview should appear**
6. **Tap send** (↑ button)
7. ✅ **Image should upload and appear in chat!**

---

## 📊 What the Rules Do

```
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // Profile images: /profile_images/{userID}/{imageID}
    // - Any authenticated user can READ
    // - Only the owner can WRITE (upload/update/delete)
    // - Must be an image
    // - Max size: 5MB
    match /profile_images/{userID}/{imageID} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && request.auth.uid == userID 
                   && request.resource.contentType.matches('image/.*')
                   && request.resource.size < 5 * 1024 * 1024;
    }
    
    // Chat images: /chat_images/{conversationID}/{imageID}
    // - Any authenticated user can READ
    // - Any authenticated user can WRITE
    //   (We trust Firestore rules to control conversation access)
    // - Must be an image
    // - Max size: 5MB
    match /chat_images/{conversationID}/{imageID} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && request.resource.contentType.matches('image/.*')
                   && request.resource.size < 5 * 1024 * 1024;
    }
    
    // Everything else: DENY
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 🔒 Security Features

✅ **Authentication Required**: Only logged-in users can access images
✅ **File Type Validation**: Only images allowed (blocks random files)
✅ **Size Limit**: 5MB max (prevents abuse)
✅ **Path-Based Access**: Different rules for profile vs. chat images
✅ **Owner Check**: Profile images only editable by owner

---

## ⚠️ Common Errors

### **Error: "User does not have permission to access this object"**
**Solution**: Deploy the storage rules (see steps above)

### **Error: "Failed to upload image"**
**Check**:
1. Are you signed in?
2. Are storage rules deployed?
3. Is the image > 5MB?
4. Check Xcode console for detailed error

### **Error: "Storage bucket not configured"**
**Solution**: 
1. Go to Firebase Console → Storage
2. Click "Get Started"
3. Choose location (us-central or closest to you)
4. Deploy storage rules

---

## 📝 File Locations

- **Local rules file**: `storage.rules` (in project root)
- **Firebase Console**: https://console.firebase.google.com/ → Storage → Rules
- **Storage path format**: 
  - Profile: `profile_images/{userID}/{imageID}.jpg`
  - Chat: `chat_images/{conversationID}/{imageID}.jpg`

---

## 🚀 Quick Fix Summary

1. Go to Firebase Console
2. Select your project
3. Storage → Rules tab
4. Paste the rules (from above)
5. Click Publish
6. Wait 30 seconds
7. Test image upload
8. ✅ Should work!

---

✅ **After deploying these rules, image uploads will work in both 1-on-1 and group chats!**


