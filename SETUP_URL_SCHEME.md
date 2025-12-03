# ⚠️ IMPORTANT: Add URL Scheme to Enable Phone Verification

## Quick Fix (5 minutes)

Phone verification will **crash** without this setup. Follow these exact steps:

### Option 1: Using Xcode (Recommended)

1. **Open Xcode**
   ```bash
   open Featur.xcodeproj
   ```

2. **Click on "Featur"** in the left sidebar (blue app icon)

3. **Select the "Featur" TARGET** (not the project)

4. **Click the "Info" tab** at the top

5. **Scroll down to "URL Types"**

6. **Click the "+" button**

7. **Fill in these EXACT values:**
   - **Identifier:** `com.lorenzo.featurdev`
   - **URL Schemes:** `com.lorenzo.featurdev`
   - **Role:** `Editor`

8. **Save** (Cmd + S)

9. **Clean build:** Product → Clean Build Folder (Shift + Cmd + K)

10. **Rebuild and run!**

---

### Option 2: Edit Info.plist Directly

If you can't find the URL Types section in Xcode:

1. **Right-click on Info.plist** in Xcode

2. **Select "Open As" → "Source Code"**

3. **Add this XML** inside the `<dict>` tag:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.lorenzo.featurdev</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.lorenzo.featurdev</string>
        </array>
    </dict>
</array>
```

4. **Save and rebuild**

---

## Test It Works

After adding the URL scheme:

1. **Go to Profile** → Verification section
2. **Tap "Verify"** next to Phone Number
3. **Enter phone:** +1 555-123-4567 (with country code)
4. **Tap "Send SMS Code"**
5. **Should NOT crash** ✅
6. **Check your phone** for the SMS
7. **Enter the code** → Verified!

---

## Why Do We Need This?

Firebase Phone Authentication uses **reCAPTCHA** to prevent spam. After verification, Firebase needs to redirect back to your app. The URL scheme tells iOS which app to open.

**URL Scheme = App's unique identifier for deep links**

---

## Troubleshooting

### Still Crashing?

1. **Check Bundle ID matches:**
   - Target → General → Identity
   - Should be: `com.lorenzo.featurdev`

2. **Clean build folder:**
   - Product → Clean Build Folder (Shift + Cmd + K)
   - Product → Build (Cmd + B)

3. **Restart Xcode**

4. **Delete app from simulator/device and reinstall**

### Wrong URL Scheme?

Your bundle ID is: **com.lorenzo.featurdev**

Use this **exactly** as your URL scheme.

### Can't Find Info.plist?

- It should be in your project folder
- In Xcode: Navigator → Featur folder → Info.plist

---

## Alternative: Just Use Email Verification

If you don't want to deal with this setup, **email verification works perfectly** without any configuration:

- ✅ No URL scheme needed
- ✅ Works out of the box
- ✅ Sends real emails automatically

Phone verification is optional!

---

## Done! 🎉

Once you add the URL scheme:
- ✅ Phone verification will work
- ✅ App won't crash
- ✅ Users can verify via SMS

Questions? Check the bundle ID in Xcode matches `com.lorenzo.featurdev`
