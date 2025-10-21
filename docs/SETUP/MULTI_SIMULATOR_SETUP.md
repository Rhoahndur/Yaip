# Multi-Simulator Auto-Deploy Setup

## 🎯 What's Configured

Both watch scripts are now set up to:
- **Wait 30 seconds** after your last code change
- **Build once** (efficient!)
- **Deploy to BOTH simulators** automatically:
  - Partner Device
  - Main Simulator Device iPhone 17 Pro

## 🚀 How to Use

### Step 1: Start Both Simulators

Open both simulators in Xcode or via command line:

```bash
# Open Partner Device
xcrun simctl boot "Partner Device"
open -a Simulator

# Open Main Simulator Device (in a new window)
xcrun simctl boot "Main Simulator Device iPhone 17 Pro"
```

Or just launch them from Xcode's device menu.

### Step 2: Run the Watcher

**Option A - Simple version:**
```bash
./watch-simple.sh
```

**Option B - Advanced version with colored output:**
```bash
./watch-and-build.sh
```

### Step 3: Start Coding!

1. Make changes to your Swift files
2. Save your changes
3. Wait 30 seconds (the script is watching)
4. Your app will automatically build and deploy to BOTH simulators! 🎉

## 📋 Requirements

Make sure you have these installed:

```bash
# Check if fswatch is installed
which fswatch

# If not installed, install it:
brew install fswatch

# Optional: Install xcpretty for prettier build output (advanced script)
gem install xcpretty
```

## 🎮 What You'll See

When you save a file, the script will:
1. ✅ Detect the change
2. ⏱️  Wait 30 seconds for more changes
3. 🔨 Build the project once
4. 📦 Find the built app
5. 📱 Deploy to Partner Device (if running)
6. 📱 Deploy to Main Simulator Device iPhone 17 Pro (if running)
7. ✅ Launch the app on both devices

## ⚙️ Customization

### Change the delay time

Edit either script and modify:
```bash
DEBOUNCE=30  # Change to desired seconds
```

### Add/Remove Simulators

Edit the `SIMULATORS` array in either script:
```bash
SIMULATORS=(
    "Partner Device"
    "Main Simulator Device iPhone 17 Pro"
    "Another Simulator Name"  # Add more if needed
)
```

### Deploy to only running simulators

The scripts automatically skip simulators that aren't running - no configuration needed!

## 🔧 Troubleshooting

### "Could not find UDID"
The simulator name doesn't match exactly. Run this to see exact names:
```bash
xcrun simctl list devices | grep "iPhone"
```

### App doesn't launch
- Make sure simulators are fully booted before starting the watch script
- Check that the bundle ID is correct: `com.gaun.Yaip`
- Try launching manually once first: `Cmd + R` in Xcode

### Build fails
- Make sure the project builds successfully in Xcode first
- Check that the scheme name is correct: "Yaip"
- Look at the build output for specific errors

### Only deploys to one simulator
- Ensure both simulators are actually running (booted)
- Check simulator names match exactly
- Look for skip messages in the output

## 💡 Pro Tips

1. **Keep simulators open**: The script only deploys to running simulators
2. **Multiple changes**: The script batches changes - make multiple edits within 30 seconds and it will only build once
3. **Build errors**: Fix them in Xcode, the watcher will automatically try again after the next change
4. **Terminal output**: Keep the terminal visible to see deployment progress
5. **Stop watching**: Press `Ctrl + C` to stop the watch script

## 🎪 Example Workflow

```bash
# Terminal 1: Start the watcher
./watch-simple.sh

# Terminal 2 (or Xcode): Edit code
# Make changes to ChatView.swift
# Save the file

# Watch the terminal - after 30 seconds:
# 🔨 Building...
# ✅ Build complete!
# 📱 Deploying to: Partner Device
#    ✅ Deployed and launched
# 📱 Deploying to: Main Simulator Device iPhone 17 Pro
#    ✅ Deployed and launched

# Both simulators now show your updated app!
```

## 🔄 How It Works

1. **File Watching**: `fswatch` monitors all Swift files in `Yaip/Yaip/`
2. **Debouncing**: Waits 30 seconds after the last change to avoid building repeatedly
3. **Single Build**: Builds once for the first simulator (efficient!)
4. **Smart Deploy**: Finds all booted simulators from your list and deploys to each
5. **Auto Launch**: Launches the app automatically on each device

## ❓ FAQ

**Q: Can I use different simulator names?**
A: Yes! Just update the `SIMULATORS` array in the script with your exact simulator names.

**Q: Will it work with physical devices?**
A: No, this is simulator-only. Physical devices require different deployment methods.

**Q: Can I change the watched directory?**
A: Yes, change `WATCH_PATH` in the script to watch different directories.

**Q: Does it do clean builds?**
A: No, it uses incremental builds for speed. If you need a clean build, do it manually in Xcode.

**Q: Can I have one simulator auto-deploy but not the other?**
A: Yes, just remove it from the `SIMULATORS` array, or don't boot that simulator.

## 🎉 Ready to Go!

Your setup is complete. Just run `./watch-simple.sh` and start coding!

