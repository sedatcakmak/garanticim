import 'package:intl/intl.dart';

class DateHelpers {
  /// Format date as dd.MM.yyyy
  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Format date as dd MMM yyyy (e.g., 24 Eki 2025)
  static String formatDateWithMonth(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  /// Calculate warranty expiration date
  static DateTime calculateExpiryDate(
    DateTime purchaseDate,
    int warrantyMonths,
  ) {
    return DateTime(
      purchaseDate.year,
      purchaseDate.month + warrantyMonths,
      purchaseDate.day,
    );
  }

  /// Get remaining days until warranty expires
  static int getRemainingDays(DateTime purchaseDate, int warrantyMonths) {
    final expiryDate = calculateExpiryDate(purchaseDate, warrantyMonths);
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  /// Check if warranty is expired
  static bool isExpired(DateTime purchaseDate, int warrantyMonths) {
    return getRemainingDays(purchaseDate, warrantyMonths) < 0;
  }

  /// Check if warranty is about to expire (within 30 days)
  static bool isExpiringSoon(DateTime purchaseDate, int warrantyMonths) {
    final remainingDays = getRemainingDays(purchaseDate, warrantyMonths);
    return remainingDays >= 0 && remainingDays <= 30;
  }

  /// Format remaining time as text
  static String formatRemainingTime(int remainingDays) {
    if (remainingDays < 0) {
      return '${remainingDays.abs()} gün önce doldu';
    } else if (remainingDays == 0) {
      return 'Bugün doluyor';
    } else if (remainingDays == 1) {
      return 'Yarın doluyor';
    } else if (remainingDays < 30) {
      return '$remainingDays gün kaldı';
    } else if (remainingDays < 365) {
      final months = (remainingDays / 30).floor();
      return '$months ay kaldı';
    } else {
      final years = (remainingDays / 365).floor();
      final months = ((remainingDays % 365) / 30).floor();
      return months > 0 ? '$years yıl $months ay kaldı' : '$years yıl kaldı';
    }
  }
}
