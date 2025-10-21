# Product Context: Yaip

## Why This Project Exists

### The Problem
Remote software teams face three critical challenges:
1. **Information Overload**: Hundreds of messages per day across multiple channels
2. **Context Switching**: Constantly switching between chat, calendar, task tracker, and email
3. **Async Communication Gaps**: Critical information buried in conversations; decisions lost; action items forgotten

### Target Persona: Remote Team Professional
**Profile**: Software engineers, designers, PMs working on distributed teams (2-20 people)

**Pain Points**:
- "I missed an important question buried in 200 Slack messages"
- "I need to catch up on 3 days of conversation—where do I even start?"
- "Someone mentioned a deadline but I can't find it now"
- "We decided something last week but I don't remember what"
- "Scheduling meetings across time zones is a nightmare"

### What Makes This Different
Unlike Slack/Teams (passive chat) or Notion (separate tool), MessageAI embeds intelligence directly into the conversation flow. You don't leave your chat to get AI help—AI proactively surfaces what matters.

## How It Should Work

### User Experience Goals

#### 1. **Messaging Foundation: Reliable & Fast**
- Messages appear instantly (<500ms)
- Works offline seamlessly
- Never lose a message
- Feels as responsive as iMessage/WhatsApp

#### 2. **Contextual AI: Embedded, Not Separate**
- AI features accessed via toolbar in chat (not a separate AI tab)
- Results appear in context (summaries as overlays, action items link back to messages)
- Proactive suggestions appear as special "assistant messages" in the conversation

#### 3. **Catch-Up Flow** (Key Use Case)
```
User opens app after 2 days away
→ Sees "Priority" badge on 2 conversations
→ Opens first conversation: "📊 Summarize 200 messages"
→ Taps banner → Reads 3-paragraph summary
→ Sees "3 action items assigned to you"
→ Taps → Sees list with context links
→ Marks one as done → Original message is highlighted
```

#### 4. **Proactive Assistant Flow** (Advanced Feature)
```
Team discussing scheduling in chat:
Alice: "We need to sync on the Q4 roadmap"
Bob: "Yeah, let's find time next week"
→ Assistant message appears automatically:
  "🤖 I noticed you're trying to schedule a meeting.
   Here are times that work for everyone:
   1️⃣ Tuesday, Oct 24 at 2pm PT (60 min)
      ✅ No conflicts
   2️⃣ Wednesday, Oct 25 at 10am PT (60 min)
      ⚠️ Conflicts: Charlie (can reschedule)
   React with 1️⃣ or 2️⃣ to vote!"
```

### Core User Flows

#### Sending a Message
1. Open conversation or create new chat
2. Type message or attach image
3. Tap send
4. **Optimistic UI**: Message appears instantly with "sending" status
5. Confirmation icon changes to "sent" → "delivered" → "read"

#### Using Thread Summarization
1. Open conversation with many unread messages
2. Tap AI toolbar icon (sparkles)
3. Select "Summarize Conversation"
4. Loading indicator appears
5. Summary sheet displays with:
   - Key decisions
   - Problems/blockers
   - Open questions
   - Action items
   - Overall tone
6. Can copy or dismiss

#### Extracting Action Items
1. In a conversation, tap AI menu
2. Select "Extract Action Items"
3. See list of detected tasks with:
   - Task description
   - Assignee (if mentioned)
   - Deadline (if mentioned)
   - Context snippet
4. Tap checkbox to mark done
5. Tap arrow to jump to original message in chat

#### Smart Search
1. Tap search icon in conversation list
2. Type query: "Q4 budget discussion"
3. Results show:
   - Exact keyword matches
   - Semantically similar messages
   - Ranked by relevance
4. Tap result to jump to message in context

#### Priority Inbox
1. Background function runs every 30 min
2. Scores unread messages for priority
3. User sees badge on high-priority conversations
4. Opens "Priority" filter
5. Sees which specific messages need attention and why
6. Can mark as handled

### Design Principles

1. **Messaging First, AI Second**
   - App must work perfectly as a messaging app
   - AI features enhance, never obstruct

2. **Contextual Over Separate**
   - Don't make users switch to an "AI mode"
   - AI results link back to original context

3. **Proactive Over Reactive**
   - System suggests actions before user asks
   - But never annoying—suggestions are helpful

4. **Fast & Reliable**
   - Real-time updates
   - Offline support
   - No message loss

5. **Privacy Conscious**
   - Conversation data only accessible to participants
   - AI processing on secure backend
   - No data sold or shared

## Problems Each Feature Solves

| Feature | Problem Solved | User Benefit |
|---------|---------------|--------------|
| **Real-time messaging** | Async communication gaps | Know conversations are instant |
| **Offline persistence** | Unreliable connections | Never lose work |
| **Group chat** | Team coordination | Keep everyone in sync |
| **Thread summarization** | Information overload | Catch up in 2 minutes instead of 20 |
| **Action items** | Tasks buried in chat | Never miss a commitment |
| **Smart search** | Can't find discussions | Find info by meaning, not keywords |
| **Priority detection** | Missing urgent messages | See what needs attention now |
| **Decision tracking** | Lost context on "why"| Searchable decision log |
| **Proactive assistant** | Scheduling back-and-forth | Auto-suggest meeting times |

## Success Metrics (Post-Launch)

### Usage Metrics
- Daily active users
- Messages sent per user per day
- AI feature engagement rate
- Time spent in app

### AI Feature Metrics
- Summarization usage (target: 30% of users weekly)
- Action items created (target: 5 per user per week)
- Search queries (target: 2 per user per day)
- Priority inbox opens (target: daily habit)
- Assistant suggestions accepted (target: 60% acceptance rate)

### Quality Metrics
- Message delivery success rate (target: >99.9%)
- Average message latency (target: <500ms)
- Crash-free sessions (target: >99.5%)
- AI accuracy (user feedback)

## User Feedback Loop
- In-app feedback button
- TestFlight feedback collection
- Analytics on AI feature abandonment
- User interviews with early adopters

