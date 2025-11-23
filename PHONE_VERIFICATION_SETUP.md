# Phone Verification Setup Guide

Phone verification is currently **disabled** to prevent crashes. Follow these steps to enable it.

## Why is it disabled?

Firebase Phone Authentication requires a custom URL scheme to be registered in your app's `Info.plist` file. Without this, the app crashes with:
```
Fatal error: Please register custom URL scheme in the app's Info.plist file
```

## How to Enable Phone Verification

### Step 1: Add URL Scheme in Xcode

1. **Open Xcode**
   ```bash
   open Featur.xcodeproj
   ```

2. **Select Your Target**
   - Click on "Featur" in the Project Navigator (left sidebar)
   - Make sure you're on the "Featur" target (not the project)

3. **Go to Info Tab**
   - Click the "Info" tab at the top

4. **Add URL Type**
   - Scroll down to find "URL Types" section
   - Click the **+** button to add a new URL Type
   - Fill in:
     - **Identifier:** `com.featur.app.auth`
     - **URL Schemes:** `featur-app-featur`
     - **Role:** `Editor`

5. **Alternative: Edit Info.plist Directly**

   If you prefer to edit the raw plist, add this to your Info.plist:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLName</key>
           <string>com.featur.app.auth</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>featur-app-featur</string>
           </array>
       </dict>
   </array>
   ```

### Step 2: Get Your Google App ID (Alternative Method)

If the above doesn't work, you can use your Google App Client ID:

1. **Find GoogleService-Info.plist**
   - Located in your project folder

2. **Look for REVERSED_CLIENT_ID**
   - Open `GoogleService-Info.plist`
   - Find the `REVERSED_CLIENT_ID` value
   - It looks like: `com.googleusercontent.apps.123456789-abcdefg`

3. **Use that as URL Scheme**
   - Add it to URL Types instead of `featur-app-featur`

### Step 3: Enable Phone Verification in Code

Once the URL scheme is added:

1. **Open** `Featur/EnhancedProfileView.swift`

2. **Find line ~1345** (search for "TEMPORARILY DISABLED")

3. **Uncomment the phone verification code:**

   Change this:
   ```swift
   // Phone Verification - TEMPORARILY DISABLED
   /*
   VerificationRow(
       title: "Phone Number",
       ...
   ) {
       showPhoneVerification = true
   }
   */
   ```

   To this:
   ```swift
   // Phone Verification
   VerificationRow(
       title: "Phone Number",
       subtitle: profile.phoneNumber ?? "Not provided",
       isVerified: profile.isPhoneVerified ?? false,
       icon: "phone.fill",
       color: .green,
       showButton: profile.isPhoneVerified != true
   ) {
       showPhoneVerification = true
   }
   ```

### Step 4: Test

1. **Rebuild the app** in Xcode
2. **Go to Profile** → Verification section
3. **Tap "Verify"** next to Phone Number
4. **Enter phone number** with country code (e.g., +1 555-123-4567)
5. **Receive SMS** with 6-digit code
6. **Enter code** → ✅ Verified!

## Troubleshooting

### Still Crashing?

1. **Check Bundle Identifier**
   - In Xcode, go to Target → General → Identity
   - Verify it matches: `featur-app.Featur`

2. **Clean Build**
   ```
   Product → Clean Build Folder (Shift + Cmd + K)
   ```

3. **Try Alternative URL Scheme**
   - Use your REVERSED_CLIENT_ID from GoogleService-Info.plist instead

### SMS Not Arriving?

1. **Check Firebase Console**
   - Go to Firebase Console → Authentication
   - Enable Phone authentication
   - Add test phone numbers if needed

2. **Daily Limits**
   - Firebase has daily SMS limits during development
   - May need to upgrade to paid plan for production

3. **Country Code**
   - Make sure to include country code (+1 for US)
   - Format: +1 555-123-4567

## Why Email Works But Phone Doesn't?

- **Email verification** uses Firebase Auth's built-in email sender (no URL scheme needed)
- **Phone verification** uses reCAPTCHA verification which requires URL callbacks
- URL scheme allows Firebase to redirect back to your app after verification

## Alternative: Use Email Only

If you don't need phone verification, you can simply leave it disabled. Email verification works perfectly without any additional setup!

---

## Summary

**Current Status:** Phone verification is **disabled** to prevent crashes

**To Enable:**
1. Add URL scheme to Info.plist (see Step 1)
2. Uncomment code in EnhancedProfileView.swift (see Step 3)
3. Rebuild and test

**Questions?**
- Check Firebase docs: https://firebase.google.com/docs/auth/ios/phone-auth
- Bundle ID: `featur-app.Featur`
- URL Scheme: `featur-app-featur` or use REVERSED_CLIENT_ID
