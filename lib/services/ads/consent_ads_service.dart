import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ilac_takip/core/config/env_config.dart';

/// UMP rıza formu + AdMob yaşam döngüsü.
/// Premium kullanıcıda ve web'de reklamlar yüklenmez.
class ConsentAdsService {
  ConsentAdsService();

  bool _mobileAdsInitialized = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  bool get isAdsReady => _mobileAdsInitialized;

  String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return EnvConfig.admobBannerIdIos;
    }
    return EnvConfig.admobBannerIdAndroid;
  }

  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return EnvConfig.admobInterstitialIdIos;
    }
    return EnvConfig.admobInterstitialIdAndroid;
  }

  Future<void> gatherConsentAndInitAds({required bool isPremium}) async {
    if (isPremium || kIsWeb) {
      _mobileAdsInitialized = false;
      return;
    }

    await _requestConsent();
    await _initMobileAdsIfAllowed();
  }

  Future<void> _requestConsent() async {
    final completer = Completer<void>();
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          if (formError != null && kDebugMode) {
            debugPrint('UMP form error: ${formError.message}');
          }
        });
        if (!completer.isCompleted) completer.complete();
      },
      (error) {
        if (kDebugMode) {
          debugPrint('UMP info update error: ${error.message}');
        }
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {},
    );
  }

  Future<void> _initMobileAdsIfAllowed() async {
    final canRequest = await ConsentInformation.instance.canRequestAds();
    if (!canRequest) {
      _mobileAdsInitialized = false;
      return;
    }
    await MobileAds.instance.initialize();
    _mobileAdsInitialized = true;
    await preloadInterstitial();
  }

  Future<void> disableAds() async {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _mobileAdsInitialized = false;
  }

  Future<void> preloadInterstitial() async {
    if (!_mobileAdsInitialized || _isInterstitialLoading) return;
    if (_interstitialAd != null) return;

    _isInterstitialLoading = true;
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
          if (kDebugMode) {
            debugPrint('Interstitial load failed: ${error.message}');
          }
        },
      ),
    );
  }

  Future<void> showInterstitialIfAvailable({required bool isPremium}) async {
    if (isPremium || !_mobileAdsInitialized || kIsWeb) return;
    final ad = _interstitialAd;
    if (ad == null) {
      await preloadInterstitial();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitial();
      },
    );
    await ad.show();
    _interstitialAd = null;
  }
}
