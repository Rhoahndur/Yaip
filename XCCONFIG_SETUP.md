# XCConfig Setup Guide

Your N8N credentials are now securely stored in `Config.xcconfig` which is **ignored by Git**.

## ✅ What's Done

- ✅ Created `Config.xcconfig` with your credentials
- ✅ Created `Config.xcconfig.template` (safe to commit)
- ✅ Created `.env.local` for reference
- ✅ Added to `.gitignore` - Won't be committed
- ✅ Added to `.claudeignore` - Won't be read by AI
- ✅ Updated `Info.plist` to read from xcconfig
- ✅ Updated `N8NService.swift` to read from Info.plist

## 🔧 Final Step: Link Config to Xcode

You need to tell Xcode to use the `Config.xcconfig` file. **This is a one-time setup**.

### Option A: Via Xcode UI (Recommended)

1. **Open Xcode**
   ```bash
   open Yaip/Yaip.xcodeproj
   ```

2. **Add Config.xcconfig to Project**
   - In Project Navigator (left sidebar)
   - Right-click on "Yaip" folder (top level, blue icon)
   - Select "Add Files to Yaip..."
   - Navigate to root directory
   - Select `Config.xcconfig`
   - ✅ Check "Copy items if needed" (UNCHECK THIS)
   - ✅ Check "Add to targets: Yaip"
   - Click "Add"

3. **Set Configuration File for Project**
   - Click on "Yaip" project (blue icon at top)
   - Select "Yaip" target (not the project)
   - Click "Info" tab
   - Under "Configurations" section:
     - Debug: Click dropdown → Select "Config"
     - Release: Click dropdown → Select "Config"

4. **Clean Build Folder**
   - Menu: Product → Clean Build Folder (Cmd+Shift+K)

5. **Build**
   - Menu: Product → Build (Cmd+B)

6. **Verify**
   - Run app
   - Check Xcode console for:
   ```
   🔧 N8N Service initialized
      Webhook URL: https://rhoahndur.app.n8n.cloud/webhook
      Auth Token: AWv4U4uLR5***
   ```

---

### Option B: Manual XML Edit (Advanced)

If the UI method doesn't work, you can edit the project file directly:

1. **Close Xcode** (important!)

2. **Edit project.pbxproj**
   ```bash
   # Open in text editor
   open Yaip/Yaip.xcodeproj/project.pbxproj
   ```

3. **Find the section** with `/* Begin PBXProject section */`

4. **Add this line** under the Yaip target configuration:
   ```xml
   baseConfigurationReference = <YOUR_FILE_REF> /* Config.xcconfig */;
   ```

5. **Save and reopen Xcode**

---

## 🧪 Testing

### Test 1: Verify Config Loaded

Run app and check console:
```
🔧 N8N Service initialized
   Webhook URL: https://rhoahndur.app.n8n.cloud/webhook
   Auth Token: AWv4U4uLR5***
```

✅ If you see your actual URL and token → **Success!**
❌ If you see placeholder values → Config not linked to Xcode (redo steps above)

---

### Test 2: Test N8N Call

1. Open any chat
2. Tap sparkles ✨ → "Summarize Thread"
3. Watch console:

```
📤 Calling N8N webhook for thread summary...
   URL: https://rhoahndur.app.n8n.cloud/webhook/summarize
📡 Sending request to N8N...
   Headers: Authorization: Bearer ***
📥 Received response: 200
✅ Received summary from N8N
```

---

## 🔒 Security Benefits

### Before (Hardcoded):
```swift
private let baseURL = "https://rhoahndur.app.n8n.cloud/webhook"  // ❌ In Git
private let authToken = "AWv4U4uLR5ncVKOomnwerikBgqBlp3Ulxr3WlWtwAb4="  // ❌ In Git
```

### After (Config File):
```swift
private let baseURL: String = {
    Bundle.main.object(forInfoDictionaryKey: "N8N_WEBHOOK_URL") as? String  // ✅ From Config.xcconfig
}()

// Config.xcconfig is in .gitignore ✅
// Config.xcconfig.template in Git (no secrets) ✅
```

---

## 📁 File Structure

```
Yaip/
├── Config.xcconfig                  # ✅ YOUR SECRETS (gitignored)
├── Config.xcconfig.template         # ✅ Template (safe to commit)
├── .env.local                       # ✅ Reference only (gitignored)
├── .gitignore                       # ✅ Ignores Config.xcconfig
├── .claudeignore                    # ✅ Claude won't read secrets
├── Yaip/
│   └── Yaip/
│       ├── Info.plist               # ✅ Reads $(N8N_WEBHOOK_URL)
│       └── Services/
│           └── N8NService.swift     # ✅ Reads from Info.plist
```

---

## 🔄 For Team Members

When someone clones the repo:

```bash
# 1. Copy template to create their own config
cp Config.xcconfig.template Config.xcconfig

# 2. Fill in their own credentials
nano Config.xcconfig

# 3. Link to Xcode (follow steps above)

# 4. Build and run
```

Their `Config.xcconfig` stays local and never gets committed!

---

## 🚨 Troubleshooting

### "Config.xcconfig not found"
- Make sure it exists in root directory
- Run: `ls Config.xcconfig`

### "Still seeing placeholder values"
- Config not linked to Xcode target
- Redo "Link Config to Xcode" steps
- Clean build folder and rebuild

### "File reference error in Xcode"
- Don't check "Copy items if needed" when adding file
- File should be referenced, not copied

### "Values not updating"
- Clean build folder (Cmd+Shift+K)
- Rebuild (Cmd+B)
- Restart Xcode

---

## ✅ Verification Checklist

Before testing N8N:
- [ ] `Config.xcconfig` exists in root directory
- [ ] `Config.xcconfig` has your actual URL and token
- [ ] `Config.xcconfig` is in `.gitignore`
- [ ] Config file linked to Xcode target
- [ ] Clean build performed
- [ ] App rebuilt successfully
- [ ] Console shows actual URL/token on launch
- [ ] Git status shows Config.xcconfig as untracked

---

## 🎉 You're Done!

Your credentials are now:
- ✅ **Secure** (not in Git)
- ✅ **Easy to change** (edit one file)
- ✅ **Team-friendly** (everyone has their own)
- ✅ **CI/CD ready** (can inject in build pipeline)

Now test your N8N integration! 🚀
