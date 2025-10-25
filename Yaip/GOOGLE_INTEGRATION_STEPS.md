# Google Calendar Integration - Implementation Steps

You have:
- ✅ Google Client ID
- ✅ Downloaded .plist file

Now let's integrate it into the app!

---

## Step 1: Add Google Sign-In SDK via Swift Package Manager (3 minutes)

### In Xcode:

1. **Open Your Project**
   - Open `Yaip.xcodeproj` in Xcode

2. **Add Package Dependency**
   - Go to: `File` → `Add Package Dependencies...`
   - In the search box (top right), paste: `https://github.com/google/GoogleSignIn-iOS`
   - Click "Add Package"

3. **Select Version**
   - Select: "Up to Next Major Version" `7.0.0`
   - Click "Add Package"

4. **Add to Target**
   - Check: `GoogleSignIn` (the main one)
   - Make sure your app target (`Yaip`) is selected
   - Click "Add Package"
   - Wait for it to download (~30 seconds)

✅ **Done! SDK Added**

---

## Step 2: Extract Client ID from .plist (1 minute)

### From your downloaded .plist file:

1. **Open the .plist file** (in Xcode or text editor)

2. **Find these values:**
   - Look for `<key>CLIENT_ID</key>` → Copy the string value below it
   - Look for `<key>REVERSED_CLIENT_ID</key>` → Copy the string value below it

**Example:**
```xml
<key>CLIENT_ID</key>
<string>123456789-abc123.apps.googleusercontent.com</string>

<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.123456789-abc123</string>
```

**Copy these two values - we'll need them next!**

Your values:
- CLIENT_ID: `_____________________________________________`
- REVERSED_CLIENT_ID: `_____________________________________`

---

## Step 3: Update Info.plist (5 minutes)

### Find Info.plist:
- In Xcode project navigator: `Yaip` → `Yaip` → `Info.plist`
- Or: `Yaip/Yaip/Info.plist`

### Add Google Configuration:

**Option A: Using Xcode's Info.plist Editor (Easier)**

1. Right-click in Info.plist → "Add Row"
2. Type: `GIDClientID` → Press Enter
3. Value: Paste your `CLIENT_ID` (the long one with .apps.googleusercontent.com)

4. Right-click in Info.plist → "Add Row"
5. Type: `CFBundleURLTypes` (if it doesn't exist)
6. Click the triangle to expand it → It becomes an Array
7. Click `+` to add "Item 0" → It becomes a Dictionary
8. Inside Item 0, click `+` to add:
   - Key: `CFBundleURLSchemes` (Type: Array)
9. Click triangle to expand CFBundleURLSchemes
10. Click `+` to add "Item 0"
11. Value: Paste your `REVERSED_CLIENT_ID` (the one starting with com.googleusercontent.apps)

**Option B: Raw XML (If you prefer editing raw XML)**

Click Info.plist → Right-click → "Open As" → "Source Code"

Add before `</dict></plist>`:

```xml
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID_HERE.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID_HERE</string>
        </array>
    </dict>
</array>
```

**Replace:**
- `YOUR_CLIENT_ID_HERE.apps.googleusercontent.com` with your actual CLIENT_ID
- `YOUR_REVERSED_CLIENT_ID_HERE` with your actual REVERSED_CLIENT_ID

✅ **Done! Info.plist Updated**

---

## Step 4: Verify Bundle ID Matches (1 minute)

1. In Xcode: Select your project → Select target (`Yaip`) → "General" tab
2. Check "Bundle Identifier": `com.yourname.yaip` (or whatever yours is)
3. **Make sure this EXACTLY matches** what you entered in Google Cloud Console

If it doesn't match:
- Go back to Google Cloud Console
- Update the Bundle ID in your OAuth client
- OR change your Xcode Bundle ID to match

---

## What's Next?

Once you complete these 4 steps, I'll implement:
1. ✅ Google Sign-In authentication flow
2. ✅ Google Calendar API availability checking
3. ✅ Updated UI to connect/disconnect Google Calendar

**Let me know when you're done with Steps 1-4!**

You can check by:
- Build the project (Cmd+B) - should succeed with no errors about missing imports
- Look in Info.plist and verify you see `GIDClientID` and `CFBundleURLTypes`
