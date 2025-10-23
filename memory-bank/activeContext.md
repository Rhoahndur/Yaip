# Active Context: Yaip

## Current Status
**Project State**: MVP Refactored & Stable - Offline/Online Sync Working  
**Date**: October 23, 2025  
**Phase**: MVP Post-Refactor - Ready for AI Features  
**Bundle ID**: yaip.tavern
**iOS Version**: 17.6+
**Completion**: 95% MVP, 0% AI Features
**Note**: Using Local Notifications (not APNs) for simulator testing

## Current Work Focus

### Recently Completed: Major Refactoring (Phases 1-5)
**Status**: ✅ Complete (~1.5 hours, under 4-hour estimate)

We completed a comprehensive 5-phase refactoring to fix critical offline/online sync issues, image handling bugs, and message state management:

1. **Phase 1 - Network State Centralization** ✅
   - Created `NetworkStateViewModifier.swift` with `.networkStateBanner()` and `.onNetworkReconnect { }` view modifiers
   - Removed duplicate network monitoring code across views
   - Unified offline banner display

2. **Phase 2 - Image Upload Manager** ✅
   - Created `ImageUploadManager.swift` singleton with state machine
   - States: `.notStarted → .cached → .uploading → .uploaded` or `.failed`
   - Implemented automatic image caching and cleanup after upload
   - Retry strategy: Auto-retry once, then show "Tap to retry" button
   - Observable states for UI updates

3. **Phase 3 - Message Lifecycle Simplification** ✅
   - Added `.staged` and `.synced` states to `MessageStatus` enum
   - Clear state ownership: Local (`.staged`, `.sending`, `.failed`) vs Network (`.sent`, `.delivered`, `.read`)
   - Smart merge logic in `ChatViewModel.startListening()` respects state ownership
   - Firestore listeners only update confirmed messages

4. **Phase 4 - Simplified Merge Logic** ✅ (Integrated into Phase 3)
   - Firestore as source of truth for synced messages
   - Local-only for pending/staged messages
   - Automatic cleanup of successfully uploaded images

5. **Phase 5 - Polish & Testing** ✅
   - Removed verbose debug logs
   - Comprehensive testing of offline scenarios
   - Fixed build errors and type inference issues

### Immediate Next Steps
1. **Continue Testing** (Ongoing)
   - Multi-user offline/online scenarios
   - Image + text message combinations
   - Group chat stability
   - Edge cases (force quit, network toggle, etc.)

2. **AI Features** (Next Phase)
   - Begin PR #12: AI Infrastructure Setup
   - Acquire API keys (Anthropic, OpenAI, Pinecone)
   - Setup Cloud Functions for AI processing

## Recent Changes
- ✅ **PR #1-11 Complete**: Full MVP implementation done
- ✅ **Major Refactoring Complete**: Offline/online sync now working reliably
- ✅ Created `ImageUploadManager` for unified image handling
- ✅ Created `NetworkStateViewModifier` for centralized network UI
- ✅ Implemented message lifecycle states (`.staged`, `.sending`, `.failed`, `.sent`, `.delivered`, `.read`)
- ✅ Fixed race conditions in message sync
- ✅ Implemented smart merge logic for Firestore + local messages
- ✅ Added image caching with automatic cleanup
- ✅ Implemented auto-retry + manual retry for failed messages
- ✅ Fixed "generic user" auto-sign-in bug
- ✅ Enhanced unread message indicators (Signal-like design)
- ✅ Fixed false offline detection in simulators
- ✅ Implemented pending conversation flow (no blank chats)
- ✅ Added image preview modal with captions
- ✅ Fixed numerous build errors and type inference issues

## Active Decisions & Considerations

### Key Technical Decisions Made
1. **Swift/SwiftUI over React Native**: Native performance, better Apple ecosystem integration
2. **Firebase over custom backend**: Faster to implement, proven scalability
3. **MVVM architecture**: Best fit for SwiftUI's reactive patterns
4. **Offline-first approach**: Better UX, handles poor connectivity
5. **Claude for AI**: Superior tool use and structured output capabilities
6. **Pinecone for vectors**: Purpose-built, easier than self-hosting

### Considerations in Flight

#### 1. Testing Strategy
**Question**: How much testing to implement in week 1?  
**Current thinking**: 
- Manual testing on physical devices for MVP (PR #11)
- Unit tests for models and critical logic (PR #23)
- UI tests for main flows (PR #23)
- Defer comprehensive test suite until post-MVP

**Decision needed**: Balance between speed and quality

#### 2. Image Optimization
**Question**: Generate thumbnails or compress only?  
**Current thinking**:
- MVP: Compression only (simpler)
- Post-MVP: Add thumbnail generation if performance issues
- Use 500KB max file size

**Decision**: Start simple, optimize if needed

#### 3. Calendar Integration for Proactive Assistant
**Question**: Mock availability or implement real calendar integration?  
**Current thinking**:
- MVP: Mock availability (simpler, no OAuth)
- Post-MVP: Real EventKit integration
- Focus on demonstrating the concept

**Decision**: Mock for week 1, note as future enhancement

#### 4. Dark Mode Support
**Question**: Implement dark mode in week 1?  
**Current thinking**:
- PR #20 includes dark mode in "UI Polish"
- Use system colors where possible for automatic support
- Test in both light and dark during final polish

**Decision**: Support basic dark mode, don't obsess over custom colors yet

## What's Working
- ✅ Authentication system (signup, login, logout, persistence)
- ✅ Real-time conversation list with unread indicators
- ✅ 1-on-1 messaging with typing indicators
- ✅ Group chat with sender names and read receipts
- ✅ Image upload with compression and caching
- ✅ Image + text combined messages with preview modal
- ✅ Message status tracking (staged → sending → sent → delivered → read)
- ✅ Offline message queue with automatic retry
- ✅ Manual retry for failed messages ("Tap to retry")
- ✅ Offline persistence with SwiftData + image caching
- ✅ User search and conversation creation
- ✅ Pending conversation flow (first message creates chat)
- ✅ Optimistic UI for sending messages
- ✅ Presence system (online/away/offline status) with real-time updates
- ✅ Network status banner with reconnect triggers
- ✅ Smart merge logic (local + Firestore sync)

## What Needs Testing
- ✅ Login flow with fresh users (fixed)
- ✅ Multi-user real-time sync (working)
- ✅ Group chat with 3+ users (working)
- ✅ Image sending end-to-end (working)
- ✅ Offline message queue and sync (working)
- ✅ Image offline handling (working)
- 🔄 Edge cases: Force quit during upload, rapid network toggles
- 🔄 Performance: Large conversations (1000+ messages)
- 🔄 Group chat: 10+ participants

## What's Not Started Yet
- AI features (PRs #12-18)
- Security rules refinement (PR #19)
- UI polish and animations (PR #20)
- Performance optimization (PR #21)
- TestFlight deployment (PR #25)
- Demo video (PR #26)
- API key acquisition (Anthropic, OpenAI, Pinecone)

## Blockers & Risks

### Current Blockers
**None** - All critical MVP issues resolved ✅

### Potential Risks
1. **API Costs**: AI features could get expensive
   - **Mitigation**: Aggressive caching (1hr for summaries), rate limiting (10/day)
   
2. **Push Notifications Setup**: Requires Apple Developer account
   - **Mitigation**: Can test most features without push initially
   
3. **Pinecone Costs**: Vector DB not free
   - **Mitigation**: Start with free tier (1M vectors), evaluate usage
   
4. **Time Constraint**: 94 hours estimated for 7 days = 13 hours/day
   - **Mitigation**: MVP first (PRs #1-11), AI features can be simplified if needed

## Open Questions

### Technical Questions
- [ ] **Q**: Use Firebase Functions v1 or v2?  
  **A**: TBD - Check latest docs, v2 is newer but v1 more stable

- [ ] **Q**: Store message history limit?  
  **A**: TBD - Consider cost vs UX, maybe 1 year?

- [ ] **Q**: Image thumbnail size?  
  **A**: TBD - Standard: 200x200 for previews, full size for viewing

### Product Questions
- [ ] **Q**: Allow message editing/deleting?  
  **A**: Not in MVP, too complex (need to update all clients, AI context)

- [ ] **Q**: Support reactions to messages?  
  **A**: Not in MVP, nice-to-have for v2

- [ ] **Q**: Voice messages?  
  **A**: Not in MVP (listed as Week 2 enhancement in PRD)

## Upcoming Milestones

### Week 1 Critical Path
- **Day 1 (Oct 20)**: PRs #1-3 (Setup, Models, Auth) ✅ Memory Bank initialized
- **Day 2 (Oct 21)**: PRs #4-6 (Conversations, Messaging, Persistence)
- **Day 3 (Oct 22)**: PRs #7-11 (Groups, Presence, Push, Media, Testing)
- **📹 Checkpoint**: Record MVP demo video
- **Day 4 (Oct 23)**: PRs #12-15 (AI setup, Summarization, Action Items, Search)
- **Day 5 (Oct 24)**: PRs #16-18 (Priority, Decisions, Proactive Assistant)
- **Day 6 (Oct 25)**: PRs #19-24 (Security, Polish, Performance, Testing)
- **Day 7 (Oct 26)**: PRs #25-26 (TestFlight deployment, Demo video)

### Success Metrics for Each Phase
**MVP Complete (Day 3)**:
- ✅ Two devices can chat in real-time
- ✅ Messages persist offline
- ✅ Group chat works
- ✅ Push notifications delivered

**AI Features Complete (Day 5)**:
- ✅ All 5 required AI features working
- ✅ Proactive assistant demonstrable
- ✅ AI responses accurate and useful

**Deployment Ready (Day 7)**:
- ✅ TestFlight build available
- ✅ Demo video complete
- ✅ Documentation comprehensive
- ✅ Ready to submit

## Context for Next Session

### When I return to this project, start by:
1. Reading activeContext.md (this file) for current state
2. Checking progress.md for what's been completed
3. Reviewing the next PR in Tasks.md
4. Reading relevant sections of systemPatterns.md for implementation guidance

### Files to prioritize reading:
- **activeContext.md**: Current focus and decisions
- **progress.md**: What's done vs. what's left
- **Tasks.md**: Next specific tasks
- **systemPatterns.md**: How to implement features
- **PRD.md**: Reference for feature requirements

## Notes & Observations

### Project Strengths
- Comprehensive planning reduces decision paralysis
- Clear separation MVP vs. AI features
- Realistic timeline with buffer
- Strong architectural foundation

### Areas of Concern
- Time is tight - need to stay focused
- AI feature testing may surface unexpected complexity
- Push notification setup can be tricky
- Cost monitoring important from day 1

### Lessons for Implementation
1. **Test on hardware early**: Don't wait until end of week
2. **Commit small and often**: Easier to debug
3. **One PR at a time**: Don't jump ahead
4. **Cache aggressively**: AI costs add up fast
5. **Mock when appropriate**: Calendar integration, for example

## Communication Log
- Oct 20, 2025: User requested Memory Bank initialization
- Oct 20, 2025: Created all 6 core Memory Bank files
- Oct 21, 2025: Completed PRs #1-11 (MVP build complete)
- Oct 21, 2025: **MVP BUILD COMPLETE** - Ready for user testing phase
- Oct 22-23, 2025: User reported critical offline/online sync issues
- Oct 23, 2025: User reported messages not showing up when offline
- Oct 23, 2025: User reported images sent offline showing as empty messages
- Oct 23, 2025: User reported network status not updating correctly
- Oct 23, 2025: User reported blank conversations appearing before first message sent
- Oct 23, 2025: User reported auto-sign-in as generic user after database reset
- Oct 23, 2025: User requested comprehensive code review and refactoring plan
- Oct 23, 2025: Proposed 5-phase refactoring plan (user approved)
- Oct 23, 2025: **REFACTORING COMPLETE** (Phases 1-5, ~1.5 hours)
- Oct 23, 2025: All critical MVP issues resolved
- Oct 23, 2025: User requested to update Memory Bank and use it consistently

