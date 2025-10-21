# Technical Context: Yaip

## Technology Stack

### iOS Application

#### Core Technologies
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (declarative, iOS 17.0+)
- **Minimum iOS Version**: 17.0
- **Architecture**: MVVM + Services

#### Apple Frameworks
- **SwiftData**: Local persistence and offline storage
- **Combine**: Reactive programming (with `@Published`)
- **PhotosUI**: Image picker for media messages
- **UserNotifications**: Push notification handling
- **EventKit**: Optional calendar/reminders integration

### Backend Services

#### Firebase Stack
- **Firebase Auth**: Email/password authentication
- **Cloud Firestore**: Real-time NoSQL database
- **Firebase Storage**: Image/media file storage
- **Cloud Messaging (FCM)**: Push notifications
- **Cloud Functions**: Serverless backend (Node.js 18)
- **Firebase Analytics**: Usage tracking
- **Crashlytics**: Error and crash reporting

#### External AI Services
- **Anthropic Claude API**
  - Model: Claude 3.5 Sonnet (`claude-3-5-sonnet-20241022`)
  - Use: Text generation, structured output via tool use
  - Features: Summarization, action items, decisions, scheduling

- **OpenAI API**
  - Model: `text-embedding-3-small`
  - Use: Generate vector embeddings for semantic search
  - Context: Message text → 1536-dimension vectors

- **Pinecone**
  - Purpose: Vector database for semantic search
  - Index: Message embeddings with metadata
  - Query: Find semantically similar messages

### Development Tools

#### Package Management
- **Swift Package Manager (SPM)**: iOS dependencies

#### Key Dependencies
```swift
// Firebase iOS SDK
.package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseStorage
  - FirebaseMessaging
  - FirebaseFunctions
  - FirebaseAnalytics
  - FirebaseCrashlytics

// Optional: Image caching
.package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI", from: "2.0.0")
```

#### Cloud Functions Dependencies
```json
{
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0",
    "@anthropic-ai/sdk": "^0.9.0",
    "@pinecone-database/pinecone": "^1.1.0",
    "openai": "^4.20.0"
  }
}
```

## Development Environment Setup

### Prerequisites
1. **Xcode 15+** with iOS 17+ SDK
2. **Apple Developer Account** (for push notifications, TestFlight)
3. **Firebase Project** created at console.firebase.google.com
4. **Node.js 18+** for Cloud Functions development
5. **Firebase CLI**: `npm install -g firebase-tools`

### Initial Setup Steps

#### 1. Firebase Project Configuration
```bash
# Login to Firebase
firebase login

# Initialize Firebase in project directory
firebase init
# Select: Firestore, Functions, Storage, Hosting

# Download GoogleService-Info.plist from Firebase Console
# Add to Xcode project root
```

#### 2. API Keys Configuration
```bash
# Set Cloud Function environment variables
firebase functions:config:set \
  anthropic.key="YOUR_ANTHROPIC_KEY" \
  pinecone.key="YOUR_PINECONE_KEY" \
  openai.key="YOUR_OPENAI_KEY"

# For local development, create .env file (add to .gitignore)
```

#### 3. Xcode Project Setup
1. Open MessageAI.xcodeproj
2. Set bundle ID: `com.yourname.MessageAI`
3. Set minimum iOS version: 17.0
4. Add Firebase via SPM
5. Add `GoogleService-Info.plist` to project
6. Enable capabilities:
   - Push Notifications
   - Background Modes (Remote notifications, Background fetch)

#### 4. Initialize Firebase in App
```swift
// MessageAIApp.swift
import Firebase

@main
struct MessageAIApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Firestore Structure

### Collections & Subcollections
```
/users/{userID}
  - displayName: String
  - email: String
  - profileImageURL: String?
  - status: String ("online", "offline", "away")
  - lastSeen: Timestamp
  - fcmToken: String?
  - createdAt: Timestamp

/conversations/{conversationID}
  - type: String ("oneOnOne", "group")
  - participants: Array<String>
  - name: String? (for groups)
  - imageURL: String?
  - lastMessage: Map {text, senderID, timestamp}
  - createdAt: Timestamp
  - updatedAt: Timestamp
  - unreadCount: Map {userID: Int}
  
  /messages/{messageID}
    - conversationID: String
    - senderID: String
    - text: String?
    - mediaURL: String?
    - mediaType: String? ("image", "video")
    - timestamp: Timestamp
    - status: String ("sending", "sent", "delivered", "read")
    - readBy: Array<String>
  
  /decisions/{decisionID}
    - decision: String
    - reasoning: String
    - alternatives: Array<String>
    - participants: Array<String>
    - messageID: String
    - timestamp: Timestamp

/userPresence/{userID}
  - status: String ("online", "offline", "away")
  - lastSeen: Timestamp

/userPriority/{userID}
  - {conversationID}: {
      count: Int,
      messages: Array<String>
    }

/aiCache/{cacheKey}
  - data: Any
  - timestamp: Number
  - conversationID: String
```

### Indexes Required
```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "conversationID", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "conversations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "participants", "arrayConfig": "CONTAINS" },
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

## Firebase Storage Structure
```
/conversations/{conversationID}/
  - {messageID}.jpg
  - {messageID}_thumb.jpg
```

## Security Rules

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function
    function isParticipant(conversationID) {
      return request.auth.uid in 
        get(/databases/$(database)/documents/conversations/$(conversationID)).data.participants;
    }
    
    match /users/{userID} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userID;
    }
    
    match /conversations/{conversationID} {
      allow read: if request.auth.uid in resource.data.participants;
      allow create: if request.auth.uid in request.resource.data.participants;
      allow update: if request.auth.uid in resource.data.participants;
      
      match /messages/{messageID} {
        allow read: if isParticipant(conversationID);
        allow create: if isParticipant(conversationID) 
                      && request.auth.uid == request.resource.data.senderID;
      }
      
      match /decisions/{decisionID} {
        allow read: if isParticipant(conversationID);
        // Write only from Cloud Functions
      }
    }
    
    match /userPresence/{userID} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userID;
    }
    
    match /userPriority/{userID} {
      allow read: if request.auth.uid == userID;
      // Write only from Cloud Functions
    }
    
    match /aiCache/{cacheKey} {
      allow read, write: if false; // Server-only
    }
  }
}
```

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /conversations/{conversationID}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024  // 5MB
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## Cloud Functions Architecture

### Function Types

#### 1. Callable Functions (HTTPS)
- `generateThreadSummary`: Summarize conversation
- `extractActionItems`: Extract tasks from messages
- `searchMessages`: Semantic + keyword search
- `analyzeSchedulingIntent`: Check if scheduling discussion

#### 2. Firestore Triggers
- `sendMessageNotification`: Send FCM on new message
- `embedMessage`: Generate embeddings for search
- `detectDecision`: Auto-detect decisions
- `detectSchedulingIntent`: Trigger proactive assistant

#### 3. Scheduled Functions
- `detectPriorityMessages`: Run every 30 min, score unread messages

### Function Structure
```
functions/
├── index.js                    # Export all functions
├── src/
│   ├── ai/
│   │   ├── summarization.js
│   │   ├── actionItems.js
│   │   ├── decisions.js
│   │   ├── priority.js
│   │   └── proactiveAssistant.js
│   ├── messaging/
│   │   └── sendNotification.js
│   └── utils/
│       ├── anthropic.js        # Claude API wrapper
│       ├── pinecone.js         # Vector DB client
│       ├── cache.js            # Response caching
│       └── rateLimit.js        # Rate limiting
```

## API Key Management

### Environment Variables
```bash
# Cloud Functions config (production)
firebase functions:config:set anthropic.key="sk-ant-..."
firebase functions:config:set pinecone.key="..."
firebase functions:config:set openai.key="sk-..."

# Local development (.env file)
ANTHROPIC_API_KEY=sk-ant-...
PINECONE_API_KEY=...
OPENAI_API_KEY=sk-...
```

### Accessing in Code
```javascript
// Production
const anthropic = new Anthropic({
    apiKey: functions.config().anthropic.key
});

// Local development
const anthropic = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY
});
```

## Testing Environment

### Local Development
```bash
# Run Firebase emulators
firebase emulators:start

# Emulators available:
# - Auth: localhost:9099
# - Firestore: localhost:8080
# - Functions: localhost:5001
# - Storage: localhost:9199
```

### iOS Testing
- **Simulator**: Use for rapid UI iteration (doesn't support push notifications)
- **Physical Device**: Required for:
  - Push notifications
  - Camera/photo library
  - Real-time performance testing
  - Network condition testing (use Network Link Conditioner)

### Testing Tools
- **Network Link Conditioner**: Simulate 3G/4G/5G conditions
- **Xcode Instruments**: Profile CPU, memory, network
- **Firebase Emulator Suite**: Local backend testing
- **Postman**: Test Cloud Functions directly

## Deployment Configuration

### Firebase Hosting (Optional)
For documentation or landing page:
```bash
firebase deploy --only hosting
```

### Cloud Functions Deployment
```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:sendMessageNotification
```

### Firestore Rules & Indexes
```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes
```

### iOS Build Configuration

#### Development
- Bundle ID: `com.yourname.MessageAI`
- Signing: Development certificate
- Push: Development APNs certificate

#### Production (TestFlight/App Store)
- Bundle ID: `com.yourname.MessageAI`
- Signing: Distribution certificate
- Push: Production APNs certificate
- Upload via Xcode Organizer

## Technical Constraints

### API Limits
- **Claude API**: 
  - Rate: 50 requests/min (tier-dependent)
  - Context: 200K tokens
  - Cost: $3/1M input tokens, $15/1M output tokens

- **OpenAI Embeddings**:
  - Rate: 3000 requests/min
  - Cost: $0.02/1M tokens

- **Pinecone**:
  - Free tier: 1M vectors
  - Starter: $70/month (100M vectors)

- **Firebase**:
  - Spark (free): 50K document reads/day
  - Blaze (pay-as-go): $0.06/100K reads
  - Cloud Functions: Free tier 125K invocations/month

### Performance Targets
- Message send latency: <500ms
- Message receive latency: <500ms (real-time)
- AI summary generation: <10s
- Search query: <2s
- Image upload: <5s (for 5MB image)

## Troubleshooting

### Common Issues

**Firebase not configured**
```
Solution: Ensure GoogleService-Info.plist in project
```

**Push notifications not working**
```
Solution: 
1. Upload APNs key to Firebase Console
2. Enable Push Notifications capability in Xcode
3. Request permission in code
```

**Firestore permission denied**
```
Solution: Check security rules, verify user authenticated
```

**Cloud Function timeout**
```javascript
// Increase timeout
exports.longFunction = functions
  .runWith({ timeoutSeconds: 300 })
  .https.onCall(async (data, context) => { ... });
```

**High costs**
```
Solution:
- Implement aggressive caching (1hr for summaries)
- Rate limit AI features (10/day per user)
- Use pagination for queries
- Monitor Firebase usage dashboard
```

