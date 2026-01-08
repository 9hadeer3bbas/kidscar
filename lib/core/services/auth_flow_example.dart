import 'package:kidscar/data/repos/driver_auth_repo.dart';
import 'package:kidscar/app/custom_widgets/custom_toast.dart';
import 'package:get/get.dart';

/// Example of the complete authentication flow
class AuthFlowExample {
  final DriverAuthRepository _authRepo = DriverAuthRepository();

  /// Example: Complete driver registration flow
  Future<bool> registerDriverExample({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String city,
    // File parameters would be added here
  }) async {
    try {
      // This would be called from the signup controller
      // The registration process will:
      // 1. Create user account
      // 2. Upload files to storage
      // 3. Send verification email
      // 4. Show success toast
      // 5. Navigate to sign-in page

      print('Driver registration completed');
      print('Verification email sent to: $email');
      print('User should now go to sign-in page');

      return true;
    } catch (e) {
      print('Registration failed: $e');
      return false;
    }
  }

  /// Example: Sign-in flow with email verification check
  Future<bool> signInExample(String email, String password) async {
    try {
      // This will be called from the sign-in controller
      // The login process will:
      // 1. Check email verification (built into loginDriver method)
      // 2. Cache user data if login successful
      // 3. Navigate to appropriate home screen

      await _authRepo.loginDriver(email: email, password: password);

      // Get cached user data
      final user = await _authRepo.getCachedUserData();
      if (user != null) {
        print('Login successful for: ${user.fullName}');
        print('User role: ${user.role}');
        print('User data cached successfully');
        return true;
      }

      return false;
    } catch (e) {
      print('Login failed: $e');

      // Show error toast
      CustomToasts(message: e.toString(), type: CustomToastType.error).show();

      return false;
    }
  }

  /// Example: Check if user is already logged in
  Future<bool> checkExistingLogin() async {
    try {
      final isLoggedIn = await _authRepo.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authRepo.getCachedUserData();
        if (user != null) {
          print('User already logged in: ${user.fullName}');
          print('Navigating to home screen...');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// Example: Logout and clear cache
  Future<bool> logoutExample() async {
    try {
      await _authRepo.logout();
      print('User logged out and cache cleared');
      return true;
    } catch (e) {
      print('Logout failed: $e');
      return false;
    }
  }

  /// Example: Get cached user information
  Future<void> getUserInfoExample() async {
    try {
      final user = await _authRepo.getCachedUserData();
      if (user != null) {
        print('Cached User Info:');
        print('- Name: ${user.fullName}');
        print('- Email: ${user.email}');
        print('- Phone: ${user.phoneNumber}');
        print('- Role: ${user.role}');
        print('- Created: ${user.createdAt}');
        print('- Updated: ${user.updatedAt}');
      } else {
        print('No user data in cache');
      }
    } catch (e) {
      print('Error getting user info: $e');
    }
  }
}
