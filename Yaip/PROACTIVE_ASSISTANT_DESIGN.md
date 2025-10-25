# Proactive Assistant: Auto-suggest Meeting Times

## Overview
AI-powered feature that automatically detects scheduling needs in conversations and proactively suggests meeting times without manual user trigger.

---

## Current Implementation Status

### ✅ Already Built
- AIFeaturesViewModel with meeting suggestions
- MeetingSuggestionsView with Apple Calendar integration
- N8NService for AI workflows
- Manual trigger system (user clicks AI button in chat)
- Calendar availability checking

### 🚧 Needs to be Built
- Automatic detection of scheduling intent from messages
- Proactive UI notification/banner system
- Lightweight detection workflow
- User settings/preferences for proactive features

---

## Design Questions & Decisions

### 1. Proactive Detection Trigger
**Question:** When should we analyze messages for scheduling intent?

**Options:**
- A) Analyze EVERY new message (most proactive, but expensive)
- B) Analyze last 5-10 messages when new message arrives (balanced)
- C) Analyze only when certain keywords are present (fast, but limited)

**Recommendation:** **Option B** - Analyze last 5-10 messages with 2-second debounce
- Balances responsiveness with API costs
- Captures conversation context (not just single message)
- Debounce prevents triggering during rapid exchanges

---

### 2. UI/UX for Proactive Suggestions
**Question:** How should we display the proactive suggestion?

**Options:**
- **Option A:** Floating banner at top of chat
  - Pros: Highly visible, familiar pattern (like Signal)
  - Cons: Can feel intrusive
  - Example: "📅 Scheduling detected - Tap to suggest times [Dismiss]"

- **Option B:** Inline card between messages
  - Pros: Contextual, less intrusive
  - Cons: Harder to implement, clutters message flow
  - Example: System message card with "Suggest Meeting Times" button

- **Option C:** Toast/snackbar notification
  - Pros: Brief, auto-dismisses
  - Cons: Easy to miss, no persistent action

- **Option D:** Badge/indicator on AI features button
  - Pros: Least intrusive
  - Cons: Requires user to notice and click

**Recommendation:** **Option A** - Floating banner at top
- Most visible without being too disruptive
- Easy to dismiss if not needed
- Clear call-to-action
- Similar to familiar notification patterns

**Design Specs:**
```swift
// Banner appearance
- Position: Top of chat, below navigation bar
- Style: Blue gradient background, white text
- Icon: 📅 or SF Symbol "calendar.badge.clock"
- Actions: Primary button "Suggest Times", dismiss "X"
- Animation: Slide down from top with gentle bounce
- Auto-dismiss: After 30 seconds if not interacted
```

---

### 3. Scheduling Intent Detection
**Question:** What triggers should detect scheduling needs?

**Keyword Patterns:**
- "let's meet"
- "schedule a call"
- "when are you free"
- "can we chat about"
- "find time to discuss"
- "set up a meeting"
- "grab coffee"
- "quick sync"
- "hop on a call"
- "available for"
- "calendar"
- "zoom/teams/meet"

**AI-Based Detection (Recommended):**
Instead of rigid keywords, use AI to detect intent:
- More flexible (handles variations, typos, context)
- Understands nuance ("We should discuss this" vs "We discussed this")
- Can detect urgency ("ASAP", "urgent", "today")
- Better international/language support

**Approach:** Create lightweight N8N workflow specifically for intent detection
- Returns: `{ hasSchedulingIntent: boolean, confidence: number, suggestedContext: string }`
- Fast response (< 2 seconds)
- Only triggers full meeting suggestion if confidence > 0.7

---

### 4. Settings & User Control
**Question:** How much control should users have?

**Recommended Settings:**

```
Settings > AI Features > Proactive Assistant
├── Enable Proactive Suggestions [Toggle]
├── Auto-detect Scheduling Needs [Toggle]
├── Show Banner Notifications [Toggle]
└── Detection Sensitivity
    ├── High (detect more, may have false positives)
    ├── Medium (balanced) ← Default
    └── Low (only obvious scheduling requests)
```

**Additional Controls:**
- "Don't suggest for this conversation" (per-chat setting)
- Learning from dismissals (if user dismisses 3 times in a row, reduce sensitivity)
- Quiet hours (don't show proactive suggestions outside work hours)

---

### 5. N8N Workflow Architecture
**Question:** New workflow or reuse existing?

**Recommendation:** Create NEW lightweight workflow: `detect-scheduling-intent`

**Why New Workflow:**
- Existing `suggestMeetingTimes` is heavy (full analysis, time generation)
- Detection should be fast (< 2 seconds)
- Separate concerns: detection vs. suggestion generation

**Workflow Design:**

```
Workflow: detect-scheduling-intent
Input:
  - conversationID
  - recentMessages (last 5-10)
  - userID

Processing:
1. Extract text from messages
2. AI Prompt: "Does this conversation indicate scheduling intent?"
3. Return: { hasIntent, confidence, detectedContext }

Output:
{
  "hasSchedulingIntent": true,
  "confidence": 0.85,
  "suggestedContext": "Team wants to schedule project review meeting",
  "urgency": "normal", // low, normal, high
  "participants": ["user1", "user2"]
}
```

---

## Implementation Plan

### Phase 1: Detection Service (Backend)
1. Create N8N workflow `detect-scheduling-intent`
2. Add webhook endpoint to N8NService
3. Test detection accuracy with sample conversations

### Phase 2: View Model Integration
1. Add proactive detection to ChatViewModel
2. Monitor new messages with debounce
3. Call detection service
4. Publish detection result

### Phase 3: UI Components
1. Create ProactiveSuggestionBanner component
2. Add to ChatView
3. Handle user interactions (accept, dismiss)
4. Trigger full meeting suggestion on accept

### Phase 4: Settings & Preferences
1. Add Proactive Settings view
2. Store preferences in UserDefaults
3. Respect user toggles
4. Add learning/feedback mechanism

### Phase 5: Testing & Refinement
1. Test with real conversations
2. Measure false positive rate
3. Adjust confidence thresholds
4. Collect user feedback

---

## Technical Architecture

### New Files to Create
```
Yaip/Services/
  ProactiveAssistantService.swift         # Core detection logic

Yaip/ViewModels/
  ProactiveAssistantViewModel.swift       # Manages detection state

Yaip/Views/Chat/
  ProactiveSuggestionBanner.swift         # Banner UI component

Yaip/Views/Settings/
  ProactiveSettingsView.swift             # User preferences

Yaip/Models/
  SchedulingIntent.swift                  # Detection result model
```

### Data Flow
```
New Message Arrives
    ↓
ChatViewModel.messageAdded()
    ↓
Debounce 2 seconds
    ↓
ProactiveAssistantService.detectIntent()
    ↓
N8N Workflow: detect-scheduling-intent
    ↓
Response: { hasIntent, confidence, context }
    ↓
If confidence > threshold:
    ↓
Show ProactiveSuggestionBanner
    ↓
User taps "Suggest Times"
    ↓
Trigger existing suggestMeetingTimes()
    ↓
Show MeetingSuggestionsView
```

---

## Success Metrics

### Performance
- Detection latency: < 2 seconds
- False positive rate: < 20%
- User acceptance rate: > 40%

### User Experience
- Time saved vs manual trigger: 3-5 seconds
- Perceived value: "Smart" and "helpful"
- Annoyance factor: Minimal (dismissal rate < 50%)

---

## Future Enhancements

### V2 Features
- Multi-language support
- Learn from user behavior (personalized thresholds)
- Integrate with other meeting platforms (Zoom, Teams)
- Suggest alternative actions (reminders, notes)
- Proactive detection for other intents:
  - Action item creation
  - Decision logging
  - Priority flagging

### Advanced AI
- Understand implicit scheduling ("We should catch up soon")
- Detect scheduling conflicts proactively
- Suggest optimal times based on team availability
- Auto-draft meeting agendas from conversation

---

## Open Questions for User

1. **Detection Trigger:** Proceed with last 5-10 messages + 2s debounce?
2. **UI Design:** Floating banner at top (Option A)?
3. **Detection Method:** AI-based with confidence threshold?
4. **Settings:** Add toggle in Settings for enable/disable?
5. **N8N Workflow:** Create new lightweight workflow?

**Recommendation:** Proceed with all recommendations above for balanced implementation.

---

## Notes
- Start simple, iterate based on feedback
- Prioritize low false-positive rate over high detection rate
- Make dismissal easy and respect user preferences
- Consider privacy: detection happens server-side with N8N
