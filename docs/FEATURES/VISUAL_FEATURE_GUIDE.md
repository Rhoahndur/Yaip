# Visual Feature Guide

## 📱 What You'll See in the App

---

## 1. Conversation List

```
┌────────────────────────────────────┐
│  Chats                    [+]  [⚙]  │
├────────────────────────────────────┤
│                                    │
│  ┌──┐●                             │
│  │ A│  Alice Smith            2m   │  ← Green dot = Online
│  └──┘  Hey there! 😊               │
│        ✓✓ Read                     │
│                                    │
│  ┌──┐●                             │
│  │ B│  Bob Jones             15m   │  ← Orange dot = Away
│  └──┘  Sounds good                 │
│                                    │
│  ┌──┐●                      [3]    │
│  │PJ│  Project Team         1h     │  ← Unread badge
│  └──┘  Alice: Let's meet...        │
│                                    │
│  ┌──┐●                             │
│  │ C│  Carol White          2h     │  ← Gray dot = Offline
│  └──┘  See you tomorrow            │
│                                    │
└────────────────────────────────────┘

Features shown:
  ● Online status badges (green/orange/gray)
  ● Read receipts (✓✓)
  ● Unread counts [3]
  ● Relative timestamps (2m, 15m, 1h)
  ● Last message preview
```

---

## 2. Chat View - 1-on-1

```
┌────────────────────────────────────┐
│  < Alice Smith              (i)    │
│    ● Online                        │  ← Status indicator
├────────────────────────────────────┤
│                                    │
│                                    │
│  Hey there!                  14:32 │  ← Received message
│  How are you?                ✓     │    (gray bubble, left)
│                                    │
│                  I'm good! ✓✓ 14:35│  ← Sent message
│            Thanks for asking   Read│    (blue bubble, right)
│                                    │
│  ╭────────╮                        │  ← Typing indicator
│  │ ● ● ●  │                        │    (animated)
│  ╰────────╯                        │
│                                    │
├────────────────────────────────────┤
│ 📷  [Type a message...]      ▲     │  ← Message composer
└────────────────────────────────────┘

Features shown:
  ● Online status in header
  ● Message alignment (left/right)
  ● Read receipts (✓ sent, ✓✓ delivered, ✓✓ Read)
  ● Typing indicator bubble
  ● Timestamps
  ● Image picker button
```

---

## 3. Chat View - Group

```
┌────────────────────────────────────┐
│  < Project Team             (i)    │
│    5 participants                  │  ← Participant count
├────────────────────────────────────┤
│                                    │
│  Alice                             │  ← Sender name (groups)
│  Meeting at 3pm?            14:20  │
│                                    │
│  Bob                               │
│  Works for me!              14:22  │
│                                    │
│                   Count me ✓✓  14:23│  ← Sent message
│                          in!    3  │    (read by 3 people)
│                                    │
│  Carol                             │
│  Perfect 👍                  14:25  │
│                                    │
├────────────────────────────────────┤
│ 📷  [Type a message...]      ▲     │
└────────────────────────────────────┘

Features shown:
  ● Sender names above messages
  ● Participant count in header
  ● Read count (✓✓ 3) for sent messages
  ● Different sender colors/positions
```

---

## 4. New Chat View

```
┌────────────────────────────────────┐
│  New Chat             Cancel       │
├────────────────────────────────────┤
│  🔍  Search users by name          │  ← Search bar
├────────────────────────────────────┤
│                                    │
│  ┌──┐                              │
│  │ A│  Alice Smith                 │
│  └──┘  alice@test.com              │
│                                    │
│  ┌──┐                              │
│  │ B│  Bob Jones                   │
│  └──┘  bob@test.com                │
│                                    │
│  ┌──┐                              │
│  │ C│  Carol White                 │
│  └──┘  carol@test.com              │
│                                    │
└────────────────────────────────────┘

Features shown:
  ● Search bar
  ● User list with avatars
  ● Display names and emails
  ● Tap to create conversation
```

---

## 5. Chat Details

```
┌────────────────────────────────────┐
│  Details                   Done    │
├────────────────────────────────────┤
│                                    │
│           ┌────────┐               │
│           │  PJ    │               │  ← Group icon
│           └────────┘               │
│        Project Team                │
│        5 participants              │
│                                    │
├────────────────────────────────────┤
│  Participants                      │
├────────────────────────────────────┤
│  ┌──┐                              │
│  │ A│  Alice Smith        ●        │  ← You + Online
│  └──┘  alice@test.com              │
│                                    │
│  ┌──┐                              │
│  │ B│  Bob Jones          ●        │  ← Online
│  └──┘  bob@test.com                │
│                                    │
│  ┌──┐                              │
│  │ C│  Carol White        ●        │  ← Offline
│  └──┘  carol@test.com              │
│                                    │
├────────────────────────────────────┤
│  🔵  Add Participant               │
│  🔴  Leave Group                   │
├────────────────────────────────────┤
│  Created: Oct 21, 2025 2:30 PM    │
│  Type: Group Chat                  │
└────────────────────────────────────┘

Features shown:
  ● Group info and icon
  ● All participants with status
  ● Participant details
  ● Action buttons
  ● Metadata
```

---

## 6. Image Message

```
┌────────────────────────────────────┐
│  < Alice Smith              (i)    │
│    ● Online                        │
├────────────────────────────────────┤
│                                    │
│  Check this out!            14:30  │
│  ┌──────────────────────┐          │
│  │                      │          │  ← Image in message
│  │    [  Photo  ]       │          │
│  │                      │          │
│  └──────────────────────┘    ✓     │
│                                    │
│                  Nice pic! ✓✓ 14:32│
│                             Read   │
│                                    │
└────────────────────────────────────┘

Features shown:
  ● Image display in bubble
  ● AsyncImage loading
  ● Optional text with image
  ● Read receipts still work
```

---

## 7. Message Status States

### Sending (Clock)
```
│                  Hello! 🕐 14:30│
│                                │
```

### Sent (Single Check)
```
│                  Hello! ✓  14:30│
│                                │
```

### Delivered (Double Check Gray)
```
│                  Hello! ✓✓ 14:30│
│                                │
```

### Read (Double Check Blue)
```
│                  Hello! ✓✓ 14:30│
│                         Read   │
```

### Failed (Warning)
```
│                  Hello! ⚠️ 14:30│
│                        Failed  │
```

---

## 8. Online Status Legend

### In Conversation List
```
┌──┐●   ← Green dot on avatar = Online
│ A│
└──┘

┌──┐●   ← Orange dot on avatar = Away
│ B│
└──┘

┌──┐●   ← Gray dot on avatar = Offline
│ C│
└──┘
```

### In Chat Header
```
● Online              ← Green dot + text
● Away                ← Orange dot + text
● Last seen 2h ago    ← Gray dot + last seen
```

---

## 9. Typing Indicator Animation

```
Frame 1:  ╭────────╮
          │ ● · ·  │
          ╰────────╯

Frame 2:  ╭────────╮
          │ · ● ·  │
          ╰────────╯

Frame 3:  ╭────────╮
          │ · · ●  │
          ╰────────╯

(Repeats continuously)
```

---

## 10. Image Selection Flow

### Step 1: Tap Image Picker
```
├────────────────────────────────────┤
│ 📷  [Type a message...]      ▲     │
└────────────────────────────────────┘
      ↑
      Tap this
```

### Step 2: Select from Photos
```
┌────────────────────────────────────┐
│  Photos                 Cancel     │
├────────────────────────────────────┤
│  [Thumbnail Grid]                  │
└────────────────────────────────────┘
```

### Step 3: Preview Before Send
```
├────────────────────────────────────┤
│  ┌──────────────────────┐    ✕     │  ← Remove button
│  │   [Image Preview]    │          │
│  └──────────────────────┘          │
├────────────────────────────────────┤
│ 📷  [Add caption...]         ▲     │
└────────────────────────────────────┘
```

---

## Color Scheme

### Message Bubbles
- **Sent messages**: Blue (#007AFF)
- **Received messages**: Light gray
- **Text color**: White (sent), Black (received)

### Status Indicators
- **Online**: Green (#34C759)
- **Away**: Orange (#FF9500)
- **Offline**: Gray (#8E8E93)

### Read Receipts
- **Unread**: Gray (#8E8E93)
- **Read**: Blue (#007AFF)
- **Failed**: Red (#FF3B30)

### UI Elements
- **Primary**: Blue (#007AFF)
- **Destructive**: Red (#FF3B30)
- **Secondary text**: Gray (#8E8E93)
- **Background**: System background (white/dark)

---

## Animations

### 1. Typing Indicator
- **Duration**: 0.6s per dot
- **Effect**: Scale + opacity
- **Delay**: 0.2s between dots
- **Repeat**: Infinite

### 2. Message Appearance
- **Effect**: Slide up + fade in
- **Duration**: 0.3s
- **Easing**: Ease out

### 3. Status Change
- **Effect**: Cross-dissolve
- **Duration**: 0.2s
- **Applies to**: Checkmarks color change

### 4. Online Status
- **Effect**: Fade
- **Duration**: 0.3s
- **Applies to**: Dot color change

---

## Accessibility

All features support:
- ✅ Dynamic Type
- ✅ VoiceOver labels
- ✅ Dark Mode
- ✅ High Contrast
- ✅ Reduce Motion (animations adapt)

---

## Summary

**Visual Highlights**:
- Clean, modern iMessage-inspired design
- Color-coded status indicators
- Progressive read receipt states
- Animated typing indicators
- Responsive image handling
- Clear message grouping
- Intuitive iconography

**Everything is**:
- Visually polished ✨
- Clearly communicated 📣
- Instantly recognizable 👁️
- Smooth animated 🎬
- Accessibility-ready ♿️

---

**Ready to Impress!** 🎉

