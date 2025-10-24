# Testing Offline Functionality

## Important: Multiple Network Interfaces

⚠️ **If your Mac has both WiFi AND Ethernet connected**, the app will correctly detect that you have internet connectivity through either interface.

### Common Testing Mistake

❌ **Wrong:** Turn off only WiFi while Ethernet is still connected
- Result: App stays online (correct behavior - you ARE online via Ethernet!)

✅ **Correct:** Disable ALL network connections to test offline

## Proper Offline Testing Methods

### Method 1: Network Link Conditioner (RECOMMENDED)

The Network Link Conditioner simulates network conditions without affecting your actual connectivity.

**Setup:**
1. In Simulator menu: `Debug → Network Link Conditioner`
2. Or install system-wide: [Download Additional Tools for Xcode](https://developer.apple.com/download/all/)

**Usage:**
- **100% Loss** = Completely offline
- **Very Bad Network** = Slow/unreliable connection
- **3G/4G** = Mobile network simulation

**Advantages:**
- ✅ Doesn't affect your Mac's actual internet
- ✅ Can simulate various conditions (slow, unreliable, etc.)
- ✅ Easy to toggle on/off
- ✅ Works per-simulator

### Method 2: Disable All Network Interfaces

To truly test offline on Mac:

1. **Turn off WiFi:** 
   - Menu bar → WiFi icon → Turn WiFi Off

2. **Disconnect Ethernet:**
   - System Settings → Network → Select Ethernet → Click Details → Disconnect
   - OR: Physically unplug Ethernet cable

3. **Verify offline state:**
   - Orange banner should appear: "No internet connection"
   - Messages should show "Sending..." overlay
   - Console logs: `❌ OFFLINE - No network available`

### Method 3: Physical iOS Device

If testing on a real iPhone/iPad:
- Turn on **Airplane Mode**
- This disables all radios instantly

## Expected Behavior

### When Offline:

**UI Indicators:**
- 🟧 Orange banner at top: "No internet connection - Messages will send when reconnected"
- ⏰ Message status shows clock icon (`.staged` or `.sending`)
- 🔴 "Status unavailable" in chat header (for 1-on-1)
- 📸 Images show cached version with "Sending..." overlay

**Console Logs:**
```
🌐 Network status changed:
   Status: unsatisfied
❌ OFFLINE - No network available
📱 Updated NetworkMonitor.isConnected: true → false
🔴 Offline banner appeared
```

**Functionality:**
- ✅ Messages appear in UI immediately (optimistic UI)
- ✅ Images cached locally and shown
- ✅ Messages saved to SwiftData (local persistence)
- ✅ Typing still works locally
- ❌ Messages don't send to Firestore
- ❌ Read receipts don't update
- ❌ Can't see other users' status

### When Reconnecting:

**UI Changes:**
- ✅ Orange banner disappears
- ✅ Status icons update (clock → checkmark)
- ✅ "Sending..." changes to uploaded image
- 🟢 User status reappears

**Console Logs:**
```
🌐 Network status changed:
   Status: satisfied
✅ ONLINE via wifi
📱 Updated NetworkMonitor.isConnected: false → true
🟢 Offline banner disappeared
```

**Automatic Actions:**
- 🔄 Pending messages automatically retry
- 🔄 Failed images automatically re-upload (max 3 attempts)
- 🔄 Status updates to `.sent` → `.delivered` → `.read`
- 🔄 Conversation list refreshes

## Debugging Network Issues

### If Banner Shows Offline But Messages ARE Sending:

This means `NetworkMonitor.isConnected = false` but Firestore IS connected.

**Check Console Logs:**
```bash
# Look for these logs:
🌐 Network status changed:
   Status: [value]
   WiFi available: [true/false]
   Ethernet available: [true/false]
   Available interfaces: [list]
```

**Possible Causes:**
1. **Simulator network bug** - Restart simulator
2. **NWPathMonitor false negative** - Check `path.status` value
3. **Race condition** - NetworkMonitor updated before Firestore
4. **VPN or proxy** - Can affect path detection

**Solution:**
- Check if `path.status = satisfied` but `isConnected = false`
- Verify available interfaces list is not empty
- Restart simulator and rebuild

### If Banner Doesn't Appear When Offline:

**Check:**
1. Is `NetworkMonitor.shared` initialized?
   - Look for: `🔍 Network monitoring started`
2. Is view using `.networkStateBanner()` modifier?
3. Are you using `@ObservedObject` (not `@StateObject`) for shared instance?

**Debug Commands:**
```swift
// In any view:
print("Current network state: \(NetworkMonitor.shared.isConnected)")
```

## Testing Checklist

- [ ] Turn off ALL network (WiFi + Ethernet)
- [ ] Orange banner appears
- [ ] Send text message → Shows "Sending..." status
- [ ] Send image → Shows cached image with overlay
- [ ] Messages appear in UI immediately
- [ ] Turn network back on
- [ ] Banner disappears
- [ ] Messages auto-retry and update to "Sent"
- [ ] Images upload and overlay disappears
- [ ] Read receipts sync properly

## Common Issues

### Issue: "No internet connection" but messages send fine

**Cause:** You have multiple network interfaces (WiFi + Ethernet)

**Solution:** Disable ALL interfaces or use Network Link Conditioner

### Issue: Banner doesn't update when reconnecting

**Cause:** Views not observing NetworkMonitor properly

**Check:** 
- Using `@ObservedObject` not `@StateObject` for `.shared`
- View has `.networkStateBanner()` modifier applied

### Issue: Messages get stuck in "Sending..." after reconnect

**Cause:** Auto-retry isn't triggering

**Solution:**
- Check `.onNetworkReconnect` is implemented
- Verify `retryAllFailedMessages()` is called
- Look for console logs of retry attempts

## Performance Notes

- Network monitoring is lightweight (runs on background queue)
- Banner animations are GPU-accelerated
- Path updates are debounced by system
- No polling - event-driven updates only

## Simulator vs Real Device

**Simulator:**
- Uses Mac's network stack
- Inherits Mac's network interfaces
- Network Link Conditioner available
- May have false positives/negatives

**Real Device:**
- More accurate network detection
- Cellular network available
- Airplane mode works perfectly
- Better for final testing

## Related Files

- `Utilities/NetworkMonitor.swift` - Core network detection
- `Utilities/NetworkStateViewModifier.swift` - UI components
- `ViewModels/ChatViewModel.swift` - Message retry logic
- `Managers/ImageUploadManager.swift` - Image retry logic

