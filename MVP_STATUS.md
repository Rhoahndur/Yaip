# MVP Status & Roadmap

## ✅ MVP Complete - What's Working

### Core Messaging (100% Complete)
- ✅ **Real-time messaging** - Send/receive with <500ms latency
- ✅ **Group chat** - Multiple participants, sender names shown
- ✅ **1-on-1 chat** - Direct messaging between users
- ✅ **Offline support** - Messages queue when offline, auto-sync on reconnect
- ✅ **Optimistic UI** - Instant feedback, syncs in background
- ✅ **Message status** - Staged → Sending → Sent → Delivered → Read
- ✅ **Read receipts** - Track who's read messages (1-on-1 and groups)
- ✅ **Typing indicators** - See when someone is typing
- ✅ **Image messages** - Send/receive images with local caching
- ✅ **Image upload retry** - Cached images upload on reconnection

### Authentication (100% Complete)
- ✅ **Email/password signup** - Create account with Firebase Auth
- ✅ **Email/password login** - Sign in with existing account
- ✅ **Session persistence** - Stay logged in across app restarts
- ✅ **User profiles** - Display name, email, status
- ✅ **Presence system** - Online/Away/Offline status

### Offline & Sync (100% Complete)
- ✅ **SwiftData persistence** - Local message/conversation storage
- ✅ **Network monitoring** - Detect connectivity changes
- ✅ **Automatic retry** - Pending messages sync on reconnect
- ✅ **Optimistic network approach** - Trust Firebase SDK, don't block on network checks
- ✅ **Image caching** - Images cached locally before upload

### UI/UX (100% Complete)
- ✅ **Conversation list** - View all chats, sorted by most recent
- ✅ **Chat detail view** - Participant list, group info
- ✅ **Message composer** - Text input, image picker
- ✅ **Empty states** - Helpful messages when no data
- ✅ **Loading states** - Progress indicators
- ✅ **Error handling** - Retry failed messages

### Infrastructure (100% Complete)
- ✅ **Firebase Firestore** - Real-time database
- ✅ **Firebase Storage** - Image/media hosting
- ✅ **Firebase Auth** - User authentication
- ✅ **Security rules** - Proper Firestore/Storage permissions
- ✅ **SwiftUI + MVVM** - Modern iOS architecture
- ✅ **Combine framework** - Reactive programming

---

## 🚧 What's Next - Feature Roadmap

### Phase 1: AI Agent Foundation (This Sprint)
**Goal**: Build UI/UX for AI features, prepare for N8N integration

1. **AI Service Layer**
   - N8N webhook service for agent communication
   - Request/response handling
   - Error handling & retries
   - Rate limiting

2. **Thread Summarization** (Dummy UI)
   - "Summarize" button in chat toolbar
   - Loading state while agent processes
   - Display summary in modal/sheet
   - Cache summaries to avoid re-processing

3. **Action Item Extraction** (Dummy UI)
   - "Extract Tasks" button
   - Show list of detected action items
   - Assignee detection
   - Deadline extraction
   - Link back to original message

4. **Smart Mentions** (Dummy UI)
   - @mention autocomplete in composer
   - Detect who needs to see what
   - Priority notifications

### Phase 2: Proactive AI Assistant
**Goal**: AI agent monitors conversations and provides proactive help

1. **Meeting Scheduler**
   - Detects: "Let's meet", "schedule a call", "find time"
   - Suggests optimal meeting times
   - Checks participant availability
   - Creates calendar events

2. **Decision Tracker**
   - Auto-detects decisions in conversations
   - Extracts: decision made, reasoning, alternatives
   - Shows decision timeline
   - Links to original discussion

3. **Priority Inbox**
   - AI scores messages for priority (0-10)
   - Highlights urgent messages
   - Factors: @mentions, questions, deadlines, tone
   - Separate "Priority" tab

### Phase 3: Advanced AI Features

1. **Semantic Search**
   - Search by meaning, not just keywords
   - "Q4 budget discussion" finds relevant messages
   - Vector embeddings (Pinecone)
   - Conversation context

2. **Smart Replies**
   - AI suggests quick replies
   - Context-aware suggestions
   - Tone matching (professional/casual)

3. **Meeting Notes**
   - Summarize meeting discussions
   - Extract action items from meetings
   - Attendee list
   - Key decisions made

4. **Context Assistant**
   - "Catch me up on this project"
   - Background info for new team members
   - Related conversations
   - Key participants

---

## 🤖 AI Agent Architecture (N8N Integration)

### Current State
- **No AI agents yet** - All AI features are placeholder UI
- **N8N not connected** - Will integrate in Phase 1

### Planned Architecture

```
iOS App (Yaip)
    ↓
N8NService.swift (Webhook client)
    ↓
[HTTPS Webhook]
    ↓
N8N Workflow
    ├─ Claude API (Anthropic)
    ├─ OpenAI Embeddings
    ├─ Pinecone Vector DB
    └─ Firebase Admin SDK
    ↓
[Webhook Response]
    ↓
iOS App receives result
```

### N8N Workflow Examples

**Workflow 1: Thread Summarization**
```
1. Webhook Trigger (receive conversationID, messageCount)
2. Firebase Node (fetch messages from Firestore)
3. Claude API Node (generate summary)
4. Firebase Node (cache summary to Firestore)
5. Webhook Response (return summary JSON)
```

**Workflow 2: Action Item Extraction**
```
1. Webhook Trigger (receive conversationID, dateRange)
2. Firebase Node (fetch recent messages)
3. Claude API Node with Tool Use (extract action items)
4. Firebase Node (save to Firestore)
5. Webhook Response (return action items JSON)
```

**Workflow 3: Proactive Meeting Scheduler**
```
1. Firestore Trigger (new message)
2. Claude API Node (detect scheduling intent)
3. If scheduling detected:
   ├─ Calendar API Node (check availability)
   ├─ Claude API Node (suggest times)
   └─ Firebase Node (post assistant message to chat)
```

### Data Flow

**Request Format** (iOS → N8N):
```json
{
  "feature": "summarize",
  "conversationID": "conv-123",
  "userID": "user-456",
  "parameters": {
    "messageCount": 200,
    "since": "2025-10-20T00:00:00Z"
  }
}
```

**Response Format** (N8N → iOS):
```json
{
  "success": true,
  "feature": "summarize",
  "data": {
    "summary": "Key discussion points...",
    "confidence": 0.95,
    "messageCount": 200
  },
  "cached": false,
  "timestamp": "2025-10-24T12:00:00Z"
}
```

---

## 📋 Immediate Next Steps

### 1. Create AI Service Layer (Today)
- `Services/N8NService.swift` - Webhook client
- `Models/AIRequest.swift` - Request models
- `Models/AIResponse.swift` - Response models
- Environment variable for N8N webhook URL

### 2. Build Dummy AI UI (Today)
- `Views/AIFeatures/` folder structure
- Summarization modal with loading states
- Action items list view
- AI assistant message bubble
- Toolbar buttons to trigger AI features

### 3. ViewModels for AI Features (Today)
- `ViewModels/AIFeaturesViewModel.swift`
- Handle loading states
- Mock responses for testing UI
- Error handling

### 4. N8N Setup (Next)
- Create N8N workflows
- Setup Claude API credentials
- Configure Firebase Admin SDK
- Test webhook endpoints
- Deploy workflows

### 5. Connect Real AI (Next)
- Replace mock responses with N8N calls
- Test end-to-end flow
- Handle rate limiting
- Implement caching

---

## 🎯 Success Metrics

### MVP (Current)
- ✅ Two devices chat in real-time
- ✅ Messages persist after app restart
- ✅ Offline messages sync on reconnect
- ✅ Group chat works with 3+ people
- ✅ Images send/receive successfully

### AI Agent Features (Goal)
- 📊 Summarize 200 messages in <10 seconds
- 🎯 Extract action items with 90%+ accuracy
- 🤖 Detect scheduling intent with 85%+ accuracy
- 🔍 Priority detection reduces noise by 50%
- ⚡ AI responses cached for 1 hour (cost savings)

---

## 💰 Cost Estimates

### Current (No AI)
- Firebase: ~$5/month (1000 users)
- Total: **$5/month**

### With AI Features
- Firebase: ~$5/month
- Claude API: ~$150/month (50 requests/user/month)
- N8N Cloud: $20/month (starter plan) OR $0 (self-hosted)
- Pinecone: $70/month (for semantic search)
- Total: **~$245/month** (1000 users) = **$0.25/user/month**

### Cost Optimization
- ✅ Cache AI responses (1 hour TTL) = 60% savings
- ✅ Rate limit: 10 AI requests/day per user
- ✅ Use cheaper models for simple tasks
- ✅ Batch operations when possible

---

## 🚀 Development Timeline

### Week 1 (Current Week)
- Day 1-2: AI service layer & dummy UI ✅ (This sprint)
- Day 3-4: N8N workflow setup
- Day 5: Connect & test end-to-end

### Week 2
- Day 1-2: Proactive assistant (meeting scheduler)
- Day 3-4: Decision tracking
- Day 5: Priority inbox

### Week 3
- Day 1-2: Semantic search (Pinecone integration)
- Day 3-4: Polish & error handling
- Day 5: Performance optimization

### Week 4
- Testing & refinement
- User feedback collection
- Beta deployment

---

## 📝 Technical Debt & Known Issues

### Resolved
- ✅ Simulator network detection (using optimistic approach)
- ✅ Offline message queueing (fixed early return bug)
- ✅ Image upload retry (caching + reconnection)
- ✅ Read receipt status logic (group vs 1-on-1)

### TODO
- [ ] Push notifications (FCM setup)
- [ ] Voice messages
- [ ] Message reactions (emoji)
- [ ] Message editing
- [ ] Message deletion
- [ ] User search improvements
- [ ] Profile photos
- [ ] Dark mode
- [ ] Localization

---

## 🎨 Design Philosophy

### Optimistic UI
- Show changes immediately
- Sync in background
- Handle failures gracefully
- Never block user actions

### Firebase-First
- Trust Firebase SDK for connectivity
- Use offline persistence (automatic)
- Server timestamps for consistency
- Real-time listeners for live updates

### AI Agent Principles
- **Contextual, not separate** - AI embedded in chat, not a separate bot
- **Proactive when helpful** - Suggest actions without being asked
- **Transparent** - Always show why AI made a suggestion
- **User control** - Easy to dismiss/ignore AI features
- **Privacy-first** - Process only what's needed

---

## 📚 Documentation

Key files for reference:
- `PRD.md` - Original product requirements (3100+ lines)
- `architecture.md` - System architecture diagram
- `RECONNECTION_FIX_SUMMARY.md` - Offline/online handling
- `OPTIMISTIC_NETWORK_APPROACH.md` - Network strategy
- `CLAUDE.md` - Development guide for AI assistants
- `firestore.rules` - Security rules
- `storage.rules` - Storage security

---

This document will be updated as features are completed and new priorities emerge.
