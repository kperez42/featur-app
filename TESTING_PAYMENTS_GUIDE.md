# 🧪 Step-by-Step Testing Guide for Payment System

## Complete Guide: From Sandbox to Production

---

## 📋 Overview

You'll test in **3 phases**:
1. **Sandbox Mode** (FREE - fake purchases)
2. **TestFlight** (FREE - real flow, no charges)
3. **Production** (REAL money - final test)

---

## 🎯 Phase 1: Sandbox Testing (Start Here!)

### What is Sandbox Mode?
- **FREE testing environment** from Apple
- Simulates real purchases without charging real money
- Perfect for development and testing

### Prerequisites:
- ✅ Xcode installed
- ✅ iPhone/iPad (physical device recommended)
- ✅ Apple Developer account

---

## Step 1: Create Sandbox Test Account

### 1.1 Go to App Store Connect
```
1. Open browser → https://appstoreconnect.apple.com
2. Sign in with your Apple Developer account
3. Click "Users and Access" (left sidebar)
4. Click "Sandbox" tab at top
```

### 1.2 Create Test User
```
1. Click [+] button (or "Add Sandbox Tester")
2. Fill in details:
   ┌────────────────────────────────────┐
   │ First Name: Test                   │
   │ Last Name: User                    │
   │ Email: testuser@example.com        │
   │ (can be fake email!)               │
   │ Password: TestPassword123!         │
   │ Country: United States             │
   │ Date of Birth: 01/01/1990         │
   └────────────────────────────────────┘
3. Click "Invite"
```

**Important Notes:**
- Email doesn't need to be real
- Remember the password you set
- You can create multiple test accounts
- Test accounts are ONLY for sandbox testing

---

## Step 2: Set Up Your iPhone/iPad

### 2.1 Sign OUT of Real Apple ID (Important!)
```
Settings → [Your Name at top] → Media & Purchases
→ Sign Out

⚠️ Don't sign out of iCloud, just Media & Purchases!
```

### 2.2 Do NOT Sign In Yet
- Leave it signed out for now
- You'll sign in DURING testing (not before)
- This prevents issues

---

## Step 3: Enable In-App Purchase in Xcode

### 3.1 Open Xcode
```
1. Open your Featur project
2. Select "Featur" target (blue icon at top)
3. Click "Signing & Capabilities" tab
```

### 3.2 Add In-App Purchase Capability
```
1. Click [+] button (top left of capabilities area)
2. Search "In-App Purchase"
3. Double-click it
```

You should now see:
```
┌────────────────────────────────────┐
│ Signing & Capabilities             │
├────────────────────────────────────┤
│ ✓ In-App Purchase                 │
└────────────────────────────────────┘
```

---

## Step 4: Build and Run on Device

### 4.1 Connect Your iPhone
```
1. Plug iPhone into Mac
2. Trust computer if prompted
3. In Xcode, select your iPhone from device dropdown
```

### 4.2 Build and Run
```
1. Click ▶ (Play button) in Xcode
2. App installs on your iPhone
3. Wait for app to launch
```

---

## Step 5: Test the Payment Flow

### 5.1 Navigate to Get Featured
```
Open app → Go to one of these places:

Option 1: Profile → ··· → "Get FEATUREd"
Option 2: Profile → ··· → Settings → "Get FEATUREd"
Option 3: FEATUREd Tab → "Get Featured" button
```

### 5.2 Select a Plan
```
1. Pricing sheet appears with 3 options
2. Tap "24 Hours" (cheapest for testing)
3. Tap "Select Plan" or "Buy" button
```

### 5.3 Sandbox Login Appears
```
You'll see a popup:
┌────────────────────────────────────┐
│ Sign In to iTunes Store            │
│                                    │
│ Use existing Apple ID?             │
│ [Cancel] [Use Existing Account]   │
└────────────────────────────────────┘

→ Tap "Use Existing Account"
```

### 5.4 Enter Sandbox Credentials
```
Enter the test account you created:
┌────────────────────────────────────┐
│ Email: testuser@example.com       │
│ Password: TestPassword123!        │
└────────────────────────────────────┘

→ Tap "Sign In"
```

### 5.5 Confirm Purchase
```
You'll see:
┌────────────────────────────────────┐
│ Confirm Your In-App Purchase       │
│                                    │
│ 24-Hour Featured Placement         │
│ $4.99                              │
│                                    │
│ [Sandbox Environment]              │
│                                    │
│ [Cancel]  [Buy]                   │
└────────────────────────────────────┘

→ Tap "Buy"
```

**Note:** Says "[Sandbox Environment]" - means it's FREE!

---

## Step 6: Verify It Worked

### 6.1 Check Success Message
```
You should see:
✓ "Purchase successful!"
✓ Haptic feedback (vibration)
```

### 6.2 Check Settings
```
Go to: Profile → ··· → Settings

You should see:
┌────────────────────────────────────┐
│ FEATUREd Status                    │
│ ┌────────────────────────────────┐ │
│ │ ⭐ FEATUREd              ✓    │ │
│ │ Active until [date/time]       │ │
│ │ ✨ Your profile is being       │ │
│ │    featured                    │ │
│ └────────────────────────────────┘ │
└────────────────────────────────────┘
```

### 6.3 Check Profile
```
Go to: Profile page

You should see:
- Star badge on profile
- "FEATUREd" label
```

### 6.4 Check FEATUREd Tab
```
Go to: FEATUREd tab (star icon)

Your profile should appear in the list!
```

### 6.5 Check Firebase (Backend)
```
Open Firebase Console:
1. Go to https://console.firebase.google.com
2. Select your project
3. Click "Firestore Database"
4. Find collection "featured"
5. Look for your user ID document

Should see:
{
  userId: "your-user-id",
  featuredAt: timestamp,
  expiresAt: timestamp,
  status: "active",
  productId: "com.featur.featured.24h"
}
```

---

## Step 7: Test Different Scenarios

### Test Case 1: Duplicate Purchase (Should Block)
```
1. While still featured, try to buy again
2. Tap "Get FEATUREd" → Select any plan
3. Should see error:
   "You're already featured! Wait for your current placement to expire."
4. Purchase should NOT proceed
```

### Test Case 2: Different Tiers
```
1. Wait for expiration OR delete from Firebase
2. Try each tier:
   - 24 Hours ($4.99)
   - 7 Days ($14.99)
   - 30 Days ($29.99)
3. Each should work the same way
```

### Test Case 3: Cancel Purchase
```
1. Tap "Get FEATUREd" → Select plan
2. Sandbox login appears → Sign in
3. Confirm purchase popup → Tap "Cancel"
4. Should return to app
5. Should NOT be featured
```

### Test Case 4: Expiration
```
Option A: Wait for real expiration
- Wait 24 hours for 24h plan
- Check that featured status expires

Option B: Manual test
1. Go to Firebase Console
2. Edit "expiresAt" to past date
3. Refresh app
4. Featured status should be gone
```

---

## 🐛 Troubleshooting Sandbox Issues

### Problem: "Cannot connect to iTunes Store"
**Solution:**
1. Check internet connection
2. Make sure signed OUT of real Apple ID
3. Restart app
4. Try again

### Problem: No products appear
**Causes:**
- Products not created in App Store Connect
- Wrong product IDs
- Capability not added

**Solution:**
1. Check App Store Connect → In-App Purchases
2. Verify product IDs match:
   - com.featur.featured.24h
   - com.featur.featured.7d
   - com.featur.featured.30d
3. Check Xcode capabilities

### Problem: "Invalid Product ID"
**Solution:**
1. Products might not be approved yet
2. Wait 24-48 hours after creating products
3. OR use StoreKit Configuration File (see below)

### Problem: Sandbox account not working
**Solution:**
1. Create a NEW sandbox account
2. Use different email
3. Make sure NOT signed in on device beforehand

---

## 🚀 Advanced: StoreKit Configuration File

### What is it?
- Lets you test WITHOUT waiting for App Store approval
- Local testing only
- Products defined in Xcode, not App Store Connect

### How to set up:

#### 1. Create StoreKit Configuration
```
1. In Xcode: File → New → File
2. Search "StoreKit Configuration"
3. Click Next
4. Name it "Products.storekit"
5. Click Create
```

#### 2. Add Products
```
1. Click [+] at bottom left
2. Select "Add Consumable In-App Purchase"
3. Fill in:
   Product ID: com.featur.featured.24h
   Reference Name: 24-Hour Featured
   Price: $4.99

4. Repeat for other 2 products
```

#### 3. Enable in Scheme
```
1. Product → Scheme → Edit Scheme
2. Select "Run" on left
3. Click "Options" tab
4. Under StoreKit Configuration:
   Select "Products.storekit"
5. Click Close
```

#### 4. Test!
```
- No sandbox account needed
- Products load immediately
- Purchases are simulated locally
```

---

## 📱 Phase 2: TestFlight Testing

### What is TestFlight?
- Apple's beta testing platform
- Real users test your app
- Purchases are FREE for testers
- Full purchase flow works

### Prerequisites:
- ✅ App uploaded to App Store Connect
- ✅ TestFlight enabled
- ✅ Sandbox testing passed

### Steps:

#### 1. Archive Your App
```
1. In Xcode: Product → Archive
2. Wait for archive to complete
3. Organizer window opens
```

#### 2. Upload to App Store Connect
```
1. Click "Distribute App"
2. Select "App Store Connect"
3. Click "Upload"
4. Wait for processing (10-30 minutes)
```

#### 3. Add Internal Testers
```
1. Go to App Store Connect
2. Select your app
3. Click "TestFlight" tab
4. Click "Internal Testing"
5. Add yourself + team members
```

#### 4. Install via TestFlight
```
1. Testers get email invitation
2. Install TestFlight app from App Store
3. Accept invitation
4. Install your app
```

#### 5. Test Purchases
```
- Use REAL Apple ID (not sandbox)
- Purchases are FREE in TestFlight
- Full flow works exactly like production
- Great for final testing
```

---

## 💳 Phase 3: Production Testing

### ⚠️ WARNING: This Uses REAL MONEY!

### Prerequisites:
- ✅ Sandbox testing complete
- ✅ TestFlight testing complete
- ✅ Products approved by Apple
- ✅ App released on App Store

### Steps:

#### 1. Download from App Store
```
- Use a REAL account you control
- NOT a test account
```

#### 2. Make REAL Purchase
```
- Start with cheapest tier ($4.99)
- You will be CHARGED for real
- Use this to verify everything works
```

#### 3. Verify Payment
```
1. Check app - should be featured
2. Check email - Apple sends receipt
3. Check bank - charge should appear
4. Check App Store Connect - sale recorded
```

#### 4. Check Analytics
```
Go to App Store Connect:
- Sales and Trends
- See your purchase recorded
- Track revenue
```

---

## 📊 Testing Checklist

### Before Launch:
- [ ] Sandbox testing passed
- [ ] All 3 tiers tested
- [ ] Duplicate purchase blocked
- [ ] Expiration works correctly
- [ ] Error handling works
- [ ] UI updates correctly
- [ ] Firebase data correct
- [ ] TestFlight testing passed
- [ ] Production test purchase made

### Common Test Scenarios:
```
✓ Happy path purchase
✓ User cancels
✓ Already featured (blocked)
✓ Network error
✓ Invalid product
✓ Expiration handling
✓ Multiple purchases over time
✓ Different price tiers
```

---

## 🎓 Quick Reference

### Sandbox Testing:
```
1. Create sandbox account (App Store Connect)
2. Sign out of real Apple ID on device
3. Run app from Xcode
4. Make purchase
5. Sign in with sandbox account when prompted
6. Verify featured status
```

### TestFlight Testing:
```
1. Archive app
2. Upload to App Store Connect
3. Add testers
4. Install via TestFlight
5. Test with real Apple ID (FREE)
```

### Production Testing:
```
1. Release app on App Store
2. Download with real account
3. Make real purchase ($4.99)
4. Verify everything works
5. Check revenue in App Store Connect
```

---

## 🆘 Need Help?

### Logs to Check:
```swift
// In Xcode console, look for:
✅ Loaded X products
✅ Purchase successful
✅ Featured placement granted
❌ Failed to load products
❌ Purchase failed
```

### Firebase to Check:
```
Collection: featured
Document: [your user ID]
Fields:
- featuredAt
- expiresAt
- status
- productId
```

### Apple Resources:
- Sandbox Testing: https://developer.apple.com/apple-pay/sandbox-testing/
- StoreKit Testing: https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox
- TestFlight: https://developer.apple.com/testflight/

---

## 🎉 Ready to Test!

**Start with Sandbox** → Move to TestFlight → Test in Production

Follow this guide step-by-step and you'll have a fully tested payment system!

**Questions?** Check the troubleshooting section or refer to:
- `PAYMENT_IMPLEMENTATION_GUIDE.md`
- `HOW_PAYMENTS_WORK.md`
