import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/warranty_item.dart';
import '../utils/date_helpers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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

  Future<bool> requestPermissions() async {
    bool granted = false;

    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      granted =
          await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isRestricted) {
        final result = await Permission.notification.request();
        granted = result.isGranted;
      } else {
        granted = status.isGranted;
      }
    }

    return granted;
  }

  Future<void> scheduleWarrantyNotifications(WarrantyItem item) async {
    try {
      await initialize();

      await cancelWarrantyNotifications(item.id);

      final expiryDate = DateHelpers.calculateExpiryDate(
        item.purchaseDate,
        item.warrantyMonths,
      );

      final now = DateTime.now();

      final ninetyDaysBefore = expiryDate.subtract(const Duration(days: 90));
      if (ninetyDaysBefore.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(item.id, 90),
          title: 'Garanti Süresi Dolmak Üzere',
          body: '${item.productName} ürününün garantisi 3 ay içinde dolacak.',
          scheduledDate: ninetyDaysBefore,
        );
      }

      final thirtyDaysBefore = expiryDate.subtract(const Duration(days: 30));
      if (thirtyDaysBefore.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(item.id, 30),
          title: 'Garanti Süresi Dolmak Üzere',
          body: '${item.productName} ürününün garantisi 1 ay içinde dolacak.',
          scheduledDate: thirtyDaysBefore,
        );
      }

      final sevenDaysBefore = expiryDate.subtract(const Duration(days: 7));
      if (sevenDaysBefore.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(item.id, 7),
          title: 'Garanti Süresi Dolmak Üzere',
          body: '${item.productName} ürününün garantisi 7 gün içinde dolacak.',
          scheduledDate: sevenDaysBefore,
        );
      }

      if (expiryDate.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(item.id, 0),
          title: 'Garanti Süresi Doldu',
          body:
              '${item.productName} ürününün garanti süresi bugün sona eriyor.',
          scheduledDate: expiryDate,
        );
      }
    } catch (e) {
      throw Exception('Notification scheduling failed: $e');
    }
  }

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
      debugPrint('Error scheduling notification (ID: $id): $e');
      rethrow;
    }
  }

  Future<void> cancelWarrantyNotifications(String itemId) async {
    await _notifications.cancel(_getNotificationId(itemId, 90));
    await _notifications.cancel(_getNotificationId(itemId, 30));
    await _notifications.cancel(_getNotificationId(itemId, 7));
    await _notifications.cancel(_getNotificationId(itemId, 0));
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  int _getNotificationId(String itemId, int days) {
    return (itemId.hashCode + days).abs() % 2147483647;
  }

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

  Future<void> sendPostApprovedNotification(String productName) async {
    await showNotification(
      title: 'Paylaşım Onaylandı',
      body:
          '$productName ürününüzün paylaşımı onaylandı ve sosyal akışta görünüyor.',
    );
  }

  Future<void> sendPostRejectedNotification(String productName) async {
    await showNotification(
      title: 'Paylaşım Reddedildi',
      body: '$productName ürününüzün paylaşımı reddedildi.',
    );
  }
}
