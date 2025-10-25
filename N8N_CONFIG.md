# N8N Configuration - Fill This In

## 📝 What You Need to Update

### 1. Generate Secret Token

Run this in terminal:
```bash
openssl rand -base64 32
```

**Your token**: _(Copy output here for reference)_
```
PASTE_YOUR_TOKEN_HERE
```

---

### 2. Update iOS App

Open: `Yaip/Yaip/Services/N8NService.swift`

**Find these lines (around line 19 and 23):**

```swift
private let baseURL = "https://your-n8n-instance.com/webhook"
private let authToken = "your_secret_token_here"
```

**Replace with your actual values:**

```swift
// Example for N8N Cloud:
private let baseURL = "https://your-name.app.n8n.cloud/webhook"

// Example for localhost:
private let baseURL = "http://localhost:5678/webhook"

// Your secret token (from step 1 above):
private let authToken = "PASTE_YOUR_TOKEN_HERE"
```

---

### 3. Configure N8N Webhook (Node 1)

In your N8N "Summarize Thread" workflow, **Webhook node** settings:

```
HTTP Method: POST
Path: /summarize
Authentication: Header Auth
  ├─ Header Name: Authorization
  └─ Expected Value: Bearer PASTE_YOUR_TOKEN_HERE
                            ^^^^^^ ^^^^^^^^^^^^^^^^^^^^
                            word   Your token from step 1
Response Mode: Last Node
```

**IMPORTANT**: In N8N, include "Bearer " before your token!

---

## 🧪 Test Configuration

### Test 1: N8N Webhook URL

After setting up the webhook node, N8N gives you a URL. Test it with curl:

```bash
# Replace with your actual URL and token
curl -X POST \
  'https://your-name.app.n8n.cloud/webhook/summarize' \
  -H 'Authorization: Bearer YOUR_TOKEN_HERE' \
  -H 'Content-Type: application/json' \
  -d '{
    "conversationID": "test123",
    "userID": "user1",
    "parameters": {
      "messageCount": 10
    }
  }'
```

**Expected response**: N8N should execute workflow (or error if Firestore not configured yet)

---

### Test 2: From iOS App

1. Build and run app in Xcode
2. Open any chat
3. Tap sparkles ✨ → "Summarize Thread"
4. Watch Xcode console for logs:

```
📤 Calling N8N webhook for thread summary...
   URL: https://your-name.app.n8n.cloud/webhook/summarize
   Conversation ID: abc123
   Message Count: 200
📡 Sending request to N8N...
   Headers: Authorization: Bearer ***
📥 Received response: 200
📄 Response body: {"success":true,"summary":"..."}
✅ Received summary from N8N
```

**If you see this**: ✅ It's working!

**If you see error**: Check the error message and compare with troubleshooting below

---

## 🐛 Troubleshooting

### Error: "Invalid URL"
```
📤 Calling N8N webhook...
❌ Invalid URL: https://your-n8n-instance.com/webhook/summarize
```

**Fix**: You forgot to update `baseURL` in N8NService.swift

---

### Error: "401 Unauthorized"
```
📥 Received response: 401
❌ Error response body: Unauthorized
```

**Fix**: Token mismatch. Check:
- iOS app: `authToken = "abc123"`
- N8N webhook: `Expected Value: Bearer abc123`

Make sure they match exactly!

---

### Error: "404 Not Found"
```
📥 Received response: 404
```

**Fix**:
- Check webhook path is `/summarize`
- Make sure workflow is **Active** (toggle ON in N8N)
- Verify baseURL doesn't have trailing slash

---

### Error: Timeout / No response
```
❌ The request timed out.
```

**Fix**:
- N8N is down or unreachable
- Check N8N URL is correct
- If localhost: Make sure N8N is running
- If cloud: Check internet connection

---

### Fallback to Mock Data
```
❌ N8N webhook error: ...
   Falling back to mock data...
```

This is expected if N8N isn't configured yet. The app will show mock summary but print the actual error in console so you can debug.

---

## ✅ Quick Checklist

Before testing:
- [ ] Generated secret token with `openssl rand -base64 32`
- [ ] Updated `baseURL` in N8NService.swift
- [ ] Updated `authToken` in N8NService.swift
- [ ] Configured webhook node in N8N with same token
- [ ] Workflow is **Active** (toggle ON)
- [ ] Tested with curl → Got response
- [ ] Cleaned and rebuilt iOS app (Cmd+Shift+K, Cmd+B)

---

## 📋 Your Configuration (Fill This Out)

```
N8N Webhook URL: ________________________________

Secret Token: ________________________________

N8N Instance Type:
  [ ] Cloud (n8n.cloud)
  [ ] Self-hosted (localhost)
  [ ] Railway
  [ ] DigitalOcean
  [ ] Other: ________________

Date Configured: ________________

Status:
  [ ] Curl test successful
  [ ] iOS app test successful
  [ ] Ready for production
```

---

## 🎉 Next Steps After It Works

1. See real AI summary in app!
2. Check N8N "Executions" tab → See workflow run
3. Check Firestore `aiCache` collection → See cached summary
4. Add other AI features using same pattern
5. Celebrate! 🎊

---

## 💡 Pro Tip: Test Mode

During development, keep the fallback to mock data. This way:
- ✅ App works even if N8N is down
- ✅ Can develop offline
- ✅ Faster testing (no API calls)

Once stable, remove the try/catch fallback in `summarizeThread()` method.

---

Ready to fill in your config and test? 🚀
