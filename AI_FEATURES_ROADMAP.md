# AI Features Roadmap

## Completed Features ✅
- Thread Summarization
- Action Items Extraction
- Meeting Suggestions (basic)

## Future Enhancements 📋

### Meeting Suggestions - Calendar Integration
**Current State**: AI analyzes conversation text only and suggests times based on:
- What people said in chat
- General business hours (9am-5pm)
- Common meeting patterns

**Potential Improvements**:
1. **iOS Calendar Integration (EventKit)**
   - Check local device calendars for conflicts
   - Mark busy/free times for current user

2. **Google Calendar API**
   - More comprehensive cross-platform availability
   - Requires OAuth setup
   - Can check availability for all participants (if they grant access)

3. **Microsoft Graph API (Outlook/Office 365)**
   - Enterprise calendar integration
   - Good for business teams

4. **Hybrid Approach**
   - AI suggests times based on conversation
   - Users manually mark their availability
   - Show which participants confirmed

5. **Calendar Event Creation**
   - Once time is selected, automatically create calendar event
   - Send invites to all participants
   - Add meeting details from conversation context

### Other Planned Features
- Decision Tracking
- Priority Detection
- Smart Search
- Push Notifications for AI insights
