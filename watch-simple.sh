#!/bin/bash

# Simple auto-rebuild script
# Watches for changes and rebuilds after 30 seconds of inactivity

WATCH_DIR="Yaip/Yaip"
DEBOUNCE=30

# Define your simulators
SIMULATORS=(
    "Partner Device"
    "Main Simulator Device iPhone 17 Pro"
)

echo "🔍 Watching $WATCH_DIR for changes..."
echo "⏱️  Will rebuild ${DEBOUNCE}s after last change"
echo "📱 Deploying to:"
for sim in "${SIMULATORS[@]}"; do
    echo "   - $sim"
done
echo ""

fswatch -l $DEBOUNCE -r \
    --exclude "\.xcuserstate$" \
    --exclude "DerivedData" \
    --exclude "\.git" \
    "$WATCH_DIR" | while read file; do
    
    echo "📝 Change detected: $(basename "$file")"
    echo "🔨 Building..."
    
    # Build for first simulator (only need to build once)
    xcodebuild \
        -project "Yaip/Yaip.xcodeproj" \
        -scheme "Yaip" \
        -destination "platform=iOS Simulator,name=${SIMULATORS[0]}" \
        -configuration Debug \
        build
    
    if [ $? -eq 0 ]; then
        echo "✅ Build complete!"
        
        # Find the built app
        APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Yaip.app" -path "*/Build/Products/Debug-iphonesimulator/Yaip.app" -type d | head -n 1)
        
        if [ -n "$APP_PATH" ]; then
            echo "📦 App found: $(basename "$APP_PATH")"
            
            # Deploy to all running simulators
            for sim in "${SIMULATORS[@]}"; do
                # Get the UDID for this simulator
                UDID=$(xcrun simctl list devices | grep "$sim" | grep -E -o -i "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})")
                
                if [ -n "$UDID" ]; then
                    # Check if simulator is booted
                    STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o "Booted" || echo "Not Booted")
                    
                    if [ "$STATE" = "Booted" ]; then
                        echo "📱 Deploying to: $sim"
                        xcrun simctl install "$UDID" "$APP_PATH"
                        xcrun simctl launch "$UDID" com.gaun.Yaip
                        echo "   ✅ Deployed and launched"
                    else
                        echo "⏸️  Skipping $sim (not running)"
                    fi
                fi
            done
        else
            echo "⚠️  Could not find built app"
        fi
        echo ""
    else
        echo "❌ Build failed"
        echo ""
    fi
done

