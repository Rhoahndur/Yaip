# Group Chat Feature Guide

## ✅ Feature Status: ENABLED

Group chat functionality is now fully enabled in Yaip! You can create both 1-on-1 and group conversations.

---

## 🎯 How to Use Group Chat

### Creating a Direct Message (1-on-1)

1. Tap the **+** button in the conversation list
2. Keep **"Direct Message"** selected (default)
3. Search for a user or scroll through the list
4. Tap on a user to select them
5. Tap **"Create"** button in the top right
6. Start chatting! 💬

### Creating a Group Chat

1. Tap the **+** button in the conversation list
2. Switch to **"Group Chat"** mode using the segmented picker
3. Enter a **Group Name** (required)
4. Search for users or scroll through the list
5. Tap on **2 or more users** to add them to the group
   - Selected users appear as blue chips at the top
   - Tap the X on a chip to remove someone
6. Tap **"Create"** button when ready
7. Start group messaging! 🎉

---

## 📱 UI Features

### New Chat View

```
┌─────────────────────────┐
│   New Chat          ✕ Create │
├─────────────────────────┤
│ [Direct Message | Group Chat] │ ← Segmented Picker
├─────────────────────────┤
│ Group Name: _________   │ ← Only visible in Group mode
├─────────────────────────┤
│ [Alice ✕] [Bob ✕]     │ ← Selected users chips
├─────────────────────────┤
│ 🔍 Search users by name │
├─────────────────────────┤
│ ○ Alice Smith          │
│   alice@test.com        │
│                      ✓  │ ← Checkmark when selected
├─────────────────────────┤
│ ○ Bob Johnson          │
│   bob@test.com          │
└─────────────────────────┘
```

### Group Chat View

Group chats display:
- **Header**: Group name + participant count
- **Message bubbles**: Sender name above each message
- **Info button**: View all participants and their status
- **All standard features**: Typing indicator, read receipts, images

---

## 🔧 Technical Details

### Validation Rules

**Direct Message:**
- Requires: Exactly 1 selected user
- "Create" button enabled when valid

**Group Chat:**
- Requires: 2+ selected users + non-empty group name
- "Create" button enabled when valid

### Behavior

1. **Mode Switching**: Switching between Direct/Group clears all selections
2. **Selection**:
   - Direct mode: Single selection (tapping another user replaces selection)
   - Group mode: Multi-selection (tap to add/remove)
3. **Creating**: Shows "Creating..." while processing
4. **Error Handling**: Displays error message if creation fails

---

## 🎨 What's Different in Group Chats?

### Conversation List
- Shows group name instead of participant name
- Displays participant count in subtitle (if needed)
- No online status indicator (groups don't have status)

### Chat View
- **Navigation Title**: Shows group name
- **Message Bubbles**: Include sender name above bubble
- **Chat Details**: Shows all participants with their:
  - Profile picture
  - Display name
  - Email
  - Online status

### Message Attribution
- Each message shows who sent it
- Read receipts show how many people read it
- Typing indicator can show multiple people typing (future enhancement)

---

## 🧪 Testing Group Chat

### Test Scenarios

1. **Create a 3-person group**:
   - Sign in on 3 simulators (Alice, Bob, Charlie)
   - Alice creates group "Team Alpha" with Bob and Charlie
   - Verify all 3 see the conversation

2. **Send messages**:
   - Each person sends a message
   - Verify sender names appear correctly
   - Verify messages appear for all participants

3. **Read receipts**:
   - Alice sends message
   - Bob opens chat → Alice sees "Read by 1"
   - Charlie opens chat → Alice sees "Read by 2"

4. **Typing indicator**:
   - Bob starts typing
   - Alice and Charlie see typing indicator
   - Bob stops typing → indicator disappears

5. **Images in groups**:
   - Send image in group
   - Verify all participants receive it
   - Verify sender name shows above image

---

## 🚀 Backend Support

All backend features are fully implemented:

- ✅ `Conversation.type` distinguishes `.oneOnOne` vs `.group`
- ✅ `Conversation.participants` array supports multiple users
- ✅ `Conversation.name` stores group names
- ✅ `ConversationService` handles group creation
- ✅ `MessageService` works with groups
- ✅ Firestore rules allow group operations
- ✅ Read receipts track multiple readers
- ✅ Chat details show all participants

---

## 📝 Code Changes

### Modified Files

1. **NewChatView.swift**:
   - Added `isGroupChatMode` toggle
   - Added `groupName` input field
   - Modified `handleUserTap` to support multi-select
   - Added `canCreate` validation
   - Added `createConversation` to handle both modes

2. **ConversationListViewModel.swift**:
   - Made `authManager` internal for access from NewChatView

---

## 🎯 Next Steps

The group chat feature is **fully functional**! You can now:

1. ✅ Build and run the app
2. ✅ Create direct messages (as before)
3. ✅ Create group chats (new!)
4. ✅ Send messages in groups
5. ✅ View participants
6. ✅ See who read messages
7. ✅ Share images in groups

**No additional setup required** - just test it out! 🚀

