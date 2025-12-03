# 💳 How Payments & Subscriptions Work in Featur App

## Complete Guide for Understanding the Payment System

---

## 📚 Table of Contents
1. [Overview](#overview)
2. [Step-by-Step Payment Journey](#step-by-step-payment-journey)
3. [How Money Flows](#how-money-flows)
4. [Technical Architecture](#technical-architecture)
5. [What Happens Behind the Scenes](#what-happens-behind-the-scenes)
6. [Security & Verification](#security--verification)
7. [User Experience Flow](#user-experience-flow)
8. [Common Questions](#common-questions)

---

## Overview

**What is the FEATUREd subscription?**
- It's a **one-time purchase** (not recurring) that boosts your profile visibility
- You pay once and get featured for a set period (24 hours, 7 days, or 30 days)
- After the period ends, it expires automatically - no recurring charges!

**Three tiers available:**
1. **24 Hours** - $4.99 (Quick test)
2. **7 Days** - $14.99 (Most popular, best value per day)
3. **30 Days** - $29.99 (Best overall value)

---

## Step-by-Step Payment Journey

### For the User (What They See)

```
Step 1: User opens app → Goes to Profile
   ↓
Step 2: Clicks three-dots menu (···) → Selects "Get FEATUREd"
   OR goes to Settings → Sees "Get FEATUREd" option
   OR goes to FEATUREd tab → Clicks "Get Featured" button
   ↓
Step 3: Sees pricing sheet with 3 options
   ┌─────────────────────────────────────┐
   │ 24 Hours - $4.99                    │
   │ 7 Days - $14.99 (POPULAR)           │
   │ 30 Days - $29.99 (BEST VALUE)       │
   └─────────────────────────────────────┘
   ↓
Step 4: Taps "Select Plan" button
   ↓
Step 5: Apple's payment sheet appears
   ┌─────────────────────────────────────┐
   │  Pay with Apple Pay                 │
   │  ━━━━━━━━━━━━━━━━━━━━━━━           │
   │  Visa ····1234                      │
   │  $14.99                             │
   │  [Touch ID to pay]                  │
   └─────────────────────────────────────┘
   ↓
Step 6: User authenticates (Face ID/Touch ID/Password)
   ↓
Step 7: Apple processes payment
   - Charges credit card
   - Confirms transaction
   ↓
Step 8: Success! User sees:
   ✓ "Purchase successful!"
   ✓ Star badge appears on profile
   ✓ Profile shows in FEATUREd tab
```

---

## How Money Flows

### The Money Trail:

```
Customer's Bank Account
    ↓ [$14.99 charged]
Apple (Payment Processing)
    ↓ [Takes 30% = $4.50]
Your Business Bank Account
    ↓ [Receives 70% = $10.49]
Monthly Deposit from Apple
```

### Payment Distribution:

| Product | Customer Pays | Apple Takes (30%) | You Receive (70%) |
|---------|--------------|-------------------|-------------------|
| 24h     | $4.99        | $1.50             | $3.49             |
| 7d      | $14.99       | $4.50             | $10.49            |
| 30d     | $29.99       | $9.00             | $20.99            |

### When You Get Paid:

- **Apple pays you monthly**
- Payments arrive ~30 days after sale
- Deposited to your bank account
- You can track earnings in App Store Connect

---

## Technical Architecture

### System Components:

```
┌──────────────────────────────────────────────────┐
│                 YOUR FEATUR APP                   │
│  ┌────────────────────────────────────────────┐  │
│  │  StoreKitManager.swift                     │  │
│  │  - Loads products                          │  │
│  │  - Handles purchases                       │  │
│  │  - Verifies transactions                   │  │
│  │  - Grants access                           │  │
│  └────────────────────────────────────────────┘  │
└──────────────┬───────────────────────────────────┘
               │
               ├──────────────┬────────────────────┐
               │              │                    │
               ▼              ▼                    ▼
     ┌─────────────┐  ┌──────────────┐  ┌────────────────┐
     │  StoreKit 2 │  │   Firebase   │  │  App Store     │
     │  (Apple SDK)│  │   Firestore  │  │  Connect       │
     └─────────────┘  └──────────────┘  └────────────────┘
           │                 │                    │
           │                 │                    │
     (Processes         (Stores user        (Product
      payment)           featured            definitions
                         status)             & pricing)
```

---

## What Happens Behind the Scenes

### When User Clicks "Select Plan":

**1. App Initiates Purchase (StoreKitManager.swift line 86-99)**
```swift
// Your app calls:
let result = try await product.purchase()
// This triggers Apple's payment system
```

**2. Apple Shows Payment Sheet**
- Apple takes over the screen
- Shows available payment methods
- User selects method & authenticates

**3. Apple Processes Payment**
- Validates payment method
- Charges the account
- Creates transaction record
- Returns result to your app

**4. Your App Verifies Transaction (line 103-108)**
```swift
let transaction = try checkVerified(verification)
// This ensures it's a real purchase, not fraud
```

**Why verification is critical:**
- Prevents fake purchases
- Detects hacked/modified apps
- Ensures Apple actually charged them
- Protects against refund fraud

**5. Your App Grants Access (line 147-192)**
```swift
// Calculate expiration
let expiresAt = Date() + 7.days

// Save to Firebase
Firestore.collection("featured").document(userId).setData({
    featuredAt: now,
    expiresAt: expiresAt,
    status: "active"
})
```

**6. Your App Finishes Transaction (line 87)**
```swift
await transaction.finish()
// Tells Apple: "Got it, thanks!"
```

**7. User Gets Featured**
- Profile appears in FEATUREd tab
- Shows star badge
- Increased visibility until expiration

---

## Security & Verification

### How We Prevent Fraud:

**1. Transaction Verification**
```swift
switch result {
case .success(let verification):
    let transaction = try checkVerified(verification)
    // ✅ Only real purchases proceed
case .unverified:
    throw error
    // ❌ Fake purchases rejected
}
```

**2. Server-Side Validation**
- Apple signs each transaction
- Your app verifies the signature
- Can't be faked by hackers

**3. Duplicate Purchase Prevention**
```swift
// Check if already featured
if try await isUserCurrentlyFeatured() {
    show error: "You're already featured!"
    return // Don't charge again!
}
```

**4. Expiration Handling**
```swift
// Automatic expiration
if expiresAt > now {
    status = "active"
} else {
    status = "expired"
    // Removed from FEATUREd tab
}
```

---

## User Experience Flow

### Where Users Can Subscribe:

**Option 1: Profile Page (Three-Dots Menu)**
```
Profile → ··· → Get FEATUREd
```

**Option 2: Settings**
```
Profile → ··· → Settings → FEATUREd Status → Get FEATUREd
```

**Option 3: FEATUREd Tab**
```
FEATUREd Tab → "Want to be featured?" → Get Featured button
```

### What They See When Active:

**In Settings:**
```
┌─────────────────────────────────────────┐
│ ⭐ FEATUREd                             │
│ Active until Nov 30, 2025 at 3:00 PM    │
│ ✨ Your profile is being featured       │
└─────────────────────────────────────────┘
```

**On Profile:**
```
┌─────────────────────────────────────────┐
│ [Profile Photo with ⭐ badge]           │
│ John Doe                                 │
│ Content Creator                          │
│ ⭐ Featured                              │
└─────────────────────────────────────────┘
```

**In FEATUREd Tab:**
```
┌─────────────────────────────────────────┐
│ [User's profile card with star badge]   │
│ Featured 2 days ago                      │
└─────────────────────────────────────────┘
```

---

## Common Questions

### Q1: Is this a subscription that auto-renews?
**A: No!** It's a **one-time purchase** (consumable).
- You buy 7 days → Get featured for 7 days → Expires → Done
- No recurring charges
- Want to be featured again? Buy again

### Q2: What if user already purchased?
**A: Protected!**
```swift
// Before purchase, we check:
if (already featured) {
    show error
    return // Don't charge!
}
```

### Q3: How does user know when it expires?
**A: Multiple ways:**
1. Settings shows expiration date
2. Push notification before expiration (optional feature)
3. Featured badge disappears when expired

### Q4: What happens if payment fails?
**A: Graceful error handling:**
```
User Sees:
❌ "Payment failed. Please try again."

Behind the scenes:
- Transaction not created
- No access granted
- Error logged to analytics
- User can retry
```

### Q5: Can user get refund?
**A: Yes, through Apple:**
- User requests refund in App Store
- Apple reviews and approves/denies
- If approved: Apple refunds, removes access
- You get notified via transaction updates

### Q6: How do transaction updates work?
**A: Automatic monitoring:**
```swift
// Your app listens for updates (line 217-237)
for await transaction in Transaction.updates {
    // New purchase? Grant access
    // Refund? Remove access
    // Expiration? Update status
}
```

---

## Implementation Checklist

### What's Already Done ✅:
- [x] StoreKitManager handles all purchases
- [x] Transaction verification implemented
- [x] Firebase integration for featured status
- [x] Duplicate purchase prevention
- [x] Error handling
- [x] User interface (Get Featured sheet)
- [x] Settings integration
- [x] Profile menu integration

### What You Still Need To Do ⏳:
- [ ] Create products in App Store Connect
- [ ] Enable In-App Purchase capability in Xcode
- [ ] Test in Sandbox mode
- [ ] Submit products for Apple review
- [ ] Test with real purchase
- [ ] Launch!

---

## Testing the Payment Flow

### Phase 1: Sandbox Testing (FREE)
```
1. Create sandbox test account in App Store Connect
2. Sign in with test account on device
3. Make "purchase" (FREE in sandbox)
4. Verify featured status activates
5. Verify expiration works
6. Test error scenarios
```

### Phase 2: TestFlight (FREE)
```
1. Upload build to TestFlight
2. Add internal testers
3. Testers make "purchases" (FREE in TestFlight)
4. Get feedback on user experience
```

### Phase 3: Production (REAL $$$)
```
1. Use personal account
2. Buy cheapest tier ($4.99)
3. Verify full flow works
4. Check money arrives in bank account
```

---

## Troubleshooting

### Problem: "Cannot load products"
**Cause:** Products not created in App Store Connect
**Fix:** Create products with exact IDs:
- `com.featur.featured.24h`
- `com.featur.featured.7d`
- `com.featur.featured.30d`

### Problem: "Purchase failed"
**Causes:**
1. Network issue → Retry
2. Payment method invalid → Update payment
3. Already featured → Show error
4. Sandbox account issue → Create new test account

### Problem: "Access not granted after purchase"
**Debug steps:**
1. Check Firebase `featured` collection
2. Verify transaction finished
3. Check error logs
4. Verify expiration date calculated correctly

---

## Revenue Projections

### Example Scenario:
```
App has 10,000 active users
2% try to get featured = 200 users
80% complete purchase = 160 purchases

Distribution:
- 100 buy 7-day ($14.99) = $1,499
- 40 buy 24-hour ($4.99) = $199.60
- 20 buy 30-day ($29.99) = $599.80

Total Revenue: $2,298.40
Apple's cut (30%): -$689.52
Your earnings (70%): $1,608.88

Monthly estimate: $1,608.88
Yearly estimate: $19,306.56
```

---

## Summary (TL;DR)

**How it works:**
1. User taps "Get FEATUREd"
2. Sees 3 pricing options
3. Selects plan → Apple handles payment
4. App verifies transaction is real
5. App grants featured status in Firebase
6. User appears in FEATUREd tab
7. Expires automatically after period
8. User can purchase again if they want

**Money flow:**
- User pays Apple
- Apple takes 30%
- You get 70% monthly

**Security:**
- Transaction verification prevents fraud
- Duplicate purchase prevention
- Automatic expiration handling
- Refund protection

**User experience:**
- Simple one-tap purchase
- Clear pricing
- Immediate activation
- Visible status everywhere
- No surprise charges

---

**Your current implementation is ready!** 🎉
Just needs App Store Connect setup and testing.

For detailed setup instructions, see: `PAYMENT_IMPLEMENTATION_GUIDE.md`
