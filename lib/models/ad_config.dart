import 'dart:io';

class AdConfig {
  static const String androidSocialFeedAdUnitId =
      'ca-app-pub-9756854719794108/1668277252';
  static const String androidAddWarrantyAdUnitId =
      'ca-app-pub-9756854719794108/4984991143';

  static const String iosSocialFeedAdUnitId =
      'ca-app-pub-9756854719794108/2733946918';
  static const String iosAddWarrantyAdUnitId =
      'ca-app-pub-9756854719794108/9791321615';

  static int adShowFrequency = 1;

  static String get socialFeedAdUnitId {
    if (Platform.isAndroid) {
      return androidSocialFeedAdUnitId;
    } else if (Platform.isIOS) {
      return iosSocialFeedAdUnitId;
    } else {
      return androidSocialFeedAdUnitId;
    }
  }

  static String get addWarrantyAdUnitId {
    if (Platform.isAndroid) {
      return androidAddWarrantyAdUnitId;
    } else if (Platform.isIOS) {
      return iosAddWarrantyAdUnitId;
    } else {
      return androidAddWarrantyAdUnitId;
    }
  }
}
