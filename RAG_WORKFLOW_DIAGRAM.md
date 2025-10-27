# RAG Search Workflow - Optimized Flow

## Complete N8N Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         RAG SEARCH WORKFLOW                              │
└─────────────────────────────────────────────────────────────────────────┘

                              ┌──────────────┐
                              │   WEBHOOK    │
                              │ POST /rag_   │
                              │   search     │
                              └──────┬───────┘
                                     │
                                     │ Receives:
                                     │ - conversationID
                                     │ - query
                                     ▼
                    ┌────────────────────────────────┐
                    │  HTTP Request - OpenAI         │
                    │  Embed Query                   │
                    │                                │
                    │  Model: text-embedding-3-large │
                    │  Dimensions: 3072              │
                    └────────────┬───────────────────┘
                                 │
                                 │ Returns: embedding vector [3072]
                                 ▼
                    ┌────────────────────────────────┐
                    │  Code - Format Pinecone Query  │
                    │                                │
                    │  Builds:                       │
                    │  {                             │
                    │    vector: [...],              │
                    │    topK: 5,                    │
                    │    namespace: conversationID,  │
                    │    includeMetadata: true       │
                    │  }                             │
                    └────────────┬───────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────────────┐
                    │  HTTP Request - Pinecone       │
                    │  Search Vectors                │
                    │                                │
                    │  POST /query                   │
                    └────────────┬───────────────────┘
                                 │
                                 │ Returns: top 5 matches with metadata
                                 ▼
                    ┌────────────────────────────────┐
                    │  Code - Format Search Results  │
                    │                                │
                    │  Maps Pinecone matches to:     │
                    │  - searchResults[]             │
                    │  - context string for GPT-4    │
                    └────────────┬───────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────────────┐
                    │  IF: Check if results exist    │
                    │                                │
                    │  Condition:                    │
                    │  searchResults.length > 0?     │
                    └─────────┬────────────┬─────────┘
                              │            │
                    ┌─────────┘            └─────────┐
                    │                                │
                 TRUE                             FALSE
            (Has Results)                    (No Results)
                    │                                │
                    ▼                                ▼
    ┌──────────────────────────────┐   ┌──────────────────────────┐
    │  Code - Build GPT-4 Request  │   │  Code - Build Empty      │
    │                              │   │  Response                │
    │  Creates request body with:  │   │                          │
    │  - System prompt             │   │  Returns:                │
    │  - User query + context      │   │  {                       │
    │  - temperature: 0.7          │   │    success: true,        │
    │  - max_tokens: 500           │   │    searchResults: [],    │
    └──────────────┬───────────────┘   │    aiAnswer: null,       │
                   │                   │    answerSources: [],    │
                   ▼                   │    query: "...",         │
    ┌──────────────────────────────┐   │    timestamp: "...",     │
    │  HTTP Request - OpenAI       │   │    conversationID: "..." │
    │  GPT-4 Generate Answer       │   │  }                       │
    │                              │   └─────────────┬────────────┘
    │  POST /chat/completions      │                 │
    │  Model: gpt-4                │                 │
    └──────────────┬───────────────┘                 │
                   │                                 │
                   │ Returns: AI-generated answer    │
                   ▼                                 │
    ┌──────────────────────────────┐                 │
    │  Code - Build Final Response │                 │
    │                              │                 │
    │  Combines:                   │                 │
    │  - searchResults             │                 │
    │  - aiAnswer (from GPT-4)     │                 │
    │  - answerSources (top 3)     │                 │
    │  - query metadata            │                 │
    └──────────────┬───────────────┘                 │
                   │                                 │
                   └────────────┬────────────────────┘
                                │
                                │ Both paths merge here
                                ▼
                   ┌─────────────────────────┐
                   │  Respond to Webhook     │
                   │                         │
                   │  Returns JSON response  │
                   │  to iOS app             │
                   └─────────────────────────┘
```

## Key Improvements

### ✅ Cost Optimization
- **Before:** GPT-4 called even with 0 results → wastes ~$0.01 per empty search
- **After:** GPT-4 only called when results exist → saves money on empty searches

### ✅ Performance
- **Before:** ~2-3 seconds for empty results (includes GPT-4 call)
- **After:** ~500ms for empty results (skips GPT-4 entirely)

### ✅ Better UX
- **Before:** Shows unhelpful AI message like "I don't have enough information"
- **After:** iOS app shows friendly empty state with helpful tips

## Node Configuration Summary

| Node | Type | Purpose |
|------|------|---------|
| **Webhook** | Webhook Trigger | Receives search request from iOS |
| **HTTP Request - OpenAI Embed Query** | HTTP Request | Converts query text to 3072-dim embedding |
| **Code - Format Pinecone Query** | Code | Builds Pinecone query with namespace |
| **HTTP Request - Pinecone Search** | HTTP Request | Finds top 5 similar messages |
| **Code - Format Search Results** | Code | Maps results + builds context for GPT-4 |
| **IF - Check if results exist** | IF | Branches based on result count |
| **Code - Build GPT-4 Request** | Code | (TRUE path) Prepares GPT-4 prompt |
| **HTTP Request - GPT-4** | HTTP Request | (TRUE path) Generates AI answer |
| **Code - Build Final Response** | Code | (TRUE path) Combines results + AI answer |
| **Code - Build Empty Response** | Code | (FALSE path) Returns empty state |
| **Respond to Webhook** | Respond to Webhook | Returns JSON to iOS app |

## Response Examples

### When Results Found (TRUE path)
```json
{
  "success": true,
  "searchResults": [
    {
      "messageID": "msg-123",
      "text": "Let's meet for coffee tomorrow at 3pm",
      "senderName": "Alice",
      "timestamp": "2025-01-26T15:00:00Z",
      "relevanceScore": 0.92,
      "matchType": "semantic"
    }
  ],
  "aiAnswer": "Based on the conversation, Alice suggested meeting for coffee tomorrow at 3pm.",
  "answerSources": ["msg-123"],
  "query": "coffee meeting",
  "timestamp": "2025-01-26T16:30:00Z",
  "conversationID": "conv-abc-123"
}
```

### When No Results (FALSE path)
```json
{
  "success": true,
  "searchResults": [],
  "aiAnswer": null,
  "answerSources": [],
  "query": "quantum physics",
  "timestamp": "2025-01-26T16:30:00Z",
  "conversationID": "conv-abc-123"
}
```

## iOS App Handling

### With Results
1. Shows **AI Summary card** at top (purple gradient border)
2. Lists **search results** grouped by match type
3. Each result shows relevance score and "View in chat" button

### No Results
1. Shows **friendly empty state** with icon
2. Message: "Nothing to Search Yet"
3. Helpful tips:
   - "Send messages in this conversation"
   - "Tap 'Index Messages' in AI Features menu"
   - "Start searching with AI-powered search"

## Setup Instructions

1. Open your RAG search workflow in N8N
2. Click **+** after "Code - Format Search Results" node
3. Add **IF** node, rename to "Check if results exist"
4. Configure condition: `{{ $json.searchResults.length }} > 0`
5. Connect **TRUE** path through existing GPT-4 nodes
6. Add **Code** node on **FALSE** path for empty response
7. Both paths connect to "Respond to Webhook"
8. Save and test!

## Testing

```bash
# Test with empty conversation (should skip GPT-4)
curl -X POST "https://rhoahndur.app.n8n.cloud/webhook/rag_search" \
  -H "Content-Type: application/json" \
  -H "Authorization: YOUR_TOKEN" \
  -d '{
    "conversationID": "empty-conv-001",
    "query": "test query"
  }'

# Expected: Fast response with aiAnswer: null
```
