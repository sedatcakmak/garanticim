import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  static const String _userIdKey = 'user_id';

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_device';
    } else {
      return 'unsupported_platform';
    }
  }

  Future<UserModel> initUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? localUserId = prefs.getString(_userIdKey);

    if (localUserId != null && localUserId.isNotEmpty) {
      final existingUser = await getCurrentUser();
      if (existingUser != null) return existingUser;
    }

    final deviceId = await _getDeviceId();

    final snapshot = await _firestore
        .collection(_collectionName)
        .where('deviceId', isEqualTo: deviceId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final user = UserModel.fromMap(snapshot.docs.first.data());
      await prefs.setString(_userIdKey, user.userId);
      return user;
    }

    final userId = _firestore.collection(_collectionName).doc().id;
    final user = UserModel(
      userId: userId,
      deviceId: deviceId,
      createdAt: DateTime.now(),
      isAdmin: false,
      isPremium: false,
      premiumExpiryDate: null,
      subscriptionId: null,
    );

    await _firestore.collection(_collectionName).doc(userId).set(user.toMap());
    await prefs.setString(_userIdKey, userId);
    return user;
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<UserModel?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    final doc = await _firestore.collection(_collectionName).doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    return userId != null && userId.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isAdmin() async {
    try {
      final user = await getCurrentUser();
      return user?.isAdmin ?? false;
    } catch (e) {
      debugPrint('Error checking admin: $e');
      return false;
    }
  }

  Future<bool> isPremiumUser() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;
      return user.isPremium;
    } catch (e) {
      debugPrint('Error checking premium: $e');
      return false;
    }
  }

  Future<bool> isRegistered() async {
    try {
      final user = await getCurrentUser();
      return user?.isRegistered ?? false;
    } catch (e) {
      debugPrint('Error checking registration: $e');
      return false;
    }
  }

  Future<void> completeRegistration({
    required String phoneNumber,
    required String name,
    required String city,
  }) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');

    await _firestore.collection(_collectionName).doc(userId).update({
      'phoneNumber': phoneNumber,
      'name': name,
      'city': city,
      'isRegistered': true,
    });
  }

  Future<DateTime?> getPremiumExpiryDate() async {
    try {
      final user = await getCurrentUser();
      return user?.premiumExpiryDate;
    } catch (e) {
      debugPrint('Error getting expiry date: $e');
      return null;
    }
  }

  Future<bool> updatePremiumStatus({
    required bool isPremium,
    DateTime? expiryDate,
    String? subscriptionId,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return false;

      await _firestore.collection(_collectionName).doc(userId).update({
        'isPremium': isPremium,
        'premiumExpiryDate': expiryDate != null
            ? Timestamp.fromDate(expiryDate)
            : null,
        'subscriptionId': subscriptionId,
      });

      return true;
    } catch (e) {
      debugPrint('Error updating premium: $e');
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return false;

      await _firestore.collection(_collectionName).doc(userId).delete();
      await logout();
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }
}
