import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repos/driver_auth_repo.dart';

class DriverProfileController extends GetxController {
  final DriverAuthRepository _authRepository = DriverAuthRepository();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final isLoading = false.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  
  // Driver-specific fields
  final city = ''.obs;
  final driverPhotoUrl = Rxn<String>();
  final drivingLicenseUrl = Rxn<String>();
  final vehicleRegistrationUrl = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    loadDriverProfile();
  }

  Future<void> loadDriverProfile() async {
    try {
      isLoading.value = true;
      
      // Get user from cache first
      final cachedUser = await _authRepository.getCachedUserData();
      if (cachedUser != null) {
        currentUser.value = cachedUser;
      }

      // Get additional driver data from Firestore
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(currentFirebaseUser.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          
          // Update user model
          currentUser.value = UserModel.fromFirestore(doc);
          
          // Get driver-specific fields
          city.value = data['city'] ?? '';
          driverPhotoUrl.value = data['driverPhotoUrl'];
          drivingLicenseUrl.value = data['drivingLicenseUrl'];
          vehicleRegistrationUrl.value = data['vehicleRegistrationUrl'];
        }
      }
    } catch (e) {
      print('Error loading driver profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      isLoading.value = true;
      final user = await _authRepository.refreshUserData();
      currentUser.value = user;
      
      // Reload driver-specific fields
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(currentFirebaseUser.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          city.value = data['city'] ?? '';
          driverPhotoUrl.value = data['driverPhotoUrl'];
          drivingLicenseUrl.value = data['drivingLicenseUrl'];
          vehicleRegistrationUrl.value = data['vehicleRegistrationUrl'];
        }
      }
    } catch (e) {
      print('Error refreshing profile: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

