import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// services/ads_service.dart  —  Google AdMob Integration
//
// Replace test IDs with real ones from admob.google.com before publishing.
// Add your AdMob App ID in AndroidManifest.xml under com.google.android.gms.ads.APPLICATION_ID
// ─────────────────────────────────────────────────────────────────────────────

class AdsService {
  // Test IDs — safe during development, show test ads only
  static const _bannerAdUnitId      = 'ca-app-pub-3940256099942544/6300978111';
  static const _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  static InterstitialAd? _interstitialAd;

  /// Call once in main() before runApp()
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  /// Returns a banner ad widget — place at bottom of scaffold
  static Widget buildBanner() {
    final banner = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();

    return SizedBox(
      width: banner.size.width.toDouble(),
      height: banner.size.height.toDouble(),
      child: AdWidget(ad: banner),
    );
  }

  /// Shows an interstitial ad — max once per day per user
  static Future<void> showInterstitialIfDue() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString('last_interstitial');

    if (lastShown != null) {
      final lastDate = DateTime.parse(lastShown);
      if (DateTime.now().difference(lastDate).inHours < 24) return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.show();
      await prefs.setString('last_interstitial', DateTime.now().toIso8601String());
      _interstitialAd = null;
      _loadInterstitial();
    }
  }

  static void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded:       (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_)  => _interstitialAd = null,
      ),
    );
  }
}
