import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  static const String _baseUrl = 'https://api.daimapp.com';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _phoneKey = 'user_phone';
  static const String _guestModeKey = 'is_guest_mode';

  /// Send OTP to phone number
  Future<bool> sendOTP(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send_otp'),
        body: {'phone': phone},
      );

      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('Error sending OTP: $e');
      return false;
    }
  }

  /// Verify OTP code
  Future<bool> verifyOTP(String phone, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify_otp'),
        body: {'phone': phone, 'code': code},
      );

      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('Error verifying OTP: $e');
      return false;
    }
  }

  /// Check if user exists by phone number
  Future<UserModel?> getUserByPhone(String phone) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return UserModel.fromMap(doc.data());
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting user by phone: $e');
      return null;
    }
  }

  /// Create new user
  Future<UserModel?> createUser(String phone, String name) async {
    try {
      final userId = _firestore.collection(_collectionName).doc().id;
      final user = UserModel(
        userId: userId,
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .set(user.toMap());

      // Save to local storage
      await _saveUserLocally(userId, name, phone);

      return user;
    } catch (e) {
      // ignore: avoid_print
      print('Error creating user: $e');
      return null;
    }
  }

  /// Save user credentials locally
  Future<void> _saveUserLocally(
    String userId,
    String userName,
    String phone,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_phoneKey, phone);
  }

  Future<void> loginUser(UserModel user) async {
    await _saveUserLocally(user.userId, user.name, user.phone);
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final userId = await getCurrentUserId();
    return userId != null && userId.isNotEmpty;
  }

  /// Get current user data
  Future<UserModel?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_guestModeKey);
  }

  /// Guest mode methods
  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestModeKey) ?? false;
  }

  Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    if (isGuest) {
      await prefs.setBool(_guestModeKey, true);
    } else {
      await prefs.remove(_guestModeKey);
    }
  }

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final user = await getCurrentUser();
      return user?.isAdmin ?? false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Check if current user has active premium subscription
  Future<bool> isPremiumUser() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;
      return user.isPremiumActive;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  /// Get premium expiry date
  Future<DateTime?> getPremiumExpiryDate() async {
    try {
      final user = await getCurrentUser();
      return user?.premiumExpiryDate;
    } catch (e) {
      print('Error getting premium expiry date: $e');
      return null;
    }
  }

  /// Update user premium status
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
        'premiumExpiryDate':
            expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
        'subscriptionId': subscriptionId,
      });

      return true;
    } catch (e) {
      print('Error updating premium status: $e');
      return false;
    }
  }

  /// Delete user account and all associated data
  Future<bool> deleteAccount() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return false;

      // Delete user document from Firestore
      await _firestore.collection(_collectionName).doc(userId).delete();

      // Clear local storage
      await logout();

      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}
