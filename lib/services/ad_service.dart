import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/save_manager.dart';

/// Manages a single preloaded interstitial for the post-game cadence.
///
/// Release builds are intentionally disabled until an AdMob unit ID is passed
/// with --dart-define. Debug builds use Google's official test ad units.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const _androidTestId = 'ca-app-pub-3940256099942544/1033173712';
  static const _iosTestId = 'ca-app-pub-3940256099942544/4411468910';
  static const _androidReleaseId =
      String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL_ID');
  static const _iosReleaseId =
      String.fromEnvironment('ADMOB_IOS_INTERSTITIAL_ID');

  InterstitialAd? _interstitial;
  bool _isLoading = false;

  String get _adUnitId {
    if (Platform.isAndroid) {
      return kDebugMode ? _androidTestId : _androidReleaseId;
    }
    if (Platform.isIOS) {
      return kDebugMode ? _iosTestId : _iosReleaseId;
    }
    return '';
  }

  bool get isConfigured => _adUnitId.isNotEmpty;

  Future<void> initialize() async {
    if (!isConfigured) return;
    await MobileAds.instance.initialize();
    await _loadInterstitial();
  }

  Future<void> _loadInterstitial() async {
    if (!isConfigured || _isLoading || _interstitial != null) return;

    _isLoading = true;
    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (_) {
          _isLoading = false;
        },
      ),
    );
  }

  /// Displays a preloaded ad only when the player has not removed ads.
  Future<void> showInterstitialIfAvailable() async {
    if (!isConfigured || SaveManager.instance.save.adsRemoved) return;

    final ad = _interstitial;
    if (ad == null) {
      await _loadInterstitial();
      return;
    }

    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }
}
