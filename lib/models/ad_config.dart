import 'dart:io';

class AdConfig {
  // Test Ad Unit IDs (production'da değiştirilecek)
  static const String androidSocialFeedAdUnitId =
      'ca-app-pub-9756854719794108/1668277252'; // Test rewarded video
  static const String iosSocialFeedAdUnitId =
      'ca-app-pub-9756854719794108/2733946918'; // Test rewarded video

  static const String androidAddWarrantyAdUnitId =
      'ca-app-pub-9756854719794108/4984991143'; // Test rewarded video
  static const String iosAddWarrantyAdUnitId =
      'ca-app-pub-9756854719794108/9791321615'; // Test rewarded video

  // Ad show frequency
  static const int adShowFrequency =
      1; // Her kaç işlemde bir reklam gösterilecek

  /// Get platform-specific ad unit ID for social feed
  static String get socialFeedAdUnitId {
    if (Platform.isAndroid) {
      return androidSocialFeedAdUnitId;
    } else if (Platform.isIOS) {
      return iosSocialFeedAdUnitId;
    }
    return androidSocialFeedAdUnitId; // Şimdilik Android default
  }

  /// Get platform-specific ad unit ID for add warranty
  static String get addWarrantyAdUnitId {
    // TODO: Platform check eklenecek
    return androidAddWarrantyAdUnitId; // Şimdilik Android default
  }
}
