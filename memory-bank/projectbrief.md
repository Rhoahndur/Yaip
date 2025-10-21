# Project Brief: Yaip

## Project Overview
**Yaip** is an AI-enhanced messaging application for remote software teams, built with Swift/SwiftUI and Firebase. The app combines WhatsApp-quality messaging infrastructure with contextual AI features that surface priority messages, extract action items, and proactively assist with scheduling.

## Target User
**Remote Team Professional** - Software teams struggling with information overload and async coordination across distributed work environments.

## Core Value Proposition
Reliable messaging infrastructure + contextual AI that makes team communication actionable without leaving the conversation flow.

## Project Scope

### MVP Requirements (Must Have)
- Real-time messaging with <500ms latency
- Offline persistence (messages survive force-quit)
- Offline queue (messages send on reconnect)
- Group chat (3+ people)
- No message loss in any scenario
- Works on actual iPhone hardware

### Core Features
1. **Authentication**: Email/password with Firebase Auth
2. **1-on-1 & Group Chat**: Real-time messaging with Firestore
3. **Local Persistence**: SwiftData for offline-first architecture
4. **Push Notifications**: FCM for message alerts
5. **User Presence**: Online/offline status with read receipts
6. **Media Support**: Image sending via Firebase Storage

### AI Features (Required)
1. **Thread Summarization**: Claude-powered conversation summaries
2. **Action Item Extraction**: Automatic task detection from conversations
3. **Smart Search**: Semantic + keyword search with Pinecone
4. **Priority Detection**: Automatic flagging of important messages
5. **Decision Tracking**: Auto-detect and catalog team decisions

### Advanced AI Feature
**Proactive Scheduling Assistant**: Automatically detects scheduling needs, analyzes availability, and suggests optimal meeting times directly in chat.

## Success Criteria
- ✅ Two physical devices can chat in real-time
- ✅ Messages persist after app restart
- ✅ Offline messages queue and sync
- ✅ Group chat works smoothly
- ✅ All AI features demonstrate real value
- ✅ Proactive assistant provides contextual suggestions
- ✅ Deployed to TestFlight with public link
- ✅ Demo video (5-7 minutes) showcasing all features

## Technical Approach
- **iOS**: Swift 5.9+, SwiftUI, iOS 17.0+
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Functions)
- **AI**: Anthropic Claude 3.5 Sonnet, OpenAI Embeddings, Pinecone Vector DB
- **Architecture**: MVVM with Services layer
- **Data Flow**: Real-time listeners + local persistence

## Constraints & Considerations
- Solo developer project (1 week timeline)
- Build vertically: complete one feature before starting next
- MVP messaging must be rock-solid before AI features
- Test on physical devices (simulators lie)
- Cost optimization: aggressive caching, rate limiting
- Target monthly cost: ~$0.23/user

## Deliverables
1. Working iOS app deployed to TestFlight
2. GitHub repository with comprehensive documentation
3. Demo video (5-7 minutes)
4. Persona brainlift document
5. Social post for project announcement

## Timeline
- **Phase 1 (Days 1-3)**: MVP messaging infrastructure (PRs #1-11)
- **Phase 2 (Days 4-6)**: AI features implementation (PRs #12-18)
- **Phase 3 (Day 7)**: Polish, testing, deployment (PRs #19-26)

## Key Technical Decisions
- Firebase for real-time infrastructure (proven, scalable)
- SwiftData for local persistence (modern, type-safe)
- Claude for AI features (excellent tool use, structured output)
- Pinecone for semantic search (purpose-built vector DB)
- Cloud Functions for AI backend (serverless, cost-effective)

