# In-App Purchase Setup Guide for Featur

This guide explains how to set up in-app purchases for the Featured subscription feature in App Store Connect and test them using Sandbox.

## 🧪 Current Status

**Debug Mode is Active:** The app automatically uses test purchases when real products aren't configured. You'll see a "🧪 Test Mode" indicator at the bottom of the pricing section.

To enable **real** in-app purchases for production and Sandbox testing, follow the steps below.

---

## 📋 Step 1: Create In-App Purchases in App Store Connect

### 1.1 Sign in to App Store Connect
1. Go to [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account
3. Click on **"My Apps"**
4. Select your **Featur** app (or create it if it doesn't exist)

### 1.2 Navigate to In-App Purchases
1. In your app's page, click on the **"Features"** tab in the left sidebar
2. Click **"In-App Purchases"**
3. Click the **"+"** button to create a new in-app purchase

### 1.3 Create Product #1: 24-Hour Featured Placement

1. Select **"Consumable"** (since featured placements expire)
2. Fill in the required information:

   **Product ID (Reference Name):**
   ```
   com.featur.featured.24h
   ```
   ⚠️ **CRITICAL:** This ID must match exactly!

   **Reference Name:**
   ```
   Featured Placement - 24 Hours
   ```

   **Price:**
   - Click **"Add Pricing"**
   - Select your primary storefront (e.g., United States)
   - Enter **$4.99**
   - Click **"Next"** and **"Create"**

   **App Store Localization (English):**
   - **Display Name:** `24-Hour Featured`
   - **Description:** `Get your profile featured for 24 hours in the FEATUREd tab. Includes featured badge and priority support.`

3. Click **"Save"**

### 1.4 Create Product #2: 7-Day Featured Placement

Repeat the process with these details:

**Product ID:**
```
com.featur.featured.7d
```

**Reference Name:**
```
Featured Placement - 7 Days
```

**Price:** `$19.99`

**Display Name:** `7-Day Featured`

**Description:**
```
Get your profile featured for 7 days in the FEATUREd tab. Includes featured badge, analytics dashboard, and priority support.
```

### 1.5 Create Product #3: 30-Day Featured Placement

**Product ID:**
```
com.featur.featured.30d
```

**Reference Name:**
```
Featured Placement - 30 Days
```

**Price:** `$59.99`

**Display Name:** `30-Day Featured`

**Description:**
```
Get your profile featured for 30 days in the FEATUREd tab. Includes featured badge, advanced analytics, dedicated support. Best value!
```

---

## 🧪 Step 2: Set Up Sandbox Testing

### 2.1 Create a Sandbox Tester Account

1. In App Store Connect, click your name in the top-right corner
2. Select **"Users and Access"**
3. Click **"Sandbox Testers"** in the sidebar
4. Click the **"+"** button
5. Fill in the tester information:
   - **Email:** Use a NEW email that's never been used with Apple (e.g., `featur.test1@example.com`)
   - **Password:** Create a secure password
   - **First/Last Name:** Your choice
   - **Country/Region:** Select your testing region (e.g., United States)
   - **App Store Territory:** Same as country
6. Click **"Invite"**

💡 **Tips:**
- You can create multiple sandbox accounts for testing
- Use `+` addressing if you have Gmail (e.g., `yourname+sandbox1@gmail.com`)
- The sandbox account does NOT need to verify the email

### 2.2 Configure Your Test Device

**On your iPhone/iPad:**

1. Go to **Settings** → **App Store**
2. Scroll down to **SANDBOX ACCOUNT**
3. Tap **Sign In** (if not already signed in)
4. Enter your **sandbox tester email and password**
5. Tap **Sign In**

⚠️ **Important:**
- Do NOT sign in with your sandbox account in regular Settings → Apple ID
- Only sign in under Settings → App Store → Sandbox Account
- Never use your real Apple ID for sandbox testing

---

## 🚀 Step 3: Test In-App Purchases in Sandbox

### 3.1 Build and Run on Device

1. Connect your iPhone/iPad to your Mac
2. In Xcode, select your connected device
3. Build and run the app (`Cmd + R`)
4. Make sure you're signed in to the app with a Firebase account

### 3.2 Test the Purchase Flow

1. In the app, navigate to the **FEATUREd** tab
2. Tap the **"Get Featured"** button (star icon in toolbar)
3. You should see **three pricing cards** with real prices
4. Tap **"Select Plan"** on any product
5. **Sandbox Purchase Dialog** will appear with `[Sandbox]` in the title
6. Tap **"Buy"** or use Touch ID/Face ID
7. You'll see a success message: **"Success! You're now featured!"**
8. Your profile should now appear in the FEATUREd tab

💡 **Sandbox Testing Tips:**
- Sandbox purchases are FREE - you won't be charged
- You can purchase the same item multiple times in sandbox
- Receipts are marked `[Sandbox]` to distinguish from real purchases
- Sandbox environment can be slower than production

### 3.3 Verify Featured Status

1. Close the payment sheet
2. Go to the **FEATUREd** tab
3. Your profile should appear at the top with a ⭐ badge
4. Check Firebase Console → Firestore → `featured` collection
5. You should see a document with:
   - `userId`: Your user ID
   - `expiresAt`: Expiration timestamp
   - `productId`: The purchased product ID
   - `status`: "active"
   - `transactionId`: Apple transaction ID

---

## 🐛 Troubleshooting

### Products Not Loading

**Error:** "Plans Unavailable - No products available"

**Solutions:**
1. Wait 1-2 hours after creating products (App Store Connect can be slow)
2. Check that product IDs exactly match:
   - `com.featur.featured.24h`
   - `com.featur.featured.7d`
   - `com.featur.featured.30d`
3. Ensure products are in "Ready to Submit" state
4. Sign out and back in to sandbox account
5. Delete and reinstall the app

### Sandbox Sign-In Issues

**Problem:** Can't sign in with sandbox account

**Solutions:**
1. Sign out from Settings → App Store
2. Delete the app from device
3. Restart the device
4. Reinstall the app
5. Try signing in to sandbox again

### Purchase Fails

**Error:** "Purchase failed" or transaction doesn't complete

**Solutions:**
1. Check internet connection
2. Verify sandbox account is valid
3. Try a different sandbox account
4. Check Xcode console for detailed error messages
5. Ensure Firebase is properly configured

### Test Mode Still Showing

**Problem:** App shows "🧪 Test Mode" even after setting up products

**Solutions:**
1. Products may not be approved yet (wait 1-2 hours)
2. Kill and restart the app
3. Check App Store Connect for product status
4. Build and run again in Xcode

---

## 📱 Step 4: Production Setup (When Ready)

### Before Submitting to App Review:

1. **Create App Store Screenshots** showing the purchase flow
2. **Add In-App Purchase Metadata:**
   - Go to each product in App Store Connect
   - Add screenshots (optional but recommended)
   - Add promotional image (optional)
3. **Submit Products for Review** along with your app
4. **Complete Paid Apps Agreement:**
   - Go to App Store Connect → Agreements, Tax, and Banking
   - Complete the Paid Apps agreement
   - Add banking and tax information

### Review Guidelines:

- Products must be submitted WITH your app (not separately)
- Reviewers will test the purchase flow
- Ensure the purchase grants the advertised features
- Include screenshots showing what users get

---

## 🔍 Product IDs Reference

Copy these exact IDs when creating products:

```swift
// 24-hour placement
com.featur.featured.24h

// 7-day placement
com.featur.featured.7d

// 30-day placement
com.featur.featured.30d
```

---

## 📚 Additional Resources

- [App Store Connect Guide](https://developer.apple.com/app-store-connect/)
- [In-App Purchase Documentation](https://developer.apple.com/in-app-purchase/)
- [StoreKit Testing in Xcode](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
- [Sandbox Testing Guide](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_at_all_stages_of_development_with_xcode_and_sandbox)

---

## ✅ Quick Checklist

- [ ] Created all 3 products in App Store Connect
- [ ] Product IDs match exactly
- [ ] Prices are set correctly ($4.99, $19.99, $59.99)
- [ ] Created at least one sandbox tester account
- [ ] Signed in to sandbox on test device
- [ ] Built and ran app on physical device
- [ ] Successfully tested purchase flow
- [ ] Verified featured status in app
- [ ] Checked Firestore for featured document

---

**Need Help?** Check the Xcode console for detailed logs. All StoreKit operations are logged with ✅/❌ prefixes.
