# RAG Smart Search Setup Guide
## Pinecone + N8N Integration for Yaip

This guide walks you through setting up a production-ready RAG (Retrieval Augmented Generation) pipeline for semantic search in Yaip using Pinecone and N8N.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Part 1: Pinecone Setup](#part-1-pinecone-setup)
4. [Part 2: N8N Workflow - Message Ingestion](#part-2-n8n-workflow---message-ingestion)
5. [Part 3: N8N Workflow - Smart Search](#part-3-n8n-workflow---smart-search)
6. [Part 4: iOS App Integration](#part-4-ios-app-integration)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

---

## Overview

### What is RAG?

**RAG (Retrieval Augmented Generation)** combines:
- **Retrieval**: Finding relevant documents using semantic search
- **Augmented**: Enhancing AI responses with retrieved context
- **Generation**: Using AI to generate intelligent responses

### How It Works in Yaip

```
User searches: "What did we decide about the project deadline?"
                        ↓
        Query converted to embeddings (vector)
                        ↓
        Pinecone finds semantically similar messages
                        ↓
        Retrieved messages + query → OpenAI GPT
                        ↓
        "Based on the conversation on Oct 15, the team decided
        to extend the deadline to Nov 30th..."
```

### Architecture

```
┌─────────────────┐
│   Yaip iOS App  │
└────────┬────────┘
         │
         │ HTTP Request
         ↓
┌─────────────────┐
│   N8N Webhook   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐     ┌──────────────┐
│  OpenAI API     │────→│  Embeddings  │
│ (text-embedding)│     │   (Vectors)  │
└─────────────────┘     └──────┬───────┘
                               │
                               ↓
                        ┌─────────────┐
                        │  Pinecone   │
                        │   Search    │
                        └──────┬──────┘
                               │
                               ↓
                        ┌─────────────┐
                        │  OpenAI GPT │
                        │  (Answer)   │
                        └─────────────┘
```

---

## Prerequisites

### Required Accounts

1. **Pinecone** - Vector database
   - Free tier: 100K vectors
   - Sign up: https://www.pinecone.io/

2. **OpenAI** - For embeddings and GPT
   - API key required
   - Sign up: https://platform.openai.com/

3. **N8N** - Workflow automation
   - Already set up (from N8N_SETUP.md)

### Required Knowledge

- Basic understanding of APIs
- Familiarity with JSON
- Access to Firestore (already configured)

---

## Part 1: Pinecone Setup

### Step 1: Create Pinecone Account

1. Go to [Pinecone](https://www.pinecone.io/)
2. Click **"Sign Up"**
3. Complete registration
4. Verify email

### Step 2: Create Index

1. In Pinecone dashboard, click **"Create Index"**
2. Configure:
   - **Name**: `yaip-messages`
   - **Dimensions**: `1536` (OpenAI text-embedding-ada-002 dimensions)
   - **Metric**: `cosine` (for semantic similarity)
   - **Pod Type**: `p1` (free tier)
   - **Replicas**: `1`
   - **Pods**: `1`

3. Click **"Create Index"**

### Step 3: Get API Key

1. In Pinecone dashboard, go to **"API Keys"**
2. Copy your **API Key**
3. Copy your **Environment** (e.g., `us-east-1-aws`)
4. Save both for later

**Example:**
```
API Key: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Environment: us-east-1-aws
Index Name: yaip-messages
```

---

## Part 2: N8N Workflow - Message Ingestion

This workflow runs whenever a new message is sent, creating embeddings and storing them in Pinecone.

### Workflow Overview

```
Firestore Trigger → Extract Message → Create Embedding → Store in Pinecone
```

### Step 1: Create New Workflow

1. Open N8N
2. Click **"New Workflow"**
3. Name: `Yaip - Message Ingestion (Pinecone)`

### Step 2: Add Firestore Trigger

**Node: Firestore Trigger**

1. Add **"Firestore Trigger"** node
2. Configure:
   - **Collection**: `conversations/{conversationId}/messages`
   - **Event**: `Document Created`
   - **Credential**: Your Firebase service account

3. This triggers when new messages are created

### Step 3: Add OpenAI Embeddings Node

**Node: OpenAI**

1. Add **"HTTP Request"** node
2. Configure:
   - **Method**: `POST`
   - **URL**: `https://api.openai.com/v1/embeddings`
   - **Authentication**: `Header Auth`
     - **Name**: `Authorization`
     - **Value**: `Bearer YOUR_OPENAI_API_KEY`
   - **Body**:
     ```json
     {
       "model": "text-embedding-ada-002",
       "input": "{{ $json.text }}"
     }
     ```

3. This converts message text to vector embeddings

### Step 4: Add Pinecone Upsert Node

**Node: Pinecone Upsert**

1. Add **"HTTP Request"** node
2. Configure:
   - **Method**: `POST`
   - **URL**: `https://yaip-messages-YOUR_PROJECT.svc.YOUR_ENVIRONMENT.pinecone.io/vectors/upsert`
   - **Authentication**: `Header Auth`
     - **Name**: `Api-Key`
     - **Value**: `YOUR_PINECONE_API_KEY`
   - **Body**:
     ```json
     {
       "vectors": [
         {
           "id": "{{ $json.messageId }}",
           "values": {{ $node["OpenAI"].json["data"][0]["embedding"] }},
           "metadata": {
             "conversationId": "{{ $json.conversationId }}",
             "text": "{{ $json.text }}",
             "senderID": "{{ $json.senderID }}",
             "timestamp": "{{ $json.timestamp }}"
           }
         }
       ]
     }
     ```

### Step 5: Save and Activate

1. Click **"Save"**
2. Toggle **"Active"** to enable the workflow

**Now**: Every new message automatically gets indexed in Pinecone! 🎉

---

## Part 3: N8N Workflow - Smart Search

This workflow handles search queries from the iOS app.

### Workflow Overview

```
Webhook → Create Query Embedding → Search Pinecone → GPT Answer → Return Results
```

### Step 1: Create New Workflow

1. Open N8N
2. Click **"New Workflow"**
3. Name: `Yaip - Smart Search (RAG)`

### Step 2: Add Webhook Trigger

**Node: Webhook**

1. Add **"Webhook"** node
2. Configure:
   - **HTTP Method**: `POST`
   - **Path**: `smart-search`
   - **Authentication**: `Header Auth`
     - **Header Name**: `Authorization`
     - **Expected Value**: `Bearer YOUR_SECRET_TOKEN`

3. Copy the webhook URL (e.g., `https://your-n8n.com/webhook/smart-search`)

**Expected Request Body:**
```json
{
  "feature": "smart_search",
  "conversationID": "abc123",
  "userID": "user456",
  "parameters": {
    "query": "What did we decide about the deadline?"
  }
}
```

### Step 3: Add Query Embedding Node

**Node: OpenAI Query Embedding**

1. Add **"HTTP Request"** node
2. Configure:
   - **Method**: `POST`
   - **URL**: `https://api.openai.com/v1/embeddings`
   - **Authentication**: `Header Auth`
     - **Name**: `Authorization`
     - **Value**: `Bearer YOUR_OPENAI_API_KEY`
   - **Body**:
     ```json
     {
       "model": "text-embedding-ada-002",
       "input": "{{ $json.body.parameters.query }}"
     }
     ```

### Step 4: Add Pinecone Query Node

**Node: Pinecone Query**

1. Add **"HTTP Request"** node
2. Configure:
   - **Method**: `POST`
   - **URL**: `https://yaip-messages-YOUR_PROJECT.svc.YOUR_ENVIRONMENT.pinecone.io/query`
   - **Authentication**: `Header Auth`
     - **Name**: `Api-Key`
     - **Value**: `YOUR_PINECONE_API_KEY`
   - **Body**:
     ```json
     {
       "vector": {{ $node["OpenAI Query Embedding"].json["data"][0]["embedding"] }},
       "topK": 5,
       "includeMetadata": true,
       "filter": {
         "conversationId": "{{ $json.body.conversationID }}"
       }
     }
     ```

**This returns the 5 most relevant messages**

### Step 5: Add Function Node to Format Context

**Node: Format Context**

1. Add **"Code"** node (JavaScript)
2. Configure:
   ```javascript
   const matches = items[0].json.matches;

   // Extract messages from Pinecone results
   const context = matches.map(match => {
     return `[${match.metadata.timestamp}] ${match.metadata.senderID}: ${match.metadata.text}`;
   }).join('\n\n');

   return [
     {
       json: {
         context: context,
         query: items[0].json.body.parameters.query,
         conversationID: items[0].json.body.conversationID
       }
     }
   ];
   ```

### Step 6: Add OpenAI GPT Node

**Node: OpenAI GPT**

1. Add **"HTTP Request"** node
2. Configure:
   - **Method**: `POST`
   - **URL**: `https://api.openai.com/v1/chat/completions`
   - **Authentication**: `Header Auth`
     - **Name**: `Authorization`
     - **Value**: `Bearer YOUR_OPENAI_API_KEY`
   - **Body**:
     ```json
     {
       "model": "gpt-4",
       "messages": [
         {
           "role": "system",
           "content": "You are a helpful assistant that answers questions based on chat message history. Use the provided context to answer the user's question accurately. If the context doesn't contain relevant information, say so."
         },
         {
           "role": "user",
           "content": "Context from conversation:\n\n{{ $json.context }}\n\nQuestion: {{ $json.query }}"
         }
       ],
       "temperature": 0.7,
       "max_tokens": 500
     }
     ```

### Step 7: Add Response Node

**Node: Format Response**

1. Add **"Code"** node (JavaScript)
2. Configure:
   ```javascript
   const gptResponse = items[0].json.choices[0].message.content;
   const matches = items[0].json.matches || [];

   // Format search results
   const results = matches.map(match => ({
     messageID: match.id,
     text: match.metadata.text,
     senderID: match.metadata.senderID,
     timestamp: match.metadata.timestamp,
     relevanceScore: match.score,
     snippet: match.metadata.text.substring(0, 200)
   }));

   return [
     {
       json: {
         success: true,
         answer: gptResponse,
         searchResults: results,
         totalResults: results.length,
         timestamp: new Date().toISOString(),
         conversationID: items[0].json.conversationID
       }
     }
   ];
   ```

### Step 8: Save and Activate

1. Click **"Save"**
2. Toggle **"Active"**

**Webhook URL Example:**
```
https://your-n8n-instance.com/webhook/smart-search
```

---

## Part 4: iOS App Integration

### Step 1: Update Config.xcconfig

Add Pinecone configuration:

```bash
# Config.xcconfig

# Existing N8N config
N8N_WEBHOOK_URL = https://your-n8n-instance.com/webhook
N8N_AUTH_TOKEN = your_secret_token_here

# Add Pinecone config (optional, only if calling directly from app)
PINECONE_API_KEY = your_pinecone_api_key
PINECONE_ENVIRONMENT = us-east-1-aws
PINECONE_INDEX = yaip-messages
```

### Step 2: Update N8NService.swift

The smart search already calls N8N, so we just need to ensure the endpoint is correct:

```swift
// File: N8NService.swift

func searchMessages(conversationID: String, query: String) async throws -> [SearchResult] {
    let request = AIRequest(
        feature: "smart_search",
        conversationID: conversationID,
        userID: AuthManager.shared.currentUserID ?? "",
        parameters: [
            "query": query
        ]
    )

    do {
        print("📤 Calling RAG Smart Search...")
        print("   URL: \(baseURL)/smart-search")
        print("   Query: \(query)")

        let response = try await callWebhook(
            request: request,
            responseType: SmartSearchResponse.self
        )

        print("✅ RAG Search successful")
        print("   Found: \(response.totalResults) results")
        print("   AI Answer: \(response.answer.prefix(100))...")

        // Convert to SearchResult models
        let searchResults = response.searchResults.map { result in
            SearchResult(
                messageID: result.messageID,
                text: result.text,
                senderID: result.senderID,
                timestamp: parseDate(result.timestamp) ?? Date(),
                relevanceScore: result.relevanceScore,
                snippet: result.snippet,
                aiAnswer: response.answer // Include AI-generated answer
            )
        }

        return searchResults
    } catch {
        print("❌ RAG Search error: \(error)")
        throw error
    }
}
```

### Step 3: Update SearchResult Model

Add AI answer field:

```swift
// File: N8NService.swift (models section)

struct SearchResult: Codable, Identifiable {
    let id: String
    let messageID: String
    let text: String
    let senderID: String
    let timestamp: Date
    let relevanceScore: Double
    let snippet: String
    let aiAnswer: String? // NEW: AI-generated answer

    init(messageID: String, text: String, senderID: String, timestamp: Date,
         relevanceScore: Double, snippet: String, aiAnswer: String? = nil) {
        self.id = messageID
        self.messageID = messageID
        self.text = text
        self.senderID = senderID
        self.timestamp = timestamp
        self.relevanceScore = relevanceScore
        self.snippet = snippet
        self.aiAnswer = aiAnswer
    }
}
```

### Step 4: Update SmartSearchView

Show AI-generated answer at the top:

```swift
// File: SmartSearchView.swift

var body: some View {
    NavigationStack {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            // AI Answer (if available)
            if let firstResult = viewModel.searchResults.first,
               let aiAnswer = firstResult.aiAnswer {
                aiAnswerCard(aiAnswer)
            }

            // Search results
            if viewModel.isSearching {
                loadingView
            } else if !viewModel.searchResults.isEmpty {
                resultsList
            } else if !viewModel.searchQuery.isEmpty {
                emptyStateView
            }
        }
    }
}

private func aiAnswerCard(_ answer: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(.purple)
            Text("AI Summary")
                .font(.headline)
                .foregroundStyle(.purple)
        }

        Text(answer)
            .font(.body)
            .foregroundStyle(.primary)

        Divider()
    }
    .padding()
    .background(Color.purple.opacity(0.1))
}
```

---

## Testing

### Test 1: Message Ingestion

1. **Send a test message** in Yaip
2. **Check N8N** → "Yaip - Message Ingestion" workflow executions
3. **Verify in Pinecone**:
   - Go to Pinecone dashboard
   - Click on `yaip-messages` index
   - Check **"Vectors"** tab → should show 1 vector

**Expected Output:**
```
Vector ID: message_abc123
Metadata: {
  conversationId: "conv_xyz",
  text: "Let's meet tomorrow at 3pm",
  senderID: "user456"
}
```

### Test 2: Smart Search

1. **In Yaip**, open a conversation
2. **Tap AI icon** → **"Smart Search"**
3. **Type query**: "When are we meeting?"
4. **Check N8N** → "Yaip - Smart Search (RAG)" workflow executions

**Expected Output in App:**
```
AI Summary:
"Based on the conversation, you're meeting tomorrow at 3pm."

Search Results:
• [Oct 26, 2pm] Alice: Let's meet tomorrow at 3pm
  Relevance: 92%
```

### Test 3: Semantic Search

Try queries that don't use exact keywords:

| Query | Expected Match |
|-------|---------------|
| "What time is the meeting?" | "Let's meet tomorrow at 3pm" |
| "Did we decide on a date?" | "I think Oct 30th works" |
| "Who's responsible for the report?" | "John will handle the report" |

This proves **semantic search** works (not just keyword matching)!

---

## Troubleshooting

### Issue: No vectors in Pinecone

**Solution:**
1. Check N8N "Message Ingestion" workflow is **Active**
2. Send a new message
3. Check workflow execution logs for errors
4. Verify Pinecone API key is correct

### Issue: Search returns no results

**Solutions:**
1. Verify index has vectors: Pinecone dashboard → Vectors tab
2. Check `conversationID` filter matches exactly
3. Try lowering `topK` to 10 for broader results
4. Check OpenAI embeddings are working (check N8N logs)

### Issue: 401 Unauthorized

**Solutions:**
- OpenAI: Check API key has credits
- Pinecone: Verify API key and environment
- N8N: Check webhook auth token

### Issue: Slow responses

**Optimizations:**
1. Reduce `topK` from 5 to 3
2. Use `gpt-3.5-turbo` instead of `gpt-4`
3. Add caching layer in N8N
4. Index messages in batches (not real-time)

---

## Production Tips

### 1. Batch Indexing

For existing messages, create a one-time migration workflow:

```javascript
// N8N Code node
const conversationID = "abc123";

// Fetch all messages from Firestore
const messages = await fetchAllMessages(conversationID);

// Process in batches of 100
for (let i = 0; i < messages.length; i += 100) {
  const batch = messages.slice(i, i + 100);

  // Create embeddings
  const embeddings = await createEmbeddings(batch);

  // Upsert to Pinecone
  await upsertToPinecone(embeddings);

  console.log(`Processed ${i + 100}/${messages.length}`);
}
```

### 2. Cost Optimization

**Embeddings Cost:**
- text-embedding-ada-002: $0.0001 / 1K tokens
- Average message: ~50 tokens
- 1000 messages: ~$0.005 (0.5 cents)

**GPT Cost:**
- gpt-3.5-turbo: $0.002 / 1K tokens (10x cheaper than GPT-4)
- Use GPT-3.5 for search, save GPT-4 for complex queries

### 3. Security

**Firestore Rules** (already configured):
```javascript
// Only index messages user has access to
match /conversations/{conversationId}/messages/{messageId} {
  allow read: if request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
}
```

**Pinecone Filtering:**
Always filter by `conversationId` to ensure users only search their own conversations.

---

## Next Steps

1. ✅ Set up Pinecone account and index
2. ✅ Create N8N message ingestion workflow
3. ✅ Create N8N smart search workflow
4. ✅ Test with sample messages
5. 🔄 Migrate existing messages (optional)
6. 🚀 Deploy to production

---

## Resources

- [Pinecone Documentation](https://docs.pinecone.io/)
- [OpenAI Embeddings Guide](https://platform.openai.com/docs/guides/embeddings)
- [N8N OpenAI Integration](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.openai/)
- [RAG Best Practices](https://www.pinecone.io/learn/retrieval-augmented-generation/)

---

**Questions? Issues?**
- Check N8N execution logs
- Verify API keys in Pinecone and OpenAI dashboards
- Test embeddings independently: https://platform.openai.com/playground

**Happy Searching! 🔍✨**
