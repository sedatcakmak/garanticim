import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/ad_config.dart';
import 'auth_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final AuthService _authService = AuthService();

  RewardedInterstitialAd? _socialFeedRewardedAd;
  RewardedInterstitialAd? _addWarrantyRewardedAd;

  bool _isSocialFeedAdLoaded = false;
  bool _isAddWarrantyAdLoaded = false;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  Future<bool> shouldShowAds() async {
    return !(await _authService.isPremiumUser());
  }

  Future<void> loadSocialFeedAd() async {
    if (!await shouldShowAds()) return;
    if (_isSocialFeedAdLoaded) return;

    await RewardedInterstitialAd.load(
      adUnitId: AdConfig.socialFeedAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _socialFeedRewardedAd = ad;
          _isSocialFeedAdLoaded = true;
          debugPrint('Social feed ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isSocialFeedAdLoaded = false;
          debugPrint('Social feed ad failed to load: $error');
        },
      ),
    );
  }

  Future<void> loadAddWarrantyAd() async {
    if (!await shouldShowAds()) return;
    if (_isAddWarrantyAdLoaded) return;

    await RewardedInterstitialAd.load(
      adUnitId: AdConfig.addWarrantyAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _addWarrantyRewardedAd = ad;
          _isAddWarrantyAdLoaded = true;
          debugPrint('Add warranty ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isAddWarrantyAdLoaded = false;
          debugPrint('Add warranty ad failed to load: $error');
        },
      ),
    );
  }

  Future<bool> showSocialFeedAd() async {
    if (!await shouldShowAds()) return true;
    if (!_isSocialFeedAdLoaded || _socialFeedRewardedAd == null) {
      return true;
    }

    bool adWatched = false;

    await _socialFeedRewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        adWatched = true;
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
      },
    );

    _socialFeedRewardedAd!.fullScreenContentCallback =
        FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _isSocialFeedAdLoaded = false;
            _socialFeedRewardedAd = null;
            loadSocialFeedAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _isSocialFeedAdLoaded = false;
            _socialFeedRewardedAd = null;
            debugPrint('Social feed ad failed to show: $error');
          },
        );

    return adWatched;
  }

  Future<bool> showAddWarrantyAd() async {
    if (!await shouldShowAds()) return true;
    if (!_isAddWarrantyAdLoaded || _addWarrantyRewardedAd == null) {
      return true;
    }

    bool adWatched = false;

    await _addWarrantyRewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        adWatched = true;
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
      },
    );

    _addWarrantyRewardedAd!.fullScreenContentCallback =
        FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _isAddWarrantyAdLoaded = false;
            _addWarrantyRewardedAd = null;
            loadAddWarrantyAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _isAddWarrantyAdLoaded = false;
            _addWarrantyRewardedAd = null;
            debugPrint('Add warranty ad failed to show: $error');
          },
        );

    return adWatched;
  }

  void dispose() {
    _socialFeedRewardedAd?.dispose();
    _addWarrantyRewardedAd?.dispose();
  }
}
