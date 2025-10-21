# MVP Test Checklist

## Authentication
- [ ] Sign up with valid email/password
- [ ] Sign in with existing account
- [ ] Sign out
- [ ] Handle invalid email format
- [ ] Handle weak password
- [ ] Handle duplicate email error
- [ ] User persists after app restart

## Conversations
- [ ] View empty conversation list
- [ ] Create new 1-on-1 conversation
- [ ] Create new group conversation
- [ ] View conversation list with messages
- [ ] Search for users
- [ ] Conversation shows last message
- [ ] Conversation shows timestamp
- [ ] Delete conversation (swipe to delete)
- [ ] Real-time conversation updates

## Messaging
- [ ] Send text message
- [ ] Send image message
- [ ] Send text + image message
- [ ] View sent messages (blue bubble, right-aligned)
- [ ] View received messages (gray bubble, left-aligned)
- [ ] Message status icons (sending, sent, delivered, read)
- [ ] Auto-scroll to new messages
- [ ] Typing indicator (1-on-1 chats)
- [ ] Real-time message updates
- [ ] Optimistic UI for sending
- [ ] Handle failed message sending
- [ ] Empty state for no messages

## Group Chats
- [ ] Create group with multiple users
- [ ] Send message in group
- [ ] View sender names in group messages
- [ ] All group members see messages
- [ ] Group conversation updates for all members

## Presence & Read Receipts
- [ ] User goes online on login
- [ ] User goes offline on logout
- [ ] Read receipts update (checkmarks turn blue)
- [ ] Messages marked as read when viewing

## Media
- [ ] Pick image from photo library
- [ ] Preview selected image before sending
- [ ] Cancel image selection
- [ ] Upload image to Firebase Storage
- [ ] Display images in message bubbles
- [ ] Handle image upload errors

## Local Persistence
- [ ] Messages persist offline
- [ ] Conversations persist offline
- [ ] Messages load from local storage first
- [ ] Pending messages sync when online
- [ ] App works without internet (read-only)

## Error Handling
- [ ] Display error messages for failed operations
- [ ] Gracefully handle network errors
- [ ] Handle Firestore permission errors
- [ ] Handle Firebase Auth errors
- [ ] Handle Storage upload errors

## UI/UX
- [ ] Loading states shown appropriately
- [ ] Smooth animations and transitions
- [ ] Keyboard dismisses on scroll
- [ ] Text field auto-expands (up to 5 lines)
- [ ] Send button disabled when empty
- [ ] Profile images load and display
- [ ] Timestamps formatted correctly
- [ ] Navigation works smoothly

## Edge Cases
- [ ] Empty conversation list
- [ ] Empty message list
- [ ] Very long messages
- [ ] Large images
- [ ] Rapid message sending
- [ ] Multiple users in same conversation
- [ ] User searches with no results
- [ ] Special characters in messages
- [ ] Emoji in messages

## Performance
- [ ] App launches quickly
- [ ] Conversations load smoothly
- [ ] Messages load smoothly
- [ ] Images load progressively
- [ ] No UI freezes
- [ ] Memory usage reasonable
- [ ] Battery usage reasonable

## Firebase Integration
- [ ] Firestore security rules enforced
- [ ] Authentication works properly
- [ ] Storage uploads work
- [ ] Real-time listeners work
- [ ] Batch writes work
- [ ] Timestamps sync correctly
- [ ] Indexes created for queries

## Notes
- Test on both iPhone and iPad simulators
- Test in both light and dark mode
- Test with various screen sizes
- Test with airplane mode enabled/disabled
- Test with multiple users simultaneously

