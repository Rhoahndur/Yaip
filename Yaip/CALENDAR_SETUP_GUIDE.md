# Calendar Integration Setup Guide

This guide will walk you through setting up Google Calendar and Outlook Calendar integration for Yaip.

---

## Part 1: Google Calendar Setup

### Step 1: Create Google Cloud Console Project (5 minutes)

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com
   - Sign in with your Google account

2. **Create New Project**
   - Click the project dropdown at the top
   - Click "New Project"
   - Project name: `Yaip` (or your preferred name)
   - Click "Create"
   - Wait for project creation (takes ~30 seconds)

3. **Select Your Project**
   - Click the project dropdown again
   - Select your newly created project

### Step 2: Enable Google Calendar API (2 minutes)

1. **Navigate to APIs & Services**
   - In the left sidebar, click "APIs & Services" → "Library"
   - Or search "APIs & Services" in the top search bar

2. **Enable Calendar API**
   - In the API Library search bar, type: `Google Calendar API`
   - Click on "Google Calendar API"
   - Click the blue "Enable" button
   - Wait for it to enable (~10 seconds)

### Step 3: Create OAuth 2.0 Credentials (8 minutes)

1. **Go to Credentials Page**
   - Left sidebar: "APIs & Services" → "Credentials"

2. **Configure OAuth Consent Screen** (Required first time)
   - Click "Configure Consent Screen" button
   - Select "External" (unless you have Google Workspace)
   - Click "Create"

3. **Fill OAuth Consent Screen Info**
   - **App name**: `Yaip`
   - **User support email**: Your email
   - **App logo**: (Optional - skip for now)
   - **Developer contact**: Your email
   - Click "Save and Continue"

4. **Scopes** (Step 2 of consent screen)
   - Click "Add or Remove Scopes"
   - Search for: `calendar.readonly`
   - Check: `https://www.googleapis.com/auth/calendar.readonly`
   - Click "Update"
   - Click "Save and Continue"

5. **Test Users** (Step 3)
   - Click "Add Users"
   - Add your email address (for testing)
   - Click "Add"
   - Click "Save and Continue"

6. **Summary** (Step 4)
   - Review and click "Back to Dashboard"

7. **Create OAuth Client ID**
   - Go back to "Credentials" tab
   - Click "Create Credentials" → "OAuth client ID"
   - Application type: **iOS**
   - Name: `Yaip iOS Client`
   - Bundle ID: `YOUR_BUNDLE_ID` (e.g., `com.yourname.yaip`)
     - ⚠️ **Get this from Xcode**: Open your project → Select target → General tab → Bundle Identifier
   - Click "Create"

8. **Download Credentials**
   - A popup appears with your Client ID
   - **Copy the Client ID** (looks like: `123456789-abc.apps.googleusercontent.com`)
   - Click "Download JSON" (save this file - we'll need it)
   - Click "OK"

### Step 4: Get Your Client ID (Already done above)
✅ You should now have:
- Client ID: `123456789-abc.apps.googleusercontent.com`
- Downloaded JSON file with credentials

**Save these for later - we'll use them in the code!**

---

## Part 2: Microsoft/Outlook Calendar Setup

### Step 1: Create Azure Active Directory App (5 minutes)

1. **Go to Azure Portal**
   - Visit: https://portal.azure.com
   - Sign in with Microsoft account

2. **Navigate to Azure Active Directory**
   - Search "Azure Active Directory" in top search bar
   - Click on it

3. **Register New Application**
   - Left sidebar: Click "App registrations"
   - Click "+ New registration" at top

4. **Fill Registration Form**
   - **Name**: `Yaip iOS`
   - **Supported account types**:
     - Select "Accounts in any organizational directory (Any Azure AD directory - Multitenant) and personal Microsoft accounts (e.g. Skype, Xbox)"
   - **Redirect URI**:
     - Select "Public client/native (mobile & desktop)"
     - Enter: `msauth.YOUR_BUNDLE_ID://auth`
     - Example: `msauth.com.yourname.yaip://auth`
   - Click "Register"

### Step 2: Configure API Permissions (3 minutes)

1. **Add Microsoft Graph Permissions**
   - In your app's page, left sidebar: "API permissions"
   - Click "+ Add a permission"
   - Select "Microsoft Graph"
   - Select "Delegated permissions"

2. **Add Calendar Permissions**
   - Search for: `Calendars.Read`
   - Check: `Calendars.Read`
   - Click "Add permissions"

3. **Grant Admin Consent** (Optional but recommended)
   - Click "Grant admin consent for [Your Directory]"
   - Click "Yes"

### Step 3: Get Application Details (2 minutes)

1. **Copy Application (client) ID**
   - On the Overview page
   - Copy "Application (client) ID" (looks like: `12345678-1234-1234-1234-123456789abc`)
   - **Save this - we'll need it!**

2. **Copy Directory (tenant) ID**
   - Also on Overview page
   - Copy "Directory (tenant) ID"
   - **Save this too!**

3. **Confirm Redirect URI**
   - Left sidebar: "Authentication"
   - Verify redirect URI is correct: `msauth.YOUR_BUNDLE_ID://auth`

✅ You should now have:
- **Application (client) ID**: `12345678-1234-1234-1234-123456789abc`
- **Directory (tenant) ID**: `12345678-1234-1234-1234-123456789abc`
- **Redirect URI**: `msauth.YOUR_BUNDLE_ID://auth`

---

## Part 3: Summary - What You Need

Before we start coding, make sure you have:

### Google Calendar:
- ✅ Google Cloud project created
- ✅ Calendar API enabled
- ✅ OAuth consent screen configured
- ✅ Client ID: `_____________.apps.googleusercontent.com`

### Outlook Calendar:
- ✅ Azure AD app registered
- ✅ API permissions added (Calendars.Read)
- ✅ Application (client) ID: `________-____-____-____-____________`
- ✅ Directory (tenant) ID: `________-____-____-____-____________`
- ✅ Redirect URI: `msauth.YOUR_BUNDLE_ID://auth`

### Your iOS App:
- ✅ Bundle ID: `_________________________`

---

## Next Steps

Once you complete the setup above and have all the IDs ready, we'll:
1. Add the SDKs via Swift Package Manager
2. Update Info.plist with your credentials
3. Implement the calendar services
4. Update the UI

**Let me know when you're done with the setup, or if you get stuck anywhere!**

---

## Troubleshooting

### Google Calendar Issues:

**"OAuth consent screen not configured"**
- Make sure you completed Step 3.2-3.5 above

**"Bundle ID doesn't match"**
- Double-check your Bundle ID in Xcode matches what you entered in Google Console

**"Calendar API not enabled"**
- Go back to APIs & Services → Library and enable it

### Outlook Calendar Issues:

**"Redirect URI invalid"**
- Make sure format is: `msauth.YOUR_BUNDLE_ID://auth` (no spaces, lowercase)
- Bundle ID must match your Xcode project exactly

**"Permission not granted"**
- Make sure you added Calendars.Read permission
- Try granting admin consent again

**"Can't sign in"**
- Make sure you selected "Multitenant and personal accounts" during registration

---

## Security Notes

- ✅ Never commit Client IDs or secrets to Git
- ✅ Use environment variables or config files (add to .gitignore)
- ✅ Only request read-only calendar permissions
- ✅ Store tokens securely in iOS Keychain
