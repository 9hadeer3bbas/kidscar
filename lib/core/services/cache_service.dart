import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidscar/data/models/user_model.dart';

class CacheService {
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _lastLoginKey = 'last_login';
  static const String _tokenKey = 'auth_token';

  static CacheService? _instance;
  static SharedPreferences? _prefs;

  CacheService._internal();

  static Future<CacheService> getInstance() async {
    _instance ??= CacheService._internal();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// Save user data to cache
  Future<void> saveUserData(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _prefs!.setString(_userDataKey, userJson);
      await _prefs!.setBool(_isLoggedInKey, true);
      await _prefs!.setString(_lastLoginKey, DateTime.now().toIso8601String());
    } catch (e) {
      throw Exception('Failed to save user data to cache: $e');
    }
  }

  /// Get cached user data
  Future<UserModel?> getUserData() async {
    try {
      final userJson = _prefs!.getString(_userDataKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data from cache: $e');
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      return _prefs!.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Save authentication token
  Future<void> saveAuthToken(String token) async {
    try {
      await _prefs!.setString(_tokenKey, token);
    } catch (e) {
      throw Exception('Failed to save auth token: $e');
    }
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    try {
      return _prefs!.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Get last login time
  Future<DateTime?> getLastLogin() async {
    try {
      final lastLoginString = _prefs!.getString(_lastLoginKey);
      if (lastLoginString != null) {
        return DateTime.parse(lastLoginString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update specific user fields
  Future<void> updateUserField(String field, dynamic value) async {
    try {
      final user = await getUserData();
      if (user != null) {
        final userMap = user.toJson();
        userMap[field] = value;
        userMap['updatedAt'] = DateTime.now().toIso8601String();

        final updatedUser = UserModel.fromJson(userMap);
        await saveUserData(updatedUser);
      }
    } catch (e) {
      throw Exception('Failed to update user field: $e');
    }
  }

  /// Check if cache is valid (not expired)
  Future<bool> isCacheValid({Duration maxAge = const Duration(days: 7)}) async {
    try {
      final lastLogin = await getLastLogin();
      if (lastLogin == null) return false;

      final now = DateTime.now();
      return now.difference(lastLogin) < maxAge;
    } catch (e) {
      return false;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await _prefs!.remove(_userDataKey);
      await _prefs!.remove(_isLoggedInKey);
      await _prefs!.remove(_lastLoginKey);
      await _prefs!.remove(_tokenKey);
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  /// Clear only user data but keep login status
  Future<void> clearUserData() async {
    try {
      await _prefs!.remove(_userDataKey);
      await _prefs!.remove(_lastLoginKey);
    } catch (e) {
      throw Exception('Failed to clear user data: $e');
    }
  }

  /// Get cache size (approximate)
  Future<int> getCacheSize() async {
    try {
      int size = 0;
      final keys = [_userDataKey, _isLoggedInKey, _lastLoginKey, _tokenKey];

      for (final key in keys) {
        final value = _prefs!.getString(key);
        if (value != null) {
          size += value.length;
        }
      }
      return size;
    } catch (e) {
      return 0;
    }
  }

  /// Check if user data exists in cache
  Future<bool> hasUserData() async {
    try {
      return _prefs!.containsKey(_userDataKey);
    } catch (e) {
      return false;
    }
  }

  /// Force refresh user data from server
  Future<void> refreshUserData(UserModel user) async {
    try {
      await clearUserData();
      await saveUserData(user);
    } catch (e) {
      throw Exception('Failed to refresh user data: $e');
    }
  }
}
