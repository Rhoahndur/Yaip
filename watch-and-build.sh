#!/bin/bash

# Configuration
PROJECT_PATH="Yaip/Yaip.xcodeproj"
SCHEME="Yaip"
WATCH_PATH="Yaip/Yaip"
DEBOUNCE_SECONDS=30
BUNDLE_ID="com.gaun.Yaip"

# Define your simulators
SIMULATORS=(
    "Partner Device"
    "Main Simulator Device iPhone 17 Pro"
)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 Starting auto-rebuild watcher...${NC}"
echo -e "${YELLOW}Watching: $WATCH_PATH${NC}"
echo -e "${YELLOW}Debounce: ${DEBOUNCE_SECONDS}s${NC}"
echo -e "${BLUE}📱 Deploying to:${NC}"
for sim in "${SIMULATORS[@]}"; do
    echo -e "${BLUE}   - $sim${NC}"
done
echo ""

# Track the last build time
last_build=0

# Function to build and deploy
build_and_deploy() {
    current_time=$(date +%s)
    time_since_last_build=$((current_time - last_build))
    
    # Only build if enough time has passed (debounce)
    if [ $time_since_last_build -lt $DEBOUNCE_SECONDS ]; then
        return
    fi
    
    last_build=$current_time
    
    echo -e "${GREEN}🔨 Changes detected! Building...${NC}"
    echo -e "${YELLOW}$(date '+%H:%M:%S')${NC}"
    
    # Build for first simulator (only need to build once)
    # Use xcpretty if available, otherwise use plain output
    if command -v xcpretty &> /dev/null; then
        xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,name=${SIMULATORS[0]}" \
            -configuration Debug \
            build 2>&1 | xcpretty
        BUILD_STATUS=$?
    else
        xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,name=${SIMULATORS[0]}" \
            -configuration Debug \
            build
        BUILD_STATUS=$?
    fi
    
    if [ $BUILD_STATUS -eq 0 ]; then
        echo -e "${GREEN}✅ Build successful!${NC}"
        
        # Find the built app
        APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "$SCHEME.app" -path "*/Build/Products/Debug-iphonesimulator/$SCHEME.app" -type d | head -n 1)
        
        if [ -n "$APP_PATH" ]; then
            echo -e "${BLUE}📦 App found: $(basename "$APP_PATH")${NC}"
            
            # Deploy to all running simulators
            for sim in "${SIMULATORS[@]}"; do
                # Get the UDID for this simulator
                UDID=$(xcrun simctl list devices | grep "$sim" | grep -E -o -i "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})")
                
                if [ -n "$UDID" ]; then
                    # Check if simulator is booted
                    STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o "Booted" || echo "Not Booted")
                    
                    if [ "$STATE" = "Booted" ]; then
                        echo -e "${BLUE}📱 Deploying to: $sim${NC}"
                        xcrun simctl install "$UDID" "$APP_PATH" 2>/dev/null
                        xcrun simctl launch "$UDID" "$BUNDLE_ID" 2>/dev/null
                        echo -e "${GREEN}   ✅ Deployed and launched${NC}"
                    else
                        echo -e "${YELLOW}⏸️  Skipping $sim (not running)${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠️  Could not find UDID for: $sim${NC}"
                fi
            done
        else
            echo -e "${RED}⚠️  Could not find built app${NC}"
        fi
        echo ""
    else
        echo -e "${RED}❌ Build failed!${NC}"
        echo ""
    fi
}

# Watch for changes in Swift files
fswatch -o -r \
    --event Created \
    --event Updated \
    --event Removed \
    --exclude ".*\.xcuserstate" \
    --exclude ".*DerivedData.*" \
    --exclude ".*\.git.*" \
    "$WATCH_PATH" | while read change; do
    
    # Wait for debounce period
    sleep $DEBOUNCE_SECONDS
    
    # Consume any additional events that came in during debounce
    while read -t 0.1 change; do :; done
    
    build_and_deploy
done

