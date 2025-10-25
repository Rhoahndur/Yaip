# N8N Setup Guide - Connect Real AI

This guide will walk you through setting up N8N and connecting your first AI agent (Thread Summarization) step-by-step.

---

## 🎯 What You'll Accomplish

By the end of this guide, you'll have:
- ✅ N8N instance running (cloud or self-hosted)
- ✅ Claude API connected
- ✅ Firestore connected
- ✅ Working Thread Summarization workflow
- ✅ iOS app calling real AI

**Time Required**: 1-2 hours

---

## 📋 Prerequisites

### 1. Anthropic API Key
```bash
# Get your key:
1. Go to https://console.anthropic.com/
2. Sign up or log in
3. Go to "API Keys"
4. Create new key
5. Copy key (starts with "sk-ant-...")
```

**Cost**: $0.015 per 1M input tokens, $0.075 per 1M output tokens
(~200 message summary = $0.01)

### 2. Firebase Admin SDK Key
```bash
# Get service account key:
1. Go to Firebase Console (console.firebase.google.com)
2. Open your project
3. Project Settings → Service Accounts
4. Click "Generate New Private Key"
5. Download JSON file
```

---

## 🚀 Step 1: Choose Your N8N Setup

### **Option A: N8N Cloud** (Easiest, $20/month)

**Pros**:
- No setup required
- Always online
- Automatic updates
- Built-in security

**Cons**:
- Monthly cost ($20)
- Data passes through N8N servers

**Steps**:
```bash
1. Go to https://n8n.io/cloud
2. Click "Start Free Trial" (14 days free)
3. Create account
4. You'll get URL: https://your-name.app.n8n.cloud
5. Done! Skip to Step 2
```

---

### **Option B: Self-Hosted** (Free, More Control)

**Pros**:
- Free forever
- Full data control
- Run on your own server

**Cons**:
- Need to manage server
- Need to keep it running
- Manual updates

#### **B1: Docker (Recommended)**

```bash
# Install Docker first:
# macOS: https://docs.docker.com/desktop/install/mac-install/
# Windows: https://docs.docker.com/desktop/install/windows-install/

# Run N8N:
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD=your_password_here \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Access at: http://localhost:5678
# Login: admin / your_password_here
```

#### **B2: Railway (Cloud hosting, $5/month)**

```bash
1. Go to https://railway.app
2. Sign up (free trial)
3. Click "New Project"
4. Search for "N8N"
5. Click "Deploy"
6. Wait 2 minutes
7. You'll get URL: https://your-app.up.railway.app
```

#### **B3: DigitalOcean Droplet ($6/month)**

```bash
1. Go to https://www.digitalocean.com
2. Create account ($200 free credit)
3. Create Droplet:
   - Ubuntu 22.04
   - Basic plan ($6/month)
   - Choose datacenter
4. SSH into droplet:
   ssh root@your_droplet_ip
5. Install Docker:
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
6. Run N8N:
   docker run -d --restart unless-stopped \
     --name n8n \
     -p 80:5678 \
     -v ~/.n8n:/home/node/.n8n \
     n8nio/n8n
7. Access at: http://your_droplet_ip
```

---

## 🔧 Step 2: Configure N8N Credentials

### Add Anthropic (Claude) Credentials

```bash
1. In N8N, click "Credentials" (left sidebar)
2. Click "Add Credential"
3. Search for "HTTP Request"
4. Name: "Anthropic Claude API"
5. Authentication: Header Auth
6. Add header:
   Name: x-api-key
   Value: sk-ant-your-key-here
7. Add header:
   Name: anthropic-version
   Value: 2023-06-01
8. Click "Save"
```

### Add Firebase Admin SDK

```bash
1. Click "Add Credential"
2. Search for "Google Service Account"
3. Name: "Firebase Admin"
4. Open your service account JSON file
5. Copy entire contents
6. Paste into "Service Account JSON" field
7. Click "Save"
```

---

## 🎨 Step 3: Create Thread Summarization Workflow

### Create New Workflow

```bash
1. Click "Workflows" (left sidebar)
2. Click "Add Workflow"
3. Name: "Summarize Thread"
4. Click canvas to start building
```

---

### Node 1: Webhook Trigger

```bash
1. Click "+" → Search "Webhook"
2. Select "Webhook"
3. Settings:
   - HTTP Method: POST
   - Path: /summarize
   - Authentication: Header Auth
     - Header Name: Authorization
     - Expected Value: Bearer your_secret_token_here
   - Response Mode: Last Node
4. Click "Execute Node" to get webhook URL
5. Copy URL (you'll need this for iOS app)
   Example: https://your-name.app.n8n.cloud/webhook/summarize
6. Click outside to close
```

**Save this webhook URL!** You'll add it to your iOS app later.

---

### Node 2: Get Firestore Messages

```bash
1. Click "+" → Search "Google Firestore"
2. Select "Google Firestore"
3. Connect to "Webhook" node (drag from dot)
4. Settings:
   - Credential: Select "Firebase Admin"
   - Project ID: your-firebase-project-id
   - Operation: Get All
   - Collection: conversations/{{$json.body.conversationID}}/messages
   - Limit: {{$json.body.parameters.messageCount}}
   - Sort: timestamp:asc
5. Click "Execute Node" to test (will fail - that's ok)
6. Click outside to close
```

---

### Node 3: Format Messages for Claude

```bash
1. Click "+" → Search "Code"
2. Select "Code"
3. Connect to "Google Firestore" node
4. Settings:
   - Mode: Run Once for All Items
   - Language: JavaScript
5. Paste this code:

const messages = $input.all().map(item => {
  const msg = item.json;
  return {
    sender: msg.senderID,
    text: msg.text || '[Image]',
    time: new Date(msg.timestamp._seconds * 1000).toLocaleString()
  };
});

const formattedConversation = messages.map(m =>
  `[${m.time}] ${m.sender}: ${m.text}`
).join('\n');

return [{
  json: {
    conversation: formattedConversation,
    messageCount: messages.length
  }
}];

6. Click "Execute Node"
7. Click outside to close
```

---

### Node 4: Call Claude API

```bash
1. Click "+" → Search "HTTP Request"
2. Select "HTTP Request"
3. Connect to "Code" node
4. Settings:
   - Method: POST
   - URL: https://api.anthropic.com/v1/messages
   - Authentication: Use Credential
     - Select: "Anthropic Claude API"
   - Send Body: Yes
   - Body Content Type: JSON
   - Specify Body: Using JSON
   - JSON:

{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 1024,
  "messages": [{
    "role": "user",
    "content": "Analyze this team conversation and provide a structured summary:\n\n{{$json.conversation}}\n\nProvide:\n1. Key Discussion Points (bullet points)\n2. Decisions Made (if any)\n3. Action Items (if any)\n4. Open Questions (if any)\n5. Overall Tone (professional/urgent/collaborative/etc)\n\nKeep it concise but comprehensive."
  }]
}

5. Click "Execute Node" (will fail until you test end-to-end)
6. Click outside to close
```

---

### Node 5: Cache to Firestore

```bash
1. Click "+" → Search "Google Firestore"
2. Select "Google Firestore"
3. Connect to "HTTP Request" node
4. Settings:
   - Credential: Select "Firebase Admin"
   - Project ID: your-firebase-project-id
   - Operation: Create
   - Collection: aiCache
   - Document ID: summary_{{$json.conversationID}}_{{Date.now()}}
   - Fields to Send: Define Below
   - Add fields:
     - summary (String): {{$node["HTTP Request"].json.content[0].text}}
     - conversationID (String): {{$json.conversationID}}
     - messageCount (Number): {{$json.messageCount}}
     - timestamp (String): {{new Date().toISOString()}}
     - cached (Boolean): true
5. Click outside to close
```

---

### Node 6: Return Response

```bash
1. Click "+" → Search "Respond to Webhook"
2. Select "Respond to Webhook"
3. Connect to "Google Firestore" node
4. Settings:
   - Response Mode: Using 'Respond to Webhook' Node
   - Response Code: 200
   - Response Body: JSON
   - JSON:

{
  "success": true,
  "summary": "{{$node["HTTP Request"].json.content[0].text}}",
  "messageCount": {{$json.messageCount}},
  "confidence": 0.92,
  "timestamp": "{{new Date().toISOString()}}"
}

5. Click outside to close
```

---

### Save and Activate Workflow

```bash
1. Click "Save" (top right)
2. Click "Active" toggle (top right) → Turn ON
3. Workflow is now live!
```

---

## 📱 Step 4: Update iOS App

### Update N8NService.swift

```swift
// File: Yaip/Yaip/Services/N8NService.swift

// Find this line (around line 14):
private let baseURL = "https://your-n8n-instance.com/webhook"

// Replace with your actual N8N webhook URL:
private let baseURL = "https://your-name.app.n8n.cloud/webhook"
// OR for self-hosted:
private let baseURL = "http://localhost:5678/webhook"
// OR for Railway:
private let baseURL = "https://your-app.up.railway.app/webhook"
```

### Add Authentication Token

```swift
// Add after baseURL:
private let authToken = "your_secret_token_here"  // Same as in webhook config

// Update callWebhook method to include auth:
private func callWebhook<T: Codable>(request: AIRequest, responseType: T.Type) async throws -> T {
    guard let url = URL(string: "\(baseURL)/\(request.feature)") else {
        throw N8NError.invalidURL
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")  // ADD THIS LINE

    // ... rest of method
}
```

### Replace Mock with Real Call

```swift
// In summarizeThread method (around line 26):

// OLD (Mock):
return try await mockSummarizeThread(conversationID: conversationID, messageCount: messageCount)

// NEW (Real):
return try await callWebhook(request: request, responseType: ThreadSummary.self)
```

---

## 🧪 Step 5: Test End-to-End

### Test in N8N First

```bash
1. Go to your workflow
2. Click "Webhook" node
3. Click "Listen for Test Event"
4. In terminal, send test request:

curl -X POST \
  'https://your-name.app.n8n.cloud/webhook/summarize' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer your_secret_token_here' \
  -d '{
    "conversationID": "test123",
    "messageCount": 10,
    "userID": "user1"
  }'

5. Watch workflow execute in N8N
6. Check each node for errors
7. See response in terminal
```

### Test in iOS App

```bash
1. Build and run app in Xcode
2. Open any chat conversation
3. Tap sparkles ✨ icon
4. Tap "Summarize Thread"
5. Watch for:
   - Loading state (2 seconds)
   - Real summary appears!
   - No more mock data!
6. Check N8N dashboard → Should see execution
7. Check Firestore → Should see cached summary in aiCache collection
```

---

## 🐛 Troubleshooting

### Error: "Invalid URL"
```bash
✅ Check baseURL in N8NService.swift
✅ Make sure no trailing slash
✅ Include /webhook path
```

### Error: "401 Unauthorized"
```bash
✅ Check authToken matches webhook config
✅ Format: "Bearer your_token"
✅ No typos in token
```

### Error: "Failed to fetch messages"
```bash
✅ Check Firebase service account JSON
✅ Verify project ID is correct
✅ Check Firestore collection path
```

### Error: "Claude API failed"
```bash
✅ Check API key is valid
✅ Verify anthropic-version header
✅ Check request format
✅ Look at N8N execution logs
```

### Mock Data Still Showing
```bash
✅ Make sure you replaced mock call with real call
✅ Clean build in Xcode (Cmd+Shift+K)
✅ Rebuild (Cmd+B)
✅ Check console logs for errors
```

---

## 📊 Monitor & Debug

### View N8N Executions

```bash
1. Click "Executions" (left sidebar)
2. See all workflow runs
3. Click any execution to see:
   - Input data
   - Each node's output
   - Errors (if any)
   - Execution time
```

### Check Firestore Cache

```bash
1. Go to Firebase Console
2. Firestore Database
3. Look for "aiCache" collection
4. Should see documents with:
   - summary
   - conversationID
   - messageCount
   - timestamp
```

### iOS Console Logs

```bash
Look for:
✅ "📤 Calling N8N webhook..."
✅ "✅ Summary generated: 200 messages"
❌ "❌ N8N error: [details]"
```

---

## 💰 Cost Breakdown

### For 1000 Active Users (Monthly)

**N8N**:
- Cloud: $20/month
- Self-hosted (Railway): $5/month
- Self-hosted (Docker): $0

**Claude API** (assuming 20 summaries/user/month):
- 20,000 requests
- ~4M tokens (200 messages each)
- Cost: ~$120/month

**Firebase**:
- Firestore reads: Free tier covers it
- Storage: Minimal
- Cost: ~$0-5/month

**Total**: $125-145/month = **$0.12/user/month**

---

## 🚀 Next: Add More AI Features

Once Thread Summarization works, add the other features:

### 1. Action Items (Same Pattern)
```bash
- Create workflow: "Extract Actions"
- Webhook path: /extract_actions
- Use same Firestore/Claude setup
- Different prompt
```

### 2. Meeting Suggestions
```bash
- Create workflow: "Schedule Meeting"
- Detect scheduling keywords
- Query Google Calendar API
- Suggest times
```

### 3. Priority Detection (Background)
```bash
- Use Firestore Trigger (not webhook)
- Runs on every new message
- Scores 0-10
- Sends push notification if >7
```

---

## 📚 Resources

**N8N Documentation**:
- https://docs.n8n.io
- https://docs.n8n.io/integrations/builtin/credentials/google/service-account/

**Claude API**:
- https://docs.anthropic.com/claude/reference/messages_post
- https://console.anthropic.com/

**Firebase Admin SDK**:
- https://firebase.google.com/docs/admin/setup
- https://firebase.google.com/docs/firestore/use-rest-api

**N8N Community**:
- https://community.n8n.io
- Discord: https://n8n.io/discord

---

## ✅ Success Checklist

- [ ] N8N instance running
- [ ] Webhook URL copied
- [ ] Claude API credentials added
- [ ] Firebase credentials added
- [ ] Workflow created with 6 nodes
- [ ] Workflow activated (toggle ON)
- [ ] iOS app baseURL updated
- [ ] Auth token added
- [ ] Mock call replaced with real call
- [ ] Test request sent via curl → Success!
- [ ] iOS app test → Real summary appears!
- [ ] Executions visible in N8N dashboard
- [ ] Cache entries in Firestore

---

## 🎉 You're Done!

You now have:
- ✅ Real AI-powered thread summarization
- ✅ N8N workflow that scales
- ✅ Cached results (cost optimization)
- ✅ Foundation for all other AI features

**Next**: Repeat this pattern for Action Items, Meeting Suggestions, and other AI features!

---

## 💡 Pro Tips

### 1. Use N8N Templates
N8N has a template library. Search for similar workflows to get started faster.

### 2. Error Handling
Add "Error Trigger" node to catch failures and send alerts.

### 3. Rate Limiting
Add "Rate Limit" node before Claude API to avoid quota issues.

### 4. Caching Strategy
Check Firestore cache first before calling Claude. Save ~60% on costs.

### 5. Monitoring
Set up N8N webhooks to send execution failures to Slack/Discord.

---

Ready to connect real AI? Start with Step 1! 🚀

Questions? Check the troubleshooting section or N8N community forum.
