# Update Test Accounts to New Schema

Your test accounts are missing the new verification fields that were recently added. This guide will help you update all test accounts to have the same profile structure as your main account.

## What's Missing from Test Accounts

The profile preview now displays these new fields:
- ✅ **Email Verified Badge** - `isEmailVerified: Bool?`
- ✅ **Phone Verified Badge** - `isPhoneVerified: Bool?`
- ✅ **Email Address** - `email: String?`
- ✅ **Phone Number** - `phoneNumber: String?`

Old test accounts created before these fields were added will be missing them.

## Option 1: Update via Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database**
4. Find the `users` collection
5. For each test account document:
   - Click on the document
   - Click "Add field"
   - Add these fields:
     - Field: `email`, Type: string, Value: `test@example.com` (or any email)
     - Field: `isEmailVerified`, Type: boolean, Value: `false` (or `true` if you want the badge)
     - Field: `phoneNumber`, Type: string, Value: `+1234567890` (optional)
     - Field: `isPhoneVerified`, Type: boolean, Value: `false` (or `true` if you want the badge)

## Option 2: Batch Update Script

I can create a one-time migration function that updates all existing user profiles. Would you like me to:

1. Create a migration script that runs once in the app?
2. Create a Cloud Function to update all users?
3. Provide a command-line script?

## What Each Field Does

### `email: String?`
- Stores the user's email address
- Shown in the Verification section on profile page
- Not shown in profile preview (only the badge)

### `isEmailVerified: Bool?`
- `true` = Shows blue "Email Verified" badge in profile preview
- `false` or `nil` = No badge shown

### `phoneNumber: String?`
- Stores the user's phone number (format: +1234567890)
- Shown in the Verification section on profile page
- Not shown in profile preview (only the badge)

### `isPhoneVerified: Bool?`
- `true` = Shows green "Phone Verified" badge in profile preview
- `false` or `nil` = No badge shown

## Quick Fix for Testing

If you just want to test the visual appearance, manually add these fields to one test account:

```
isEmailVerified: true
isPhoneVerified: true
```

Then view that test account's profile preview - it should look identical to your main account with both verification badges showing.

## Need Help?

Let me know which option you prefer and I can:
- Create a migration script
- Walk you through Firebase Console updates
- Create sample test data for all 6 accounts
