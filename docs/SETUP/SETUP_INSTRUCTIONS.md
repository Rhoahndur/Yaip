# Yaip - Setup Instructions

## Prerequisites Checklist
- [ ] macOS with Xcode 15+ installed
- [ ] Apple Developer Account (free or paid)
- [ ] Firebase account (free)
- [ ] Git installed

---

## Phase 1: Xcode Project Setup

### Step 1: Create Xcode Project
1. Open Xcode
2. File → New → Project
3. Select **iOS** → **App**
4. Configure:
   - Product Name: `MessageAI`
   - Bundle ID: `com.[yourname].MessageAI` (e.g., `com.alexgaun.MessageAI`)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployments: **iOS 17.0**
5. Save to: `/Users/aleksandrgaun/Downloads/Yaip/`
6. ✅ Check "Create Git repository"

### Step 2: Verify Project Structure
After creation, you should see:
```
Yaip/
├── .gitignore (already created)
├── MessageAI/
│   ├── MessageAIApp.swift
│   ├── ContentView.swift
│   └── Assets.xcassets/
└── MessageAI.xcodeproj
```

---

## Phase 2: Firebase Setup

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: **MessageAI**
4. Click Continue
5. **Enable Google Analytics**: Recommended (toggle ON)
6. Click Continue
7. Select Analytics account or create new
8. Click **"Create project"**
9. Wait for project creation (~30 seconds)
10. Click **"Continue"** when ready

### Step 2: Add iOS App to Firebase
1. In Firebase Console, on project overview page
2. Click **iOS icon** (or click gear icon → Project settings → Add app)
3. Enter **iOS bundle ID**: Use the SAME bundle ID from Xcode (e.g., `com.alexgaun.MessageAI`)
4. App nickname (optional): `MessageAI`
5. App Store ID: Leave blank for now
6. Click **"Register app"**
7. **Download GoogleService-Info.plist** (Click the download button)
8. ⚠️ **IMPORTANT**: Save this file, we'll add it to Xcode next

### Step 3: Add GoogleService-Info.plist to Xcode
1. In Xcode, right-click on **MessageAI** folder (the one with MessageAIApp.swift)
2. Select **"Add Files to MessageAI..."**
3. Navigate to where you saved `GoogleService-Info.plist`
4. ✅ **IMPORTANT**: Check **"Copy items if needed"**
5. ✅ Make sure **MessageAI target** is checked
6. Click **"Add"**
7. Verify the file appears in the project navigator

### Step 4: Enable Firebase Services
In Firebase Console:

1. **Authentication**:
   - Left sidebar → Build → Authentication
   - Click "Get started"
   - Sign-in method tab
   - Enable **Email/Password**
   - Click Save

2. **Firestore Database**:
   - Left sidebar → Build → Firestore Database
   - Click "Create database"
   - Location: Choose closest to you (e.g., us-central)
   - Security rules: Start in **test mode** (we'll update later)
   - Click Enable

3. **Storage**:
   - Left sidebar → Build → Storage
   - Click "Get started"
   - Security rules: Start in **test mode**
   - Location: Same as Firestore
   - Click Done

4. **Cloud Messaging** (for Push Notifications):
   - Left sidebar → Build → Cloud Messaging
   - Click "Get started" or just note the settings
   - We'll configure APNs later when testing

---

## Phase 3: Add Firebase SDK to Xcode

### Step 1: Add Firebase via Swift Package Manager
1. In Xcode, select your project in the navigator (top-most item)
2. Select **MessageAI** target
3. Go to **Package Dependencies** tab
4. Click **"+"** button
5. In search bar, paste: `https://github.com/firebase/firebase-ios-sdk`
6. Click **"Add Package"**
7. Wait for package to load (~30 seconds)

### Step 2: Select Firebase Products
When prompted, select these packages:
- ✅ **FirebaseAuth**
- ✅ **FirebaseFirestore**
- ✅ **FirebaseStorage**
- ✅ **FirebaseMessaging**
- ✅ **FirebaseFunctions**
- ✅ **FirebaseAnalytics** (optional but recommended)
- ✅ **FirebaseCrashlytics** (optional but recommended)

Click **"Add Package"**

Wait for packages to download and integrate (~1-2 minutes)

---

## Phase 4: Enable iOS Capabilities

### Step 1: Enable Push Notifications
1. Select **MessageAI** project in navigator
2. Select **MessageAI** target
3. Go to **Signing & Capabilities** tab
4. Click **"+ Capability"**
5. Search for and add **"Push Notifications"**

### Step 2: Enable Background Modes
1. Still in **Signing & Capabilities**
2. Click **"+ Capability"** again
3. Search for and add **"Background Modes"**
4. In Background Modes section, check:
   - ✅ **Remote notifications**
   - ✅ **Background fetch**

---

## Phase 5: Configure Firebase in Code

We'll update the app files in the next step to initialize Firebase.

---

## Troubleshooting

### GoogleService-Info.plist not found
- Make sure you checked "Copy items if needed" when adding
- Verify file is in the same folder as MessageAIApp.swift
- Clean build folder: Product → Clean Build Folder

### Firebase packages won't download
- Check internet connection
- Try restarting Xcode
- Remove and re-add the package

### Bundle ID mismatch
- In Xcode: Target → General → Identity → Bundle Identifier
- In Firebase: Settings → Your apps → iOS app → Bundle ID
- **These must match exactly**

---

## Verification Checklist

Before proceeding, verify:
- [ ] Xcode project created successfully
- [ ] Firebase project created
- [ ] GoogleService-Info.plist added to Xcode
- [ ] Firebase SDK packages added
- [ ] Authentication enabled in Firebase
- [ ] Firestore Database created
- [ ] Storage enabled
- [ ] Push Notifications capability enabled
- [ ] Background Modes capability enabled
- [ ] Project builds without errors (⌘B)

---

## Next Steps

Once setup is complete, we'll:
1. Update MessageAIApp.swift to initialize Firebase
2. Create the folder structure for the project
3. Begin implementing features

---

## Need Help?

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all checkboxes in the verification checklist
3. Make sure Xcode and macOS are up to date
4. Check Firebase Console for any service status issues

