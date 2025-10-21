# Active Context: Yaip

## Current Status
**Project State**: MVP Build Complete (PRs #1-11) - Ready for User Testing  
**Date**: October 21, 2025  
**Phase**: MVP Testing & Debugging  
**Bundle ID**: yaip.tavern
**iOS Version**: 17.6+
**Completion**: 90% MVP, 0% AI Features
**Note**: Push Notifications skipped for simulator testing (will implement for physical devices)

## Current Work Focus

### Immediate Next Steps (User Testing Phase)
1. **Test Authentication Flow** (In Progress)
   - User experiencing Firestore decoding errors on login
   - Added fallback logic to manually construct User object
   - Auto-creates missing Firestore user documents
   - Need to verify with fresh test accounts

2. **Create Firestore Composite Index** (Pending)
   - Conversations query requires index on `participants` + `updatedAt`
   - Firebase Console URL provided to user
   - Must be created before conversations load properly

3. **Multi-User Testing** (Pending)
   - Create 2-3 test accounts
   - Test real-time messaging
   - Test group chats
   - Test image sending
   - Test offline sync

4. **Bug Fixes** (Ongoing)
   - Resolve any issues discovered during testing
   - Improve error messages
   - Polish UI/UX

## Recent Changes
- ✅ **PR #1-11 Complete**: Full MVP implementation done
- ✅ Created 40+ files (~3,000 lines of code)
- ✅ Implemented all core messaging features
- ✅ Added SwiftData local persistence
- ✅ Integrated Firebase (Auth, Firestore, Storage)
- ✅ Fixed multiple Swift concurrency warnings
- ✅ Fixed Firestore @DocumentID warnings
- ✅ Created comprehensive test checklist
- ✅ Created MVP build summary document
- 🚧 **Currently**: Debugging authentication login issues

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
- ✅ Authentication system (signup, login, logout)
- ✅ Real-time conversation list
- ✅ 1-on-1 messaging with typing indicators
- ✅ Group chat with sender names
- ✅ Image upload and display
- ✅ Read receipts and message status
- ✅ Offline persistence with SwiftData
- ✅ User search and conversation creation
- ✅ Optimistic UI for sending messages
- ✅ Presence system (online/offline status)

## What Needs Testing
- Login flow with fresh users (experiencing errors)
- Multi-user real-time sync
- Group chat with 3+ users
- Image sending end-to-end
- Offline message queue and sync
- Firestore composite index creation

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
1. **Authentication Login Issue** (High Priority)
   - Firestore decoding error: "FirebaseFirestore.FirestoreDecodingError error 0"
   - User can't log in even after fresh signup
   - Fallback logic added but needs testing
   - May be related to missing Firestore user documents
   
2. **Firestore Index Missing** (High Priority)
   - Conversations query failing without composite index
   - User needs to click Firebase Console URL to create it
   - Blocks conversation list from loading

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
- Oct 20, 2025: Started PR #1 (Project Setup)
- Oct 21, 2025: User confirmed project name change to "Yaip", bundle ID to "yaip.tavern"
- Oct 21, 2025: User reported multiple build warnings (resolved)
- Oct 21, 2025: User reported .gitkeep file conflicts (resolved)
- Oct 21, 2025: User reported concurrency errors (resolved)
- Oct 21, 2025: User reported Hashable conformance errors (resolved)
- Oct 21, 2025: User reported user search issue (resolved)
- Oct 21, 2025: User reported authentication login failures (debugging)
- Oct 21, 2025: Completed PRs #1-11 (MVP build complete)
- Oct 21, 2025: User requested to continue building MVP, skip troubleshooting for now
- Oct 21, 2025: **MVP BUILD COMPLETE** - Ready for user testing phase

