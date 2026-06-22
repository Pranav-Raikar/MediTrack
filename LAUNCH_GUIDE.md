# 🚀 MediTrack — Launch & Earn Guide

## What you're launching
A full SaaS EHR (Electronic Health Record) product with 3 revenue streams:

| Stream | Who pays | How much |
|---|---|---|
| AdMob ads | Google (auto) | ~₹3/1000 impressions |
| Patient Premium | Individual users | ₹99/month |
| Clinic plan | Hospitals/clinics | ₹2,999/month |

**Just 10 clinics = ₹29,990/month (~₹3.6 lakh/year)**

---

## 📁 New Files Added (this session)

```
lib/
├── models/diagnosis.dart               ← Doctor diagnosis records
├── services/
│   ├── ai_service.dart                 ← Claude API health summaries
│   ├── subscription_service.dart       ← Razorpay ₹99 + ₹2999 plans
│   └── ads_service.dart                ← Google AdMob ads
├── screens/
│   ├── doctor/doctor_portal_screen.dart ← Full doctor web dashboard
│   ├── premium/premium_screen.dart      ← Upgrade flow UI
│   └── ai/ai_insights_screen.dart       ← AI insights for premium users
functions/
├── index.js                            ← Firebase Cloud Function (Claude API)
└── package.json
firestore.rules                         ← Database security rules
deploy.sh                               ← One-command deploy
```

---

## 🛠️ COMPLETE SETUP GUIDE (read top to bottom)

---

### PART 1 — Firebase Setup (15 mins)

#### 1.1 Create Firebase project
1. Go to https://console.firebase.google.com
2. Click "Add project" → name: `MediTrack`
3. Enable Google Analytics → Continue

#### 1.2 Enable services
In Firebase console:
- **Authentication** → Sign-in method → Email/Password → Enable
  - Also enable **Google Sign-In** (optional but good for UX)
- **Firestore Database** → Create database → Start in **test mode** (we'll secure it later)
- **Hosting** → Get started (for web deployment)
- **Functions** → Get started

#### 1.3 Connect Flutter to Firebase
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# In your project root:
flutterfire configure
# Select your MediTrack project, check android + web
```
This auto-generates `lib/firebase_options.dart` ✅

#### 1.4 Deploy Firestore security rules
```bash
firebase deploy --only firestore:rules
```

---

### PART 2 — AdMob Setup (10 mins)

1. Go to https://admob.google.com → Sign in with Google
2. Click "Add app" → Android → Enter app name "MediTrack"
3. Create **2 ad units**:
   - Banner ad → copy the Ad Unit ID
   - Interstitial ad → copy the Ad Unit ID
4. Update `lib/services/ads_service.dart`:
   ```dart
   static const _bannerAdUnitId      = 'ca-app-pub-XXXX/XXXX'; // your real ID
   static const _interstitialAdUnitId = 'ca-app-pub-XXXX/XXXX'; // your real ID
   ```
5. Add your **AdMob App ID** to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
     android:name="com.google.android.gms.ads.APPLICATION_ID"
     android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
   ```

> ⚠️ Keep test IDs during development. Only switch to real IDs before publishing.

---

### PART 3 — Razorpay Setup (15 mins)

1. Go to https://razorpay.com → Sign up (free)
2. Complete KYC (Aadhaar + PAN + bank account — required to receive payments)
3. Dashboard → Settings → API Keys → Generate Key
4. Update `lib/services/subscription_service.dart`:
   ```dart
   static const _keyId = 'rzp_live_XXXXXXXXXXXXXXXX'; // your real key
   ```
5. Create subscription plans in Razorpay Dashboard:
   - Plan 1: ₹99/month → Patient Premium
   - Plan 2: ₹2999/month → Clinic Plan
   - Copy the Plan IDs and update subscription_service.dart

---

### PART 4 — Claude API Setup (5 mins)

1. Go to https://console.anthropic.com → Create account
2. Dashboard → API Keys → Create key → copy it
3. Set the key as a Firebase secret (NEVER paste in code):
   ```bash
   firebase functions:secrets:set CLAUDE_API_KEY
   # Paste your key when prompted
   ```
4. Update the function URL in `lib/services/ai_service.dart`:
   ```dart
   static const _functionUrl =
     'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/generateHealthSummary';
   ```

---

### PART 5 — Deploy Everything (5 mins)

```bash
# Make script executable
chmod +x deploy.sh

# Deploy everything at once
./deploy.sh
```

This builds web + APK + deploys Firebase in one go.

---

### PART 6 — Publish to Google Play Store

1. Go to https://play.google.com/console → Create developer account (one-time $25 fee)
2. Create new app → "MediTrack"
3. Upload `build/app/outputs/flutter-apk/app-release.apk`
4. Fill in store listing:
   - Title: "MediTrack - Medicine Reminder & Health Tracker"
   - Description: Focus on "remember medicines", "track BP/sugar", "share with doctor"
   - Category: Health & Fitness
   - Screenshots: Use the simulator from the chat
5. Set pricing → Free (AdMob earns revenue)
6. Submit for review (takes 3-7 days)

---

### PART 7 — Sell to Clinics (B2B)

This is where the real money is. Strategy:

#### Step 1: Build a demo
- Create a clinic demo account in Firebase
- Add 3-4 fake patients with real-looking data
- Practice the 5-min demo: "doctor sees patient vitals before they walk in"

#### Step 2: Target clinics in Pune
- Small general physician clinics (1-3 doctors) are the easiest
- They have NO software right now — paper records only
- Pitch: "₹2999/month = ₹100/day = less than one appointment"

#### Step 3: Cold outreach
- Visit clinics near you in person (most effective)
- WhatsApp the doctor directly: "I'm a Flutter developer, I built a free EHR demo for your clinic"
- Offer 1 month free trial

#### Step 4: Scale
- 5 clinics = ₹14,995/month (passive)
- 20 clinics = ₹59,980/month
- Refer other clinics → add referral discount

---

## 💰 Revenue Milestone Plan

| Milestone | Target | Monthly Revenue |
|---|---|---|
| Month 1 | App live on Play Store | ₹0 (building users) |
| Month 2 | 500 users, 1 clinic | ~₹5,000 |
| Month 3 | 1000 users, 3 clinics | ~₹15,000 |
| Month 6 | 3000 users, 10 clinics | ~₹40,000 |
| Month 12 | 10000 users, 25 clinics | ~₹1,00,000 |

---

## 🔒 Important Security Checklist

- [ ] Firestore rules deployed (`firebase deploy --only firestore:rules`)
- [ ] Claude API key stored as Firebase Secret (NOT in code)
- [ ] Razorpay live key only in production build (use environment variables)
- [ ] AdMob real IDs only added before Play Store submission
- [ ] HTTPS only — Firebase Hosting provides this automatically

---

## 📞 Support & Questions

Built by **Pranav Raikar** — Flutter Developer, Pune 🇮🇳

If you're stuck on any step, the error message will tell you exactly what's wrong.
Most common issues:
- `firebase_options.dart` missing → run `flutterfire configure`
- Razorpay not opening → check `razorpay_flutter` version in pubspec.yaml
- AI summary not working → verify the Cloud Function URL and API key secret
