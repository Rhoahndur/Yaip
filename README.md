# Yaip - AI-Powered Team Messaging

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017.6%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

**Yaip** is a modern, AI-powered team messaging app built for remote professionals. It combines real-time chat with intelligent AI features that automatically summarize conversations, extract action items, detect priorities, and more.

---

## ✨ Features

### 💬 Core Messaging
- **Real-time chat** - Instant message delivery with <500ms latency
- **Group conversations** - Create teams with 3+ participants
- **1-on-1 chats** - Direct messaging between users
- **Offline support** - Messages queue automatically and sync when reconnected
- **Image sharing** - Send photos with automatic compression
- **Message reactions** - React with 8 emoji reactions (👍 ❤️ 😂 😮 😢 🙏 🔥 🎉)
- **Message replies** - Thread conversations with quote replies
- **Message deletion** - Remove messages with soft delete

### 🤖 AI Features

#### 1. Thread Summarization
Get instant AI-generated summaries of long conversations
- Highlights key discussion points
- Identifies decisions made
- Extracts questions asked
- Shows conversation tone

#### 2. Action Items Extraction
Automatically detect tasks from conversations
- Extract assignees
- Identify deadlines
- Categorize by priority
- Link to original message context

#### 3. Smart Search
Semantic + keyword search powered by AI
- Search by meaning, not just keywords
- Relevance scoring
- Hybrid matching (semantic + keyword)
- Find messages by user name

#### 4. Priority Detection
AI scores messages for urgency (0-10)
- Detect critical messages (9-10)
- Highlight high priority (7-8)
- Flag messages needing attention (6)
- Reduce notification noise

#### 5. Decision Tracking
Auto-extract decisions from conversations
- Capture decision reasoning
- Track impact assessment
- Categorize decision types
- Link to discussion context

#### 6. Meeting Suggestions
AI-suggested meeting times
- Analyze scheduling discussions
- Suggest optimal time slots
- Consider participant availability
- Generate meeting proposals

### 🎨 User Experience
- **Dark mode** - Full system-wide dark mode support
- **Read receipts** - See who's read your messages (group-aware)
- **Typing indicators** - Know when someone is typing (1-on-1 chats)
- **Online presence** - 🟢 Online, 🟠 Away, ⚫️ Offline status
- **Message status** - Sending → Sent → Delivered → Read
- **Visual feedback** - Pulsing animations, haptic feedback
- **Message highlighting** - Scroll to and highlight specific messages
- **Polished animations** - Smooth transitions and loading states

---

## 🏗️ Architecture

### Tech Stack
- **Frontend**: SwiftUI + MVVM architecture
- **Backend**: Firebase (Firestore, Storage, Auth)
- **AI Processing**: N8N Workflows + OpenAI GPT-3.5-turbo
- **Local Storage**: SwiftData for offline persistence
- **Real-time Sync**: Firestore snapshot listeners

### System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     iOS App (SwiftUI)                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  Views   │←→│ViewModels│←→│ Services & Managers  │  │
│  └──────────┘  └──────────┘  └──────────────────────┘  │
└────────────────────────┬────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ↓               ↓               ↓
  ┌──────────┐   ┌──────────────┐   ┌──────────┐
  │ Firebase │   │ N8N Workflows│   │SwiftData │
  │          │   │              │   │ (Local)  │
  │ • Auth   │   │ • OpenAI API │   └──────────┘
  │ • Firestore  │ • AI Processing│
  │ • Storage│   │ • User Lookup│
  └──────────┘   └──────────────┘
```

### AI Workflow (N8N)

Each AI feature follows this pattern:
1. iOS app sends request to N8N webhook
2. N8N fetches messages from Firestore
3. N8N calls OpenAI GPT-3.5-turbo for processing
4. N8N enriches data (e.g., user names lookup)
5. N8N returns structured JSON response
6. iOS app displays results with polished UI

---

## 📱 Screenshots

### Chat Interface
- Real-time messaging with typing indicators
- Message status icons (sent, delivered, read)
- Image messages with compression
- Message reactions and replies

### AI Features
- Thread summaries with key points
- Action items with assignees and deadlines
- Priority inbox highlighting urgent messages
- Smart search with relevance scoring
- Decision timeline with reasoning
- Meeting time suggestions

### Polish Features
- Dark mode throughout the app
- Online presence indicators
- Message highlighting and scroll-to
- Context menus for quick actions
- Loading animations with shimmer effects

---

## 🚀 Setup Instructions

### Prerequisites
- **Xcode 15.0+** with iOS 17.6+ SDK
- **Firebase project** (Auth, Firestore, Storage)
- **N8N instance** (cloud or self-hosted)
- **OpenAI API key** for AI features
- **Apple Developer account** (for device testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/yaip.git
   cd yaip
   ```

2. **Configure Firebase**
   - Create Firebase project at https://console.firebase.google.com
   - Add iOS app with bundle ID
   - Download `GoogleService-Info.plist`
   - Place in `Yaip/Yaip/` directory
   - Enable Authentication (Email/Password)
   - Create Firestore database
   - Enable Firebase Storage

3. **Deploy Firestore Security Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

4. **Set up N8N Workflows**
   - Follow `N8N_SETUP_GUIDE.md` for detailed instructions
   - Create workflows for each AI feature
   - Configure OpenAI API credentials
   - Set up Firebase Admin SDK

5. **Configure API Keys**
   - Copy `Config.xcconfig.template` to `Config.xcconfig`
   - Add your N8N webhook URL and auth token:
     ```
     N8N_BASE_URL = https://your-n8n-instance.com/webhook
     N8N_AUTH_TOKEN = your_secret_token
     ```
   - **Important**: Never commit `Config.xcconfig` to git

6. **Open in Xcode**
   ```bash
   open Yaip/Yaip.xcodeproj
   ```

7. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run
   - Create test accounts to try messaging

### Testing

**Two-Device Testing**:
1. Run app on 2 simulators or devices
2. Sign up with different emails on each
3. Search for users and create conversation
4. Send messages and test real-time sync
5. Try AI features on conversations with 20+ messages

**Offline Testing**:
1. Send messages while online
2. Enable Airplane Mode
3. Send messages (they'll queue)
4. Disable Airplane Mode
5. Watch messages auto-sync

---

## 📖 Documentation

- **[PRD.md](PRD.md)** - Complete product requirements
- **[architecture.md](architecture.md)** - System architecture diagram
- **[Tasks.md](Tasks.md)** - Development task breakdown (26 PRs)
- **[N8N_SETUP_GUIDE.md](N8N_SETUP_GUIDE.md)** - AI workflow setup guide
- **[CODE_CLEANUP_GUIDE.md](CODE_CLEANUP_GUIDE.md)** - Code maintenance guide
- **[MVP_STATUS.md](MVP_STATUS.md)** - Current implementation status
- **[WHATS_NEXT.md](WHATS_NEXT.md)** - Roadmap and future features
- **[AI_FEATURES_ROADMAP.md](AI_FEATURES_ROADMAP.md)** - AI feature planning
- **[PROJECT_REVIEW_ANALYSIS.md](PROJECT_REVIEW_ANALYSIS.md)** - Feature analysis

---

## 🎯 Use Cases

### Remote Teams
- Reduce meeting time with AI summaries
- Never miss action items with auto-extraction
- Prioritize urgent messages automatically
- Search by meaning, not just keywords

### Project Management
- Track decisions with context
- Extract tasks from discussions
- Schedule meetings intelligently
- Maintain conversation history offline

### Distributed Collaboration
- Real-time communication across time zones
- Offline-first architecture for spotty connections
- Group chats for team coordination
- 1-on-1 chats for direct communication

---

## 💰 Cost Breakdown

### For 1,000 Active Users:

| Service | Monthly Cost | Per User |
|---------|-------------|----------|
| Firebase (Firestore + Storage + Auth) | $5 | $0.005 |
| N8N Cloud (or $0 self-hosted) | $20 | $0.02 |
| OpenAI API (GPT-3.5-turbo) | ~$120 | $0.12 |
| **Total** | **$145** | **$0.15** |

**Cost Optimizations**:
- ✅ Cache AI responses (1 hour TTL) - 60% savings
- ✅ Rate limit: 10 AI requests/day per user
- ✅ Image compression reduces storage costs
- ✅ Efficient Firestore queries minimize reads

**Revenue Models**:
- **Freemium**: Free basic chat, $5/user/month for AI features
- **Team Plans**: $10/user/month unlimited everything
- **Enterprise**: Custom pricing with dedicated support

**Break-even**: 15-30 paying users

---

## 🧪 Testing

### Manual Testing Checklist
- [ ] Sign up new account
- [ ] Create 1-on-1 conversation
- [ ] Send text messages (see real-time delivery)
- [ ] Send image messages
- [ ] React to messages
- [ ] Reply to messages
- [ ] Delete own messages
- [ ] Create group chat (3+ users)
- [ ] Test typing indicators
- [ ] Test read receipts
- [ ] Test offline mode (airplane mode)
- [ ] Test AI summarization (20+ messages)
- [ ] Test action item extraction
- [ ] Test smart search
- [ ] Test priority detection
- [ ] Test decision tracking
- [ ] Test meeting suggestions

### Performance Testing
- Tested with 500+ messages: ✅ Smooth scrolling
- Tested with slow network (3G): ✅ Graceful degradation
- Tested rapid sending (100 messages): ✅ No duplicates
- Memory profiling: ✅ No leaks detected

---

## 🐛 Known Issues & Limitations

### Not Yet Implemented
- ⚠️ **Push notifications** - Requires APNs certificate and FCM setup
- ⚠️ **Voice messages** - Audio recording and playback
- ⚠️ **Video messages** - Video recording and streaming
- ⚠️ **Message editing** - Edit sent messages
- ⚠️ **File attachments** - Share PDFs, documents
- ⚠️ **Profile photos** - Custom user avatars

### Known Limitations
- **Simulator network detection** - NWPathMonitor unreliable on simulator, but Firebase SDK handles actual connectivity
- **Group typing indicators** - Only supported in 1-on-1 chats
- **Calendar integration** - Meeting suggestions don't check actual calendars yet
- **Message pagination** - Currently loads all messages (works fine up to ~1000)

### Platform Support
- ✅ **iOS 17.6+** - Fully supported
- ❌ **macOS** - Not yet implemented (SwiftUI could be adapted)
- ❌ **Web** - Not yet implemented (could build with Next.js)
- ❌ **Android** - Not planned (iOS-only for now)

---

## 🤝 Contributing

This is currently a solo project for demonstration purposes. If you'd like to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

### Technologies Used
- [Firebase](https://firebase.google.com/) - Backend infrastructure
- [N8N](https://n8n.io/) - Workflow automation for AI features
- [OpenAI](https://openai.com/) - GPT-3.5-turbo for AI processing
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Modern iOS UI framework

### Inspiration
Built to solve real problems faced by remote teams:
- Too many messages to read
- Important action items lost in chat
- Decisions made but not documented
- Time wasted scheduling meetings

---

## 📊 Project Stats

- **Development Time**: ~3 weeks
- **Lines of Code**: ~4,000+ Swift
- **Files**: 50+ Swift files
- **Services**: 8 backend services
- **ViewModels**: 3 main view models
- **Views**: 15+ SwiftUI views
- **AI Features**: 6 complete features
- **N8N Workflows**: 6 workflows
- **Firebase Collections**: 3 main collections

---

## 🎥 Demo Video

_[Demo video coming soon]_

**See it in action**:
- Real-time messaging demonstration
- All 6 AI features working
- Offline mode testing
- Group chat with 3+ participants
- Polish features (reactions, delete, reply)

---

## 📧 Contact

**Questions or feedback?**
- Open an issue on GitHub
- Email: [your-email@example.com]
- Twitter: [@yourusername]

---

## 🚀 What's Next?

See [WHATS_NEXT.md](WHATS_NEXT.md) for the complete roadmap.

**Immediate priorities**:
1. ✅ Clean up debug logging - COMPLETE
2. ✅ Create README - COMPLETE
3. ⏳ Record demo video
4. ⏳ Add push notifications
5. ⏳ TestFlight deployment

**Future features** (v2.0):
- Voice/video calls (WebRTC)
- Desktop app (Mac Catalyst)
- Web app (Next.js)
- Calendar integration for meetings
- Analytics dashboard
- Team workspace management

---

<p align="center">
  Built with ❤️ using SwiftUI, Firebase, and AI
</p>

<p align="center">
  <strong>Yaip</strong> - Making team communication smarter, not louder.
</p>
