# Auto-Rebuild Guide for iOS Simulator

This guide covers different approaches to automatically rebuild and redeploy your app when code changes are detected.

## Option 1: Simple Watch Script (Recommended for Starting)

The simplest approach using `fswatch` (built into macOS):

```bash
# Make the script executable
chmod +x watch-simple.sh

# Run it
./watch-simple.sh
```

**How it works:**
- Watches all Swift files in `Yaip/Yaip/`
- Waits 10 seconds after the last change
- Automatically rebuilds the app
- Xcode will auto-deploy to the running simulator

**Pros:**
- Simple and reliable
- Works with Xcode's automatic deployment
- Easy to customize

**Cons:**
- Requires simulator to be already running
- Terminal must stay open

## Option 2: Advanced Watch Script

A more sophisticated version with better output and control:

```bash
chmod +x watch-and-build.sh
./watch-and-build.sh
```

**Additional features:**
- Color-coded output
- Debounce logic to prevent multiple builds
- Better error handling
- Can be customized for different simulators

## Option 3: Xcode + Manual Trigger

**If you don't want to use scripts:**

1. Keep Xcode open with your project
2. In Xcode: Product → Scheme → Edit Scheme
3. Under "Run" → "Info" → Enable "Debug executable"
4. Use `Cmd + R` to rebuild quickly

**Tip:** You can also use `Cmd + B` to just build without restarting the app.

## Option 4: Use Xcode's Live Previews (SwiftUI Only)

For rapid UI iteration without full rebuilds:

1. Open any SwiftUI View file
2. Click the "Resume" button in the canvas (or `Cmd + Option + P`)
3. Changes to that view will update in real-time

**Limitations:**
- Only works for individual views
- Doesn't run the full app context
- Requires proper preview configurations

## Option 5: Third-Party Tools

### InjectionIII (Hot Reloading)

[InjectionIII](https://github.com/johnno1962/InjectionIII) provides true hot-reloading for Swift:

```bash
# Install via Mac App Store or GitHub
# Then add to your AppDelegate/App struct
```

**Benefits:**
- Changes appear instantly without rebuild
- Maintains app state
- Works for most Swift code

**Setup required:**
- Add Injection framework to your project
- Add observation code to your app

## Customizing the Watch Scripts

### Change the debounce time:

Edit either script and change:
```bash
DEBOUNCE=10  # Change to desired seconds
```

### Change the simulator:

Edit the destination in the script:
```bash
-destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

Available simulators (run to list):
```bash
xcrun simctl list devices
```

### Watch specific file types only:

Add to `fswatch` command:
```bash
fswatch --include "\.swift$" ...
```

## Recommended Workflow

**For active development:**
1. Start your simulator in Xcode (`Cmd + R`)
2. Run the watch script in a terminal: `./watch-simple.sh`
3. Edit code in your preferred editor
4. App auto-rebuilds 10s after you stop typing

**For UI work:**
- Use Xcode's SwiftUI Previews for rapid iteration
- Use the watch script for full app testing

## Troubleshooting

### "fswatch: command not found"
Install via Homebrew:
```bash
brew install fswatch
```

### Script doesn't detect changes
- Ensure you're editing files in the watched directory
- Check that the path in the script is correct
- Try increasing the debounce time

### Build fails but Xcode builds fine
- Make sure you're using the correct scheme name
- Check that the project path is correct
- Try building manually first: `xcodebuild -project Yaip/Yaip.xcodeproj -scheme Yaip -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build`

### Simulator doesn't auto-launch
- Keep the simulator running before starting the watch script
- Xcode should be running in the background
- Check that automatic deployment is enabled in Xcode preferences

## Performance Tips

1. **Incremental builds:** The scripts use incremental builds by default, so only changed files rebuild
2. **Clean builds:** If you need a clean build, run `xcodebuild clean` manually
3. **Exclude files:** Add more exclusions to `fswatch` to ignore generated files
4. **Multiple terminals:** Run the watcher in a separate terminal so you can still use the main one

## Alternative: Makefile Approach

You can also add targets to a Makefile:

```makefile
watch:
	@echo "Watching for changes..."
	@fswatch -l 10 -r Yaip/Yaip | xargs -n1 -I{} make build

build:
	@echo "Building..."
	@xcodebuild -project Yaip/Yaip.xcodeproj -scheme Yaip \
		-destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

Then just run: `make watch`

## Summary

**Quick start (easiest):**
```bash
chmod +x watch-simple.sh && ./watch-simple.sh
```

That's it! Your app will now automatically rebuild 10 seconds after you make changes.

