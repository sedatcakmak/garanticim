import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/ad_config.dart';
import 'auth_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final AuthService _authService = AuthService();

  RewardedAd? _socialFeedRewardedAd;
  RewardedAd? _addWarrantyRewardedAd;

  bool _isSocialFeedAdLoaded = false;
  bool _isAddWarrantyAdLoaded = false;

  /// Initialize Google Mobile Ads
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// Check if ads should be shown (premium users don't see ads)
  Future<bool> shouldShowAds() async {
    return !(await _authService.isPremiumUser());
  }

  /// Load social feed rewarded ad
  Future<void> loadSocialFeedAd() async {
    if (!await shouldShowAds()) return;
    if (_isSocialFeedAdLoaded) return;

    await RewardedAd.load(
      adUnitId: AdConfig.socialFeedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _socialFeedRewardedAd = ad;
          _isSocialFeedAdLoaded = true;
          print('Social feed ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isSocialFeedAdLoaded = false;
          print('Social feed ad failed to load: $error');
        },
      ),
    );
  }

  /// Load add warranty rewarded ad
  Future<void> loadAddWarrantyAd() async {
    if (!await shouldShowAds()) return;
    if (_isAddWarrantyAdLoaded) return;

    await RewardedAd.load(
      adUnitId: AdConfig.addWarrantyAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _addWarrantyRewardedAd = ad;
          _isAddWarrantyAdLoaded = true;
          print('Add warranty ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isAddWarrantyAdLoaded = false;
          print('Add warranty ad failed to load: $error');
        },
      ),
    );
  }

  /// Show social feed rewarded ad
  Future<bool> showSocialFeedAd() async {
    if (!await shouldShowAds()) return true; // Premium users skip
    if (!_isSocialFeedAdLoaded || _socialFeedRewardedAd == null) {
      return true; // If ad not loaded, proceed anyway
    }

    bool adWatched = false;

    await _socialFeedRewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        adWatched = true;
        print('User earned reward: ${reward.amount} ${reward.type}');
      },
    );

    _socialFeedRewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isSocialFeedAdLoaded = false;
        _socialFeedRewardedAd = null;
        // Preload next ad
        loadSocialFeedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isSocialFeedAdLoaded = false;
        _socialFeedRewardedAd = null;
        print('Social feed ad failed to show: $error');
      },
    );

    return adWatched;
  }

  /// Show add warranty rewarded ad
  Future<bool> showAddWarrantyAd() async {
    if (!await shouldShowAds()) return true; // Premium users skip
    if (!_isAddWarrantyAdLoaded || _addWarrantyRewardedAd == null) {
      return true; // If ad not loaded, proceed anyway
    }

    bool adWatched = false;

    await _addWarrantyRewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        adWatched = true;
        print('User earned reward: ${reward.amount} ${reward.type}');
      },
    );

    _addWarrantyRewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isAddWarrantyAdLoaded = false;
        _addWarrantyRewardedAd = null;
        // Preload next ad
        loadAddWarrantyAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isAddWarrantyAdLoaded = false;
        _addWarrantyRewardedAd = null;
        print('Add warranty ad failed to show: $error');
      },
    );

    return adWatched;
  }

  /// Dispose ads
  void dispose() {
    _socialFeedRewardedAd?.dispose();
    _addWarrantyRewardedAd?.dispose();
  }
}
