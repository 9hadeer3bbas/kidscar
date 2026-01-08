import 'package:kidscar/core/services/cache_service.dart';
import 'package:kidscar/data/repos/driver_auth_repo.dart';
import 'package:kidscar/data/models/user_model.dart';

/// Example usage of the cache service
class CacheExample {
  late final CacheService _cacheService;
  final DriverAuthRepository _authRepo = DriverAuthRepository();

  CacheExample() {
    _initializeCacheService();
  }

  Future<void> _initializeCacheService() async {
    _cacheService = await CacheService.getInstance();
  }

  /// Example: Check if user is logged in on app startup
  Future<bool> checkLoginStatus() async {
    try {
      final isLoggedIn = await _cacheService.isLoggedIn();
      if (isLoggedIn) {
        // Check if cache is still valid
        final isValid = await _cacheService.isCacheValid();
        if (isValid) {
          print('User is logged in and cache is valid');
          return true;
        } else {
          print('Cache expired, need to refresh');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// Example: Get user data from cache
  Future<UserModel?> getUserFromCache() async {
    try {
      final user = await _cacheService.getUserData();
      if (user != null) {
        print('User data loaded from cache: ${user.fullName}');
        return user;
      } else {
        print('No user data in cache');
        return null;
      }
    } catch (e) {
      print('Error getting user from cache: $e');
      return null;
    }
  }

  /// Example: Login and cache user data
  Future<bool> loginAndCache(String email, String password) async {
    try {
      // Login using auth repository
      await _authRepo.loginDriver(email: email, password: password);

      // Get user data from cache (should be cached by loginDriver method)
      final user = await _cacheService.getUserData();
      if (user != null) {
        print('User logged in and cached: ${user.fullName}');
        return true;
      } else {
        print('Login successful but failed to cache user data');
        return false;
      }
    } catch (e) {
      print('Login failed: $e');
      return false;
    }
  }

  /// Example: Update user profile and cache
  Future<bool> updateProfile(String newName, String newPhone) async {
    try {
      final updates = {'fullName': newName, 'phoneNumber': newPhone};

      await _authRepo.updateUserProfile(updates);
      print('Profile updated and cache refreshed');
      return true;
    } catch (e) {
      print('Failed to update profile: $e');
      return false;
    }
  }

  /// Example: Logout and clear cache
  Future<bool> logoutAndClearCache() async {
    try {
      await _authRepo.logout();
      print('User logged out and cache cleared');
      return true;
    } catch (e) {
      print('Logout failed: $e');
      return false;
    }
  }

  /// Example: Get cache information
  Future<void> getCacheInfo() async {
    try {
      final hasData = await _cacheService.hasUserData();
      final cacheSize = await _cacheService.getCacheSize();
      final lastLogin = await _cacheService.getLastLogin();

      print('Cache Info:');
      print('- Has user data: $hasData');
      print('- Cache size: $cacheSize bytes');
      print('- Last login: $lastLogin');
    } catch (e) {
      print('Error getting cache info: $e');
    }
  }
}
