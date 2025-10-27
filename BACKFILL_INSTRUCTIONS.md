# Message Backfill Instructions

This script indexes all existing Firestore messages into Pinecone for RAG search.

## Prerequisites

1. Node.js installed (v16 or higher)
2. Firebase Admin SDK service account key

## Step 1: Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **Yaip** project
3. Click the gear icon ⚙️ → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Download the JSON file
7. **Rename it to `serviceAccountKey.json`**
8. **Move it to `/Users/aleksandrgaun/Downloads/Yaip/` directory** (same location as this README)

**⚠️ IMPORTANT:** Never commit `serviceAccountKey.json` to git! It contains sensitive credentials.

## Step 2: Install Dependencies

```bash
cd /Users/aleksandrgaun/Downloads/Yaip
npm install
```

## Step 3: Run the Backfill Script

```bash
npm run backfill
```

Or directly:

```bash
node backfill-messages.js
```

## What the Script Does

1. Connects to your Firestore database
2. Fetches all conversations
3. For each conversation:
   - Reads all messages
   - Sends each message to the N8N ingestion webhook
   - Messages are processed in batches of 10 with 500ms delay between batches
4. Prints a summary of:
   - Total messages found
   - Successfully ingested
   - Skipped (messages without text)
   - Failed (if any errors)

## Expected Output

```
🚀 Starting message backfill process...

📋 Found 5 conversations

📁 Processing conversation: conv-abc-123
   Found 42 messages
   Processing batch 1/5...
   ✅ Ingested message msg-001
   ✅ Ingested message msg-002
   ...

============================================================
✨ Backfill Complete!
============================================================
📊 Total messages found: 156
✅ Successfully ingested: 150
⏭️  Skipped (no text): 6
❌ Failed: 0
============================================================
```

## Troubleshooting

### Error: "Cannot find module 'firebase-admin'"
Run `npm install` in the `/Users/aleksandrgaun/Downloads/Yaip/` directory.

### Error: "ENOENT: no such file or directory, open './serviceAccountKey.json'"
Make sure you downloaded the Firebase service account key and placed it in the same directory as the script.

### Error: "Authorization data is wrong!"
Check that the `N8N_AUTH_TOKEN` in `backfill-messages.js` matches your N8N webhook token.

### Error: "HTTP 429: Too Many Requests"
The script is sending too many requests. Increase the `DELAY_MS` value in the script (e.g., change to 1000 for 1 second delay).

## Configuration

You can modify these values in `backfill-messages.js`:

```javascript
const BATCH_SIZE = 10;  // Number of messages to process at once
const DELAY_MS = 500;   // Milliseconds to wait between batches
```

## After Backfill

Once the backfill is complete:
- All existing messages will be searchable via RAG search in the iOS app
- New messages sent through the app will be automatically indexed (you'll need to set this up)
- You can verify by searching for specific topics/keywords in the Smart Search feature

## Clean Up

After successful backfill, you can delete:
- `serviceAccountKey.json` (keep it safe somewhere else)
- `backfill-messages.js`
- `package.json`
- `node_modules/` directory

Or keep them for future backfills if needed.
