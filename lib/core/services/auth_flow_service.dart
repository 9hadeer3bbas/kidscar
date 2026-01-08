import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kidscar/core/services/cache_service.dart';
import 'package:kidscar/data/models/user_model.dart';
import 'package:kidscar/data/repos/auth_repository.dart';
import 'package:kidscar/core/routes/get_routes.dart';

/// Professional Authentication Flow Service
/// Handles login state checking, cache validation, and role-based navigation
class AuthFlowService extends GetxService {
  static AuthFlowService get instance => Get.find<AuthFlowService>();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final AuthRepository _authRepository = AuthRepository();
  late final CacheService _cacheService;

  // Observable states
  final RxBool isInitialized = false.obs;
  final RxBool isCheckingAuth = true.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxString authStatus =
      'checking'.obs; // 'checking', 'authenticated', 'unauthenticated'

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeService();
  }

  /// Initialize the authentication service
  Future<void> _initializeService() async {
    try {
      print('🔐 AuthFlowService: Initializing...');

      // Initialize cache service
      _cacheService = await CacheService.getInstance();

      // Check authentication status
      await _checkAuthenticationStatus();

      isInitialized.value = true;
      print('🔐 AuthFlowService: Initialized successfully');
    } catch (e) {
      print('❌ AuthFlowService: Initialization failed - $e');
      authStatus.value = 'unauthenticated';
      isInitialized.value = true;
    }
  }

  /// Check current authentication status
  Future<void> _checkAuthenticationStatus() async {
    try {
      print('🔍 AuthFlowService: Checking authentication status...');
      isCheckingAuth.value = true;

      // Check Firebase Auth state
      final firebaseUser = _firebaseAuth.currentUser;
      print('🔥 Firebase user: ${firebaseUser?.email}');

      if (firebaseUser == null) {
        print('❌ No Firebase user found');
        await _handleUnauthenticated();
        return;
      }

      // Check if email is verified
      if (!firebaseUser.emailVerified) {
        print('❌ Email not verified');
        await _handleUnauthenticated();
        return;
      }

      // Check cache for user data
      final cachedUser = await _cacheService.getUserData();
      final isLoggedIn = await _cacheService.isLoggedIn();
      final isCacheValid = await _cacheService.isCacheValid();

      print('💾 Cache status - Logged in: $isLoggedIn, Valid: $isCacheValid');
      print('👤 Cached user: ${cachedUser?.email} (${cachedUser?.role})');

      if (!isLoggedIn || cachedUser == null || !isCacheValid) {
        print('❌ Invalid cache, refreshing user data...');
        await _refreshUserData(firebaseUser.uid);
        return;
      }

      // Validate cached user matches Firebase user
      if (cachedUser.uid != firebaseUser.uid) {
        print('❌ User ID mismatch, refreshing...');
        await _refreshUserData(firebaseUser.uid);
        return;
      }

      // Success - user is authenticated
      currentUser.value = cachedUser;
      authStatus.value = 'authenticated';
      print(
        '✅ AuthFlowService: User authenticated - ${cachedUser.email} (${cachedUser.role})',
      );
    } catch (e) {
      print('❌ AuthFlowService: Authentication check failed - $e');
      await _handleUnauthenticated();
    } finally {
      isCheckingAuth.value = false;
    }
  }

  /// Refresh user data from server
  Future<void> _refreshUserData(String uid) async {
    try {
      print('🔄 AuthFlowService: Refreshing user data for UID: $uid');

      // Get fresh user data from Firestore
      final userDoc = await _authRepository.getUserDocument(uid);
      if (userDoc == null) {
        print('❌ User document not found in Firestore');
        await _handleUnauthenticated();
        return;
      }

      final user = UserModel.fromFirestore(userDoc);

      // Validate user role
      if (user.role != 'parent' && user.role != 'driver') {
        print('❌ Invalid user role: ${user.role}');
        await _handleUnauthenticated();
        return;
      }

      // Save refreshed data to cache
      await _cacheService.saveUserData(user);

      currentUser.value = user;
      authStatus.value = 'authenticated';
      print(
        '✅ AuthFlowService: User data refreshed - ${user.email} (${user.role})',
      );
    } catch (e) {
      print('❌ AuthFlowService: Failed to refresh user data - $e');
      await _handleUnauthenticated();
    }
  }

  /// Handle unauthenticated state
  Future<void> _handleUnauthenticated() async {
    print('🚪 AuthFlowService: Handling unauthenticated state');

    // Clear cache
    await _cacheService.clearCache();

    // Sign out from Firebase
    await _firebaseAuth.signOut();

    // Update state
    currentUser.value = null;
    authStatus.value = 'unauthenticated';
  }

  /// Navigate to appropriate screen based on authentication status
  Future<void> navigateToInitialScreen() async {
    try {
      print('🧭 AuthFlowService: Navigating to initial screen...');

      if (authStatus.value == 'authenticated' && currentUser.value != null) {
        final user = currentUser.value!;
        print('👤 Navigating for user: ${user.email} (${user.role})');

        if (user.role == 'parent') {
          print('🏠 Navigating to parent main view');
          Get.offAllNamed(AppRoutes.parentMainView);
        } else if (user.role == 'driver') {
          print('🚗 Navigating to driver main view');
          Get.offAllNamed(AppRoutes.driverMainView);
        } else {
          print('❌ Unknown role, navigating to role selection');
          Get.offAllNamed(AppRoutes.roleSelection);
        }
      } else {
        print('🚪 User not authenticated, navigating to role selection');
        Get.offAllNamed(AppRoutes.roleSelection);
      }
    } catch (e) {
      print('❌ AuthFlowService: Navigation failed - $e');
      Get.offAllNamed(AppRoutes.roleSelection);
    }
  }

  /// Force refresh authentication status
  Future<void> refreshAuthStatus() async {
    await _checkAuthenticationStatus();
  }

  /// Get current user
  UserModel? get user => currentUser.value;

  /// Check if user is authenticated
  bool get isAuthenticated =>
      authStatus.value == 'authenticated' && currentUser.value != null;

  /// Check if user is parent
  bool get isParent => isAuthenticated && currentUser.value?.role == 'parent';

  /// Check if user is driver
  bool get isDriver => isAuthenticated && currentUser.value?.role == 'driver';

  /// Logout user
  Future<void> logout() async {
    try {
      print('🚪 AuthFlowService: Logging out user...');
      await _handleUnauthenticated();
      Get.offAllNamed(AppRoutes.roleSelection);
    } catch (e) {
      print('❌ AuthFlowService: Logout failed - $e');
    }
  }

  /// Update user data in cache
  Future<void> updateUserData(UserModel user) async {
    try {
      await _cacheService.saveUserData(user);
      currentUser.value = user;
      print('✅ AuthFlowService: User data updated');
    } catch (e) {
      print('❌ AuthFlowService: Failed to update user data - $e');
    }
  }
}
