// ─────────────────────────────────────────────────────────────────────────────
// services/subscription_service.dart  —  Razorpay Premium Subscription
//
// HOW IT WORKS:
//  1. User taps "Upgrade to Premium"
//  2. Razorpay payment sheet opens (UPI, cards, net banking — all supported)
//  3. On payment success → Firestore updates user to premium
//  4. Premium features unlock immediately
//
// SETUP:
//  1. Create account at https://razorpay.com
//  2. Get your Key ID from Dashboard → Settings → API Keys
//  3. Replace 'YOUR_RAZORPAY_KEY' below with your actual key
//
// DEPENDENCY: Add to pubspec.yaml:
//   razorpay_flutter: ^1.3.6
// ─────────────────────────────────────────────────────────────────────────────

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  static Razorpay? _razorpay;

  // ── Replace this with your Razorpay Key ID ─────────────────────────────────
  static const _keyId = 'YOUR_RAZORPAY_KEY_ID';
  // ──────────────────────────────────────────────────────────────────────────

  static const _premiumPriceMonthly = 9900; // ₹99 in paise (Razorpay uses paise)
  static const _clinicPriceMonthly  = 299900; // ₹2999 in paise

  /// Open Razorpay payment for patient premium (₹99/month)
  static void openPremiumCheckout({required String userEmail}) {
    _initRazorpay();
    final options = {
      'key': _keyId,
      'amount': _premiumPriceMonthly,
      'name': 'MediTrack Premium',
      'description': '1 month — No ads + AI insights + PDF reports',
      'prefill': {'email': userEmail},
      'theme': {'color': '#2E7D32'},
      // Recurring subscription (Razorpay recurring)
      'recurring': 1,
      'subscription_id': 'sub_XXXXX', // Create via Razorpay API
    };
    _razorpay!.open(options);
  }

  /// Open Razorpay payment for clinic plan (₹2999/month)
  static void openClinicCheckout({required String clinicEmail, required String clinicName}) {
    _initRazorpay();
    final options = {
      'key': _keyId,
      'amount': _clinicPriceMonthly,
      'name': 'MediTrack Clinic Plan',
      'description': 'Doctor portal + all patient records + AI',
      'prefill': {'email': clinicEmail},
      'notes': {'clinic_name': clinicName},
      'theme': {'color': '#4527A0'},
    };
    _razorpay!.open(options);
  }

  static void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
  }

  /// Called by Razorpay when payment succeeds
  static Future<void> _onSuccess(PaymentSuccessResponse response) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Mark user as premium in Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isPremium': true,
      'premiumSince': DateTime.now().toIso8601String(),
      'paymentId': response.paymentId,
    });

    print('Payment successful: ${response.paymentId}');
  }

  static void _onError(PaymentFailureResponse response) {
    print('Payment failed: ${response.message}');
  }

  /// Check if current user has premium
  static Future<bool> isPremium() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc.data()?['isPremium'] == true;
  }

  static void dispose() {
    _razorpay?.clear();
  }
}
