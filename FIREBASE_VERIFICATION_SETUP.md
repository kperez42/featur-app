# Firebase Verification Setup Guide

This guide explains how to set up **real** email and phone verification using Firebase Cloud Functions.

## Overview

The app now uses Firebase Cloud Functions to:
1. **Email Verification**: Send verification emails with clickable links
2. **Phone Verification**: Send SMS codes via Twilio or AWS SNS

## Prerequisites

1. Firebase project with Blaze plan (pay-as-you-go) - required for Cloud Functions
2. For email: Any email service (SendGrid, AWS SES, or Mailgun)
3. For phone: Twilio account OR AWS SNS

---

## Part 1: Set Up Firebase Cloud Functions

### 1. Initialize Firebase Functions

```bash
cd /path/to/your/project
firebase init functions
```

Select:
- JavaScript or TypeScript
- Install dependencies: Yes

### 2. Install Required Packages

```bash
cd functions
npm install --save @sendgrid/mail twilio
# OR for AWS
npm install --save aws-sdk
```

---

## Part 2: Email Verification Function

### Create `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail'); // or use nodemailer, AWS SES, etc.

admin.initializeApp();

// Set your SendGrid API key
sgMail.setApiKey(functions.config().sendgrid.key);

exports.sendEmailVerification = functions.https.onCall(async (data, context) => {
  const { email, token, userId } = data;

  // Create verification link
  const verificationLink = `https://your-app.web.app/verify-email?token=${token}&userId=${userId}`;

  const msg = {
    to: email,
    from: 'verify@yourapp.com', // Use your verified sender
    subject: 'Verify Your Email - Featur App',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #6366f1;">Verify Your Email Address</h2>
        <p>Thank you for signing up for Featur! Please click the button below to verify your email address:</p>
        <a href="${verificationLink}"
           style="display: inline-block; padding: 12px 24px; background-color: #6366f1; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0;">
          Verify Email
        </a>
        <p>Or copy and paste this link into your browser:</p>
        <p style="color: #666; word-break: break-all;">${verificationLink}</p>
        <p>This link will expire in 24 hours.</p>
        <p style="color: #999; font-size: 12px;">If you didn't request this verification, please ignore this email.</p>
      </div>
    `
  };

  try {
    await sgMail.send(msg);
    return { success: true };
  } catch (error) {
    console.error('Email send error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send email');
  }
});
```

### 3. Create Web Endpoint to Handle Email Verification

Create `public/verify-email.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Email Verification</title>
  <script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-firestore-compat.js"></script>
</head>
<body>
  <div id="message">Verifying your email...</div>

  <script>
    // Initialize Firebase
    const firebaseConfig = {
      // Your Firebase config here
    };
    firebase.initializeApp(firebaseConfig);
    const db = firebase.firestore();

    // Get token and userId from URL
    const urlParams = new URLSearchParams(window.location.search);
    const token = urlParams.get('token');
    const userId = urlParams.get('userId');

    // Verify the token
    db.collection('emailVerifications').doc(userId).get()
      .then((doc) => {
        if (!doc.exists) {
          document.getElementById('message').innerHTML = '❌ Invalid verification link';
          return;
        }

        const data = doc.data();
        if (data.token !== token) {
          document.getElementById('message').innerHTML = '❌ Invalid verification link';
          return;
        }

        if (new Date() > data.expiresAt.toDate()) {
          document.getElementById('message').innerHTML = '❌ Verification link expired';
          return;
        }

        // Mark as verified
        return db.collection('emailVerifications').doc(userId).update({
          verified: true
        });
      })
      .then(() => {
        document.getElementById('message').innerHTML = '✅ Email verified successfully! You can close this window.';
      })
      .catch((error) => {
        console.error('Error:', error);
        document.getElementById('message').innerHTML = '❌ Verification failed';
      });
  </script>
</body>
</html>
```

### 4. Set SendGrid API Key

```bash
firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY"
```

---

## Part 3: Phone Verification Function

### Using Twilio:

```javascript
const twilio = require('twilio');
const accountSid = functions.config().twilio.sid;
const authToken = functions.config().twilio.token;
const twilioPhoneNumber = functions.config().twilio.phone;
const client = twilio(accountSid, authToken);

exports.sendPhoneVerification = functions.https.onCall(async (data, context) => {
  const { phoneNumber, userId } = data;

  // Generate 6-digit code
  const code = Math.floor(100000 + Math.random() * 900000).toString();

  // Store verification code in Firestore
  const verificationId = admin.firestore().collection('phoneVerifications').doc().id;

  await admin.firestore().collection('phoneVerifications').doc(verificationId).set({
    userId,
    phoneNumber,
    code,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
  });

  // Send SMS via Twilio
  try {
    await client.messages.create({
      body: `Your Featur verification code is: ${code}`,
      from: twilioPhoneNumber,
      to: phoneNumber
    });

    return { success: true, verificationId };
  } catch (error) {
    console.error('SMS send error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send SMS');
  }
});

exports.verifyPhoneCode = functions.https.onCall(async (data, context) => {
  const { verificationId, code, userId } = data;

  const doc = await admin.firestore().collection('phoneVerifications').doc(verificationId).get();

  if (!doc.exists) {
    throw new functions.https.HttpsError('not-found', 'Verification not found');
  }

  const verification = doc.data();

  // Check if expired
  if (new Date() > verification.expiresAt.toDate()) {
    throw new functions.https.HttpsError('deadline-exceeded', 'Code expired');
  }

  // Check if code matches
  if (verification.code !== code) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid code');
  }

  // Delete verification doc (single use)
  await admin.firestore().collection('phoneVerifications').doc(verificationId).delete();

  return { success: true };
});
```

### 5. Set Twilio Credentials

```bash
firebase functions:config:set twilio.sid="YOUR_TWILIO_SID"
firebase functions:config:set twilio.token="YOUR_TWILIO_AUTH_TOKEN"
firebase functions:config:set twilio.phone="+1234567890"
```

---

## Part 4: Deploy Functions

```bash
firebase deploy --only functions
```

---

## Alternative: Using AWS SNS for SMS

If you prefer AWS SNS instead of Twilio:

```javascript
const AWS = require('aws-sdk');
AWS.config.update({
  accessKeyId: functions.config().aws.key,
  secretAccessKey: functions.config().aws.secret,
  region: 'us-east-1'
});

const sns = new AWS.SNS();

exports.sendPhoneVerification = functions.https.onCall(async (data, context) => {
  // ... same verification ID generation ...

  const params = {
    Message: `Your Featur verification code is: ${code}`,
    PhoneNumber: phoneNumber
  };

  try {
    await sns.publish(params).promise();
    return { success: true, verificationId };
  } catch (error) {
    console.error('SMS send error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send SMS');
  }
});
```

---

## Testing

### Email Verification:
1. Open app → Profile → Verification section
2. Tap "Verify" next to Email
3. Enter email address
4. Check email inbox for verification link
5. Click link in email
6. Tap "I've Verified - Check Status" in app
7. ✅ Email should show as verified

### Phone Verification:
1. Open app → Profile → Verification section
2. Tap "Verify" next to Phone Number
3. Enter phone number with country code
4. Receive SMS with 6-digit code
5. Enter code (auto-verifies on 6th digit)
6. ✅ Phone should show as verified

---

## Costs

### SendGrid:
- Free: 100 emails/day
- Essentials: $14.95/month for 50,000 emails

### Twilio SMS:
- ~$0.0075 per SMS (varies by country)
- $15 credit when you sign up

### AWS SNS:
- $0.00645 per SMS in US
- Very cheap for large volumes

### Firebase Functions:
- Free tier: 2M invocations/month
- After: $0.40 per million invocations

---

## Security Notes

1. **Never hardcode API keys** - Use Firebase config or environment variables
2. **Rate limit verification requests** - Add cooldowns in Cloud Functions
3. **Verify request origin** - Use Firebase Auth context in Cloud Functions
4. **Clean up expired codes** - Set up Firestore TTL or scheduled function

---

## Support

If you need help setting this up:
1. SendGrid docs: https://sendgrid.com/docs
2. Twilio docs: https://www.twilio.com/docs/sms
3. Firebase Functions: https://firebase.google.com/docs/functions

## Summary

You now have:
- ✅ Real email verification with clickable links
- ✅ Real SMS verification with Twilio/AWS
- ✅ Secure token-based verification
- ✅ Auto-expiring codes
- ✅ Production-ready implementation
