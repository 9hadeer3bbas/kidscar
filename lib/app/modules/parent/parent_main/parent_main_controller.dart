import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/repos/auth_repository.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/services/cache_service.dart';

class ParentMainController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late final CacheService _cacheService;

  final selectedIndex = 0.obs;
  final isLoading = false.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    print('=== PARENT MAIN CONTROLLER INIT ===');
    _initializeCacheServiceAndCheckLogin();
  }

  Future<void> _initializeCacheServiceAndCheckLogin() async {
    try {
      _cacheService = await CacheService.getInstance();
      print('Cache service initialized in ParentMainController');

      // Add a small delay to ensure everything is properly initialized
      await Future.delayed(const Duration(milliseconds: 500));

      // Now check login status
      await _checkLoginStatus();
    } catch (e) {
      print('ERROR: Failed to initialize cache service: $e');
      // If cache initialization fails, still check login status
      await _checkLoginStatus();
    }
  }

  /// Check if user is logged in and has valid cached data
  Future<void> _checkLoginStatus() async {
    try {
      print('=== CHECKING LOGIN STATUS IN PARENT MAIN ===');

      // Check Firebase Auth first
      final firebaseUser = _firebaseAuth.currentUser;
      print('Firebase current user: ${firebaseUser?.email}');
      print('Firebase user verified: ${firebaseUser?.emailVerified}');

      if (firebaseUser == null) {
        print('No Firebase user, redirecting to signin');
        Get.offAllNamed('/signin');
        return;
      }

      // Check if user is verified
      if (!firebaseUser.emailVerified) {
        print('User email not verified, redirecting to signin');
        Get.offAllNamed('/signin');
        return;
      }

      // Try to get cached user data with retry logic
      UserModel? cachedUser;
      int retryCount = 0;
      const maxRetries = 3;

      while (cachedUser == null && retryCount < maxRetries) {
        try {
          cachedUser = await _authRepository.getCachedUserData();
          print(
            'Attempt ${retryCount + 1}: Cached user: ${cachedUser?.toJson()}',
          );

          if (cachedUser == null) {
            retryCount++;
            if (retryCount < maxRetries) {
              print('No cached user found, retrying in 200ms...');
              await Future.delayed(const Duration(milliseconds: 200));
            }
          }
        } catch (e) {
          print('Error getting cached user (attempt ${retryCount + 1}): $e');
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }
      }

      if (cachedUser != null && cachedUser.role == 'parent') {
        print('Parent is logged in and verified, staying on ParentMainView');
        currentUser.value = cachedUser;
      } else if (cachedUser == null) {
        print('WARNING: No cached user data found, but Firebase user exists');
        print(
          'This might be a timing issue. Staying on ParentMainView for now.',
        );
        // Don't redirect immediately - this might be a timing issue
        // The user can still use the app, and we'll check again later if needed
      } else {
        print('ERROR: User is logged in but not a parent');
        print('Cached user: ${cachedUser.toJson()}');
        // User is logged in but not a parent, redirect to signin
        Get.offAllNamed('/signin');
      }
    } catch (e) {
      print('=== PARENT MAIN LOGIN CHECK ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('Error details: $e');
      // If there's an error checking login status, redirect to signin
      Get.offAllNamed('/signin');
    }
  }

  /// Change selected tab index
  void changeTabIndex(int index) {
    print('Changing tab to index: $index');
    selectedIndex.value = index;
  }

  /// Logout user and redirect to signin
  Future<void> logout() async {
    try {
      print('=== PARENT LOGOUT ===');
      isLoading.value = true;

      // Sign out from Firebase Auth
      await _firebaseAuth.signOut();
      print('Firebase Auth signout successful');

      // Clear any cached data
      await _cacheService.clearCache();
      print('Cache cleared');

      // Navigate to signin
      Get.offAllNamed('/signin');
    } catch (e) {
      print('=== PARENT LOGOUT ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('Error details: $e');

      // Even if logout fails, redirect to signin
      Get.offAllNamed('/signin');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh user data from server
  Future<void> refreshUserData() async {
    try {
      print('=== REFRESHING USER DATA ===');
      isLoading.value = true;

      final user = await _authRepository.getCachedUserData();
      if (user != null) {
        print('User data refreshed: ${user.toJson()}');
        currentUser.value = user;
      } else {
        print('ERROR: No user data found during refresh');
        Get.offAllNamed('/signin');
      }
    } catch (e) {
      print('=== REFRESH USER DATA ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('Error details: $e');

      // If refresh fails, redirect to signin
      Get.offAllNamed('/signin');
    } finally {
      isLoading.value = false;
    }
  }

  void setCurrentUser(UserModel user) {
    currentUser.value = user;
  }

  @override
  void onClose() {
    print('=== PARENT MAIN CONTROLLER CLOSED ===');
    super.onClose();
  }
}
