#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# deploy.sh  —  Full MediTrack Deployment Script
#
# Run this once to deploy everything:
#   chmod +x deploy.sh
#   ./deploy.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e  # Stop on any error

echo "🚀 MediTrack Deployment Starting..."
echo "======================================"

# ── STEP 1: Install Flutter dependencies ──────────────────────────────────────
echo ""
echo "📦 Step 1/6 — Installing Flutter packages..."
flutter pub get
echo "✅ Flutter packages installed"

# ── STEP 2: Build Flutter Web ─────────────────────────────────────────────────
echo ""
echo "🌐 Step 2/6 — Building Flutter Web app..."
flutter build web --release --web-renderer canvaskit
echo "✅ Web build complete → build/web/"

# ── STEP 3: Build Android APK ─────────────────────────────────────────────────
echo ""
echo "📱 Step 3/6 — Building Android release APK..."
flutter build apk --release
echo "✅ APK built → build/app/outputs/flutter-apk/app-release.apk"

# ── STEP 4: Install Firebase Functions dependencies ───────────────────────────
echo ""
echo "⚙️  Step 4/6 — Installing Cloud Functions dependencies..."
cd functions && npm install && cd ..
echo "✅ Functions dependencies installed"

# ── STEP 5: Deploy Firebase (Hosting + Functions + Firestore rules) ───────────
echo ""
echo "☁️  Step 5/6 — Deploying to Firebase..."
firebase deploy --only hosting,functions,firestore:rules
echo "✅ Firebase deployed!"

# ── STEP 6: Summary ───────────────────────────────────────────────────────────
echo ""
echo "======================================"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "======================================"
echo ""
echo "🌐 Web app:     https://YOUR_PROJECT_ID.web.app"
echo "📱 Android APK: build/app/outputs/flutter-apk/app-release.apk"
echo "⚙️  Functions:  Firebase Console → Functions"
echo ""
echo "📋 Next steps:"
echo "  1. Upload APK to Google Play Console"
echo "  2. Set CLAUDE_API_KEY secret in Firebase:"
echo "     firebase functions:secrets:set CLAUDE_API_KEY"
echo "  3. Replace AdMob test IDs in ads_service.dart"
echo "  4. Replace Razorpay test key in subscription_service.dart"
echo ""
