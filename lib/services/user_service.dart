import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _userIdKey = 'user_id';
  static const String _createdAtKey = 'created_at';
  static final UserService _instance = UserService._internal();

  factory UserService() => _instance;

  UserService._internal();

  String? _cachedUserId;

  Future<String?> getUserId() async {
    if (_cachedUserId != null) {
      return _cachedUserId!;
    }
    return null;
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_createdAtKey);
    _cachedUserId = null;
  }
}
