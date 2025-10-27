import 'package:intl/intl.dart';

class DateHelpers {
  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  static String formatDateWithMonth(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

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

  static int getRemainingDays(DateTime purchaseDate, int warrantyMonths) {
    final expiryDate = calculateExpiryDate(purchaseDate, warrantyMonths);
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  static bool isExpired(DateTime purchaseDate, int warrantyMonths) {
    return getRemainingDays(purchaseDate, warrantyMonths) < 0;
  }

  static bool isExpiringSoon(DateTime purchaseDate, int warrantyMonths) {
    final remainingDays = getRemainingDays(purchaseDate, warrantyMonths);
    return remainingDays >= 0 && remainingDays <= 30;
  }

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
