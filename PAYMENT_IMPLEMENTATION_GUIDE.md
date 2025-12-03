# 💳 Featur App - Payment System Complete Guide

## Table of Contents
1. [How It Works](#how-it-works)
2. [App Store Connect Setup](#app-store-connect-setup)
3. [Testing Guide](#testing-guide)
4. [Error Handling](#error-handling)
5. [Security Best Practices](#security-best-practices)
6. [Troubleshooting](#troubleshooting)

---

## How It Works

### Payment Flow Architecture
```
User Initiates Purchase
    ↓
StoreKit Loads Products
    ↓
User Selects Plan & Confirms
    ↓
Apple Payment Sheet Appears
    ↓
User Authenticates (Face ID/Touch ID)
    ↓
Apple Processes Payment
    ↓
StoreKit Returns Transaction
    ↓
App Verifies Transaction (Security Check)
    ↓
App Grants Featured Placement in Firebase
    ↓
Transaction Finished & User Featured!
```

### Product IDs (Already in Code)
```swift
com.featur.featured.24h  // 24 Hours - $4.99
com.featur.featured.7d   // 7 Days - $14.99 (Most Popular)
com.featur.featured.30d  // 30 Days - $29.99 (Best Value)
```

---

## App Store Connect Setup

### Step 1: Create Products

1. **Login to App Store Connect**
   - URL: https://appstoreconnect.apple.com
   - Go to: My Apps → Your App → Features → In-App Purchases

2. **Create Each Product** (repeat 3 times)
   ```
   Click [+] Button
   Select: "Consumable"

   Product Details:
   ┌─────────────────────────────────────┐
   │ Reference Name: Featured 24 Hours   │
   │ Product ID: com.featur.featured.24h │
   │ Price Tier: $4.99 (Tier 5)          │
   └─────────────────────────────────────┘

   Localization (English):
   ┌──────────────────────────────────────────────┐
   │ Display Name: 24-Hour Featured Placement    │
   │ Description: Get your profile featured in   │
   │ the FEATUREd tab for 24 hours. Boost your  │
   │ visibility and reach thousands of creators! │
   └──────────────────────────────────────────────┘
   ```

3. **Add Screenshot** (Required by Apple)
   - Size: 640x920 pixels minimum
   - Content: Simple graphic showing "Featured" badge
   - Create in Canva or Figma

4. **Submit for Review**
   - Click "Submit for Review"
   - Approval takes 24-48 hours
   - Can test immediately in Sandbox mode

### Step 2: Pricing Strategy
```
Recommended Pricing:
┌──────────┬─────────┬──────────────┬─────────────┐
│ Duration │ Price   │ Daily Rate   │ Best For    │
├──────────┼─────────┼──────────────┼─────────────┤
│ 24 Hours │ $4.99   │ $4.99/day    │ Quick test  │
│ 7 Days   │ $14.99  │ $2.14/day    │ Most Popular│
│ 30 Days  │ $29.99  │ $1.00/day    │ Best Value  │
└──────────┴─────────┴──────────────┴─────────────┘
```

---

## Testing Guide

### Phase 1: Sandbox Testing (Before Launch)

1. **Create Sandbox Test Account**
   ```
   App Store Connect → Users and Access → Sandbox Testers
   Click [+] → Create test account
   Email: test@example.com (can be fake)
   Password: Test1234!
   ```

2. **Configure Device for Testing**
   ```
   iPhone Settings → App Store → Sandbox Account
   Sign in with test account
   ```

3. **Test Purchase Flow**
   ```swift
   // In your app:
   1. Tap "Get Featured"
   2. Select a plan
   3. Confirm purchase
   4. Use sandbox account password
   5. Verify featured placement appears
   ```

4. **Important Test Cases**
   ```
   ✅ Successful purchase
   ✅ User cancels purchase
   ✅ Network error during purchase
   ✅ Invalid payment method
   ✅ Restore purchases
   ✅ Expiration handling
   ```

### Phase 2: TestFlight Testing

```
1. Upload build to TestFlight
2. Add internal testers
3. Testers use REAL Apple ID
4. Payments are FREE in TestFlight
5. Full purchase flow works (but no charge)
```

### Phase 3: Production Testing

```
⚠️ IMPORTANT: Use a real account you control
- Purchases are REAL and CHARGED
- Test with smallest tier ($4.99)
- Verify full flow end-to-end
```

---

## Error Handling

### Common Errors & Solutions

#### 1. "Cannot connect to iTunes Store"
```swift
Error: Network connectivity issues
Solution:
- Check internet connection
- Retry purchase
- Show user-friendly message
```

#### 2. "Purchase Failed"
```swift
Causes:
- Invalid product ID
- Products not approved in App Store Connect
- Sandbox account issues

Fix:
1. Verify product IDs match exactly
2. Check App Store Connect status
3. Clear Sandbox account
```

#### 3. "Transaction Verification Failed"
```swift
Error: VerificationResult.unverified
Solution:
- DO NOT grant access
- Log error for investigation
- Show "Purchase failed - contact support"
```

#### 4. "User Already Featured"
```swift
Check Firestore before purchase:
if await isUserCurrentlyFeatured() {
    showAlert("You're already featured!")
    return
}
```

---

## Security Best Practices

### ✅ DO's

1. **Always Verify Transactions**
   ```swift
   // Your code already does this:
   let transaction = try checkVerified(verification)
   ```

2. **Use Server-Side Validation** (Future Enhancement)
   ```swift
   // Send receipt to your server
   // Server validates with Apple
   // Prevents fraud
   ```

3. **Store Transaction IDs**
   ```swift
   // Already in code (line 181):
   "transactionId": transaction.id
   ```

4. **Handle Expiration**
   ```swift
   // Set expiration date (line 168):
   let expiresAt = Calendar.current.date(byAdding: .day, value: duration, to: Date())
   ```

5. **Listen for Transaction Updates**
   ```swift
   // Already implemented (line 217-237):
   listenForTransactions()
   ```

### ❌ DON'Ts

1. **Don't Grant Access Without Verification**
   ```swift
   // BAD:
   await grantAccess()

   // GOOD (your code):
   let transaction = try checkVerified(verification)
   await grantFeaturedPlacement(for: transaction)
   ```

2. **Don't Skip Transaction.finish()**
   ```swift
   // Always call (already in code line 87):
   await transaction.finish()
   ```

3. **Don't Trust Client-Side Only**
   ```swift
   // Future: Add server-side verification
   ```

---

## Troubleshooting

### Problem: Products Don't Load
```
Checklist:
□ Products created in App Store Connect?
□ Product IDs match exactly?
□ Products approved (or in Sandbox mode)?
□ Bundle ID matches?
□ Capabilities: In-App Purchase enabled?
```

### Problem: Purchase Completes But No Access
```
Debug Steps:
1. Check Firebase Firestore
2. Verify document created in "featured" collection
3. Check transaction listener is running
4. Verify grantFeaturedPlacement() succeeds
```

### Problem: Sandbox Not Working
```
Solutions:
1. Sign out of real Apple ID in Settings
2. Sign in with Sandbox account in Settings → App Store
3. Delete and reinstall app
4. Clear derived data in Xcode
```

### Problem: "Invalid Product ID"
```
Common Causes:
1. Typo in product ID
2. Product not yet approved
3. Wrong app bundle ID
4. Capabilities not enabled

Fix:
- Double-check spelling
- Wait for approval (24-48 hours)
- Verify bundle ID: com.yourcompany.featur
```

---

## Production Checklist

Before launching payments:

### App Store Connect
- [ ] All 3 products created
- [ ] Products approved by Apple
- [ ] Pricing set correctly
- [ ] Screenshots uploaded
- [ ] Localizations added

### Xcode
- [ ] In-App Purchase capability enabled
- [ ] Bundle ID matches App Store Connect
- [ ] StoreKit configuration file added (for testing)
- [ ] Receipt validation implemented

### Code
- [ ] Product IDs match exactly
- [ ] Error handling complete
- [ ] Transaction verification working
- [ ] Firebase integration tested
- [ ] Expiration handling works
- [ ] Restore purchases working

### Testing
- [ ] Sandbox testing passed
- [ ] TestFlight testing passed
- [ ] Real purchase tested
- [ ] Expiration tested
- [ ] Error scenarios tested

### Legal
- [ ] Terms of Service updated
- [ ] Privacy Policy includes payments
- [ ] Refund policy documented

---

## Support & Debugging

### Useful Console Logs
Your code already has great logging:
```swift
✅ Loaded X products
✅ Purchase successful
✅ Featured placement granted
❌ Failed to load products
❌ Purchase failed
```

### Firebase Console Check
```
Firestore → featured collection
Should see:
{
  userId: "abc123",
  category: "Featured",
  featuredAt: Timestamp,
  expiresAt: Timestamp,
  transactionId: "1234567",
  productId: "com.featur.featured.7d",
  status: "active"
}
```

### Test Refunds
```
App Store Connect → Sales and Trends → Refund Request
```

---

## Next Steps

1. **Setup App Store Connect**
   - Create products
   - Set pricing
   - Add screenshots

2. **Enable Capability in Xcode**
   ```
   Target → Signing & Capabilities → [+] In-App Purchase
   ```

3. **Test in Sandbox**
   - Create sandbox account
   - Test all flows

4. **Submit for Review**
   - Include in-app purchase review note
   - Explain how to trigger payment

5. **Monitor Analytics**
   - Track purchase attempts
   - Track success/failure rates
   - Track revenue

---

## Questions?

Common questions answered:

**Q: How long for Apple approval?**
A: Usually 24-48 hours for products

**Q: Can users get refunds?**
A: Yes, through App Store. Apple handles refunds.

**Q: Do I need a server?**
A: Not required, but recommended for extra security

**Q: What about subscriptions vs consumables?**
A: Featured placement = Consumable (current implementation is correct)

**Q: Testing costs money?**
A: No! Sandbox is FREE. TestFlight is FREE.

**Q: Need business entity?**
A: Yes, need Apple Developer account ($99/year)

---

## Success Metrics

Track these KPIs:
```
- Purchase conversion rate
- Average order value
- Revenue per user
- Refund rate
- Featured placement effectiveness
- User retention after featuring
```

---

**Your current implementation is solid! Just needs App Store Connect setup and testing. 🚀**
