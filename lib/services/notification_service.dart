import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/warranty_item.dart';
import '../utils/date_helpers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? false;
  }

  /// Schedule notifications for a warranty item
  Future<void> scheduleWarrantyNotifications(WarrantyItem item) async {
    try {
      await initialize();

      // Cancel existing notifications for this item
      await cancelWarrantyNotifications(item.id);

      final expiryDate = DateHelpers.calculateExpiryDate(
        item.purchaseDate,
        item.warrantyMonths,
      );

      final now = DateTime.now();

      // Schedule 30 days before expiry
      final thirtyDaysBefore = expiryDate.subtract(const Duration(days: 30));
      if (thirtyDaysBefore.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(item.id, 30),
          title: 'Garanti Süresi Dolmak Üzere',
          body: '${item.productName} ürününün garantisi 30 gün içinde dolacak.',
          scheduledDate: thirtyDaysBefore,
        );
      }

      // Schedule 7 days before expiry
      final sevenDaysBefore = expiryDate.subtract(const Duration(days: 7));
      if (sevenDaysBefore.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(item.id, 7),
          title: 'Garanti Süresi Dolmak Üzere',
          body: '${item.productName} ürününün garantisi 7 gün içinde dolacak.',
          scheduledDate: sevenDaysBefore,
        );
      }

      // Schedule on expiry day
      if (expiryDate.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(item.id, 0),
          title: 'Garanti Süresi Doldu',
          body: '${item.productName} ürününün garanti süresi bugün sona eriyor.',
          scheduledDate: expiryDate,
        );
      }
    } catch (e) {
      // Rethrow to be caught by the calling code
      throw Exception('Notification scheduling failed: $e');
    }
  }

  /// Schedule a notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'warranty_reminders',
        'Garanti Hatırlatıcıları',
        channelDescription: 'Garanti süresi dolacak ürünler için bildirimler',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error scheduling notification (ID: $id): $e');
      rethrow;
    }
  }

  /// Cancel all notifications for a warranty item
  Future<void> cancelWarrantyNotifications(String itemId) async {
    await _notifications.cancel(_getNotificationId(itemId, 30));
    await _notifications.cancel(_getNotificationId(itemId, 7));
    await _notifications.cancel(_getNotificationId(itemId, 0));
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get unique notification ID from warranty ID and days
  int _getNotificationId(String itemId, int days) {
    return (itemId.hashCode + days).abs() % 2147483647;
  }

  /// Show immediate notification (for testing)
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'warranty_reminders',
      'Garanti Hatırlatıcıları',
      channelDescription: 'Garanti süresi dolacak ürünler için bildirimler',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }

  /// Send notification when post is approved
  Future<void> sendPostApprovedNotification(String productName) async {
    await showNotification(
      title: 'Paylaşım Onaylandı',
      body: '$productName ürününüzün paylaşımı onaylandı ve sosyal akışta görünüyor.',
    );
  }

  /// Send notification when post is rejected
  Future<void> sendPostRejectedNotification(String productName) async {
    await showNotification(
      title: 'Paylaşım Reddedildi',
      body: '$productName ürününüzün paylaşımı reddedildi.',
    );
  }

  /// Send notification when subscription is expiring
  Future<void> sendSubscriptionExpiryReminder(int daysLeft) async {
    await showNotification(
      title: 'Abonelik Süresi Dolmak Üzere',
      body: 'Premium aboneliğiniz $daysLeft gün içinde sona erecek.',
    );
  }

  /// Send notification when warranty limit is reached
  Future<void> sendWarrantyLimitReachedNotification() async {
    await showNotification(
      title: 'Fatura Limiti Doldu',
      body: 'Ücretsiz hesaplarda maksimum 3 aktif fatura oluşturabilirsiniz. Premium üyelik için yükseltin.',
    );
  }
}
