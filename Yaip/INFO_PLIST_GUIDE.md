# Info.plist Configuration Guide - Google Calendar

## Visual Guide: Adding URL Schemes to Info.plist

### Method 1: Xcode Visual Editor (Recommended)

#### Step-by-Step:

1. **Open Info.plist in Xcode**
   - Project Navigator → `Yaip` folder → `Yaip` subfolder → `Info.plist`
   - It should open in the visual editor (looks like a table/spreadsheet)

2. **Check if CFBundleURLTypes exists**
   - Scroll through the list
   - Look for a row that says "URL types" or "CFBundleURLTypes"

3. **If CFBundleURLTypes DOES NOT exist:**
   - Hover over any row, you'll see a `+` button appear
   - Click the `+` to add a new row
   - Start typing: `URL types` or `CFBundleURLTypes`
   - Select it from the dropdown
   - It will appear as "URL types" with Type: Array

4. **Expand CFBundleURLTypes:**
   - Click the little triangle/arrow next to "URL types"
   - You'll see "Item 0" appear (or it might be empty)

5. **If Item 0 doesn't exist, create it:**
   - Click the `+` next to "URL types"
   - "Item 0" appears with Type: Dictionary

6. **Expand Item 0:**
   - Click the triangle next to "Item 0"
   - You'll see the inside of this dictionary

7. **Add CFBundleURLSchemes:**
   - Click the `+` next to "Item 0"
   - Type: `URL Schemes` or `CFBundleURLSchemes`
   - Select it from dropdown
   - Type should be: Array

8. **Expand CFBundleURLSchemes:**
   - Click triangle next to "URL Schemes"
   - Click the `+` next to "URL Schemes"
   - "Item 0" appears with Type: String

9. **Set the Value:**
   - Double-click on "Item 0" under URL Schemes
   - Paste your REVERSED_CLIENT_ID
   - Example: `com.googleusercontent.apps.123456789-abc123`

10. **Add GIDClientID (at the top level):**
    - Go back to the root of Info.plist
    - Click `+` at the top level
    - Type: `GIDClientID`
    - Type: String
    - Value: Paste your CLIENT_ID (the long one ending in .apps.googleusercontent.com)

### Final Structure Should Look Like:

```
Info.plist
├── ...other keys...
├── GIDClientID (String) = "123456789-abc.apps.googleusercontent.com"
├── URL types (Array)
│   └── Item 0 (Dictionary)
│       └── URL Schemes (Array)
│           └── Item 0 (String) = "com.googleusercontent.apps.123456789-abc"
└── ...other keys...
```

---

### Method 2: Raw XML Editor (Alternative)

If you prefer editing the raw XML:

1. **Right-click Info.plist** → "Open As" → "Source Code"

2. **Find the closing `</dict>` tag near the bottom** (before `</plist>`)

3. **Add this RIGHT BEFORE `</dict>`:**

```xml
	<key>GIDClientID</key>
	<string>YOUR_CLIENT_ID_HERE.apps.googleusercontent.com</string>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>YOUR_REVERSED_CLIENT_ID_HERE</string>
			</array>
		</dict>
	</array>
```

4. **Replace:**
   - `YOUR_CLIENT_ID_HERE.apps.googleusercontent.com` → Your actual CLIENT_ID
   - `YOUR_REVERSED_CLIENT_ID_HERE` → Your actual REVERSED_CLIENT_ID

---

## Example with Real Values:

If your IDs are:
- CLIENT_ID: `123456789-abc123.apps.googleusercontent.com`
- REVERSED_CLIENT_ID: `com.googleusercontent.apps.123456789-abc123`

### XML would look like:

```xml
	<key>GIDClientID</key>
	<string>123456789-abc123.apps.googleusercontent.com</string>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>com.googleusercontent.apps.123456789-abc123</string>
			</array>
		</dict>
	</array>
```

---

## Verification:

After adding, your Info.plist should have:
1. ✅ A key called `GIDClientID` with your long CLIENT_ID as the value
2. ✅ A key called `CFBundleURLTypes` (or "URL types") with nested arrays/dictionaries
3. ✅ Inside that structure, your REVERSED_CLIENT_ID

### To Verify in Visual Editor:
- Expand "URL types" → "Item 0" → "URL Schemes" → "Item 0"
- You should see your REVERSED_CLIENT_ID (starting with `com.googleusercontent.apps`)

### To Verify in Source Code:
- Right-click Info.plist → Open As → Source Code
- Search (Cmd+F) for: `GIDClientID`
- Should find your CLIENT_ID
- Search for: `CFBundleURLSchemes`
- Should find your REVERSED_CLIENT_ID

---

## Common Issues:

**"I don't see URL types option when I try to add a row"**
- Type the full name: `CFBundleURLTypes`
- It will show up

**"The structure looks different"**
- That's okay! As long as the hierarchy matches:
  - CFBundleURLTypes (Array)
    - Item 0 (Dictionary)
      - CFBundleURLSchemes (Array)
        - Item 0 (String) = your REVERSED_CLIENT_ID

**"I already have CFBundleURLTypes"**
- Good! Just add a new item to the array
- Click the `+` next to CFBundleURLTypes
- Add the dictionary structure for Google

---

Need help? Let me know what you see in your Info.plist and I can guide you!
