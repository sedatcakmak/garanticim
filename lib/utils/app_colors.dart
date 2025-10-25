import 'package:flutter/cupertino.dart';

class AppColors {
  static bool get isDark {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  static Color get background =>
      isDark ? Color(0xFF000000) : Color.fromARGB(255, 242, 242, 247);

  static Color get white => isDark ? Color(0xFF171717) : Color(0xFFFFFFFF);

  static Color get black =>
      isDark ? Color.fromARGB(255, 229, 229, 234) : Color(0xFF000000);

  static Color get gray => isDark
      ? Color.fromARGB(255, 199, 199, 204)
      : Color.fromARGB(153, 60, 60, 67);

  static Color get success =>
      isDark ? Color(0xFF30D158) : Color(0xFF34C759);

  static Color get warning =>
      isDark ? Color(0xFFFFD60A) : Color(0xFFFFCC00);

  static Color get danger =>
      isDark ? Color(0xFFFF453A) : Color(0xFFFF3B30);

  static Color get info =>
      isDark ? Color(0xFF64D2FF) : Color(0xFF007AFF);

  static Color get primary => info;

  static Color get text => black;

  static Color get textSecondary => gray;
}
