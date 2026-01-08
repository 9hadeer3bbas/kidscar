import 'package:kidscar/app/modules/driver/driver_home/driver_home_view.dart';
import 'package:kidscar/app/modules/driver/profile/driver_profile_view.dart';
import 'package:kidscar/app/modules/driver/profile/driver_profile_controller.dart';
import 'package:kidscar/app/modules/driver/profile/driver_view_profile_view.dart';
import 'package:kidscar/app/modules/driver/profile/driver_edit_profile_view.dart';
import 'package:kidscar/app/modules/driver/profile/driver_edit_profile_controller.dart';
import 'package:kidscar/app/modules/driver/profile/driver_vehicle_documents_view.dart';
import 'package:kidscar/app/modules/driver/profile/driver_vehicle_documents_controller.dart';
import 'package:kidscar/app/modules/driver/sign_up_driver/driver_signup_view.dart';
import 'package:kidscar/app/modules/parent/driver_selection/driver_selection_controller.dart';
import 'package:kidscar/app/modules/parent/driver_selection/driver_selection_view.dart';
import 'package:kidscar/app/modules/parent/my_kids/my_kids_controller.dart';
import 'package:kidscar/app/modules/parent/my_kids/my_kids_view.dart';
import 'package:kidscar/app/modules/parent/parent_home/parent_home_view.dart';
import 'package:kidscar/app/modules/splash/splash_view.dart';
import 'package:kidscar/app/modules/driver/driver_main/driver_main_view.dart';
import 'package:kidscar/app/modules/driver/driver_main/driver_main_controller.dart';
import 'package:kidscar/app/modules/driver/trips/driver_trips_controller.dart';
import 'package:kidscar/app/modules/driver/trips/driver_trips_view.dart';
import 'package:kidscar/app/modules/driver/trips/trip_detail_controller.dart';
import 'package:kidscar/app/modules/driver/trips/trip_detail_view.dart';
import 'package:kidscar/data/repos/location_repo.dart';
import 'package:kidscar/domain/repositories/location_repository.dart';
import 'package:kidscar/domain/usecases/location/get_route_path_usecase.dart';
import 'package:kidscar/domain/usecases/location/get_route_pois_usecase.dart';
import 'package:kidscar/app/modules/parent/parent_main/parent_main_controller.dart';
import 'package:kidscar/app/modules/parent/parent_main/parent_main_view.dart';
import 'package:kidscar/app/modules/parent/edit_profile/parent_edit_profile_controller.dart';
import 'package:kidscar/app/modules/parent/edit_profile/parent_edit_profile_view.dart';
import 'package:kidscar/app/modules/parent/notifications/parent_notifications_controller.dart';
import 'package:kidscar/app/modules/parent/notifications/parent_notifications_view.dart';
import 'package:kidscar/app/modules/parent/language/parent_language_view.dart';
import 'package:kidscar/app/modules/parent/parent_activity/trip_detail/parent_trip_detail_controller.dart';
import 'package:kidscar/app/modules/parent/parent_activity/trip_detail/parent_trip_detail_view.dart';
import 'package:kidscar/app/modules/parent/profile/parent_view_profile_view.dart';
import 'package:kidscar/app/modules/driver/notifications/driver_notifications_controller.dart';
import 'package:kidscar/app/modules/driver/notifications/driver_notifications_view.dart';
import 'package:kidscar/app/modules/privacy_security/privacy_security_view.dart';
import 'package:kidscar/app/modules/driver/file_attach_driver/file_attach_driver_controller.dart';
import 'package:kidscar/app/modules/driver/file_attach_driver/file_attach_driver_view.dart';
import 'package:kidscar/app/modules/driver/sign_up_driver/driver_signup_controller.dart';
import 'package:kidscar/app/modules/driver/selfie_verification/selfie_verification_controller.dart';
import 'package:kidscar/app/modules/driver/selfie_verification/selfie_verification_view.dart';
import 'package:get/get.dart';

import 'package:kidscar/app/modules/change_password/change_password_controller.dart';
import 'package:kidscar/app/modules/change_password/change_password_view.dart';
import 'package:kidscar/app/modules/signin/signin_controller.dart';
import 'package:kidscar/app/modules/parent/sign_up_parent/signup_parent_controller.dart';
import 'package:kidscar/app/modules/parent/sign_up_parent/signup_parent_view.dart';
import 'package:kidscar/app/modules/role_selection/role_selection_view.dart';

import 'package:kidscar/app/modules/signin/signin_view.dart';

import 'package:kidscar/app/modules/reset_password/reset_password_view.dart';
import 'package:kidscar/app/modules/reset_password/reset_password_controller.dart';

import 'package:kidscar/app/modules/map/map_view.dart';
import 'package:kidscar/app/modules/map/map_controller.dart';
import 'package:kidscar/app/modules/map/map_test_view.dart';

import 'package:kidscar/app/modules/parent/subscription/subscription_view.dart';
import 'package:kidscar/app/modules/parent/subscription/subscription_controller.dart';
import 'package:kidscar/app/modules/parent/instant_ride/instant_ride_view.dart';
import 'package:kidscar/app/modules/parent/instant_ride/instant_ride_controller.dart';
import 'package:kidscar/app/modules/parent/instant_ride/instant_ride_driver_selection_view.dart';
import 'package:kidscar/app/modules/parent/instant_ride/instant_ride_driver_selection_controller.dart';
import 'package:kidscar/app/modules/parent/my_kids/add_edit_kid_view.dart';
import 'package:kidscar/core/routes/get_routes.dart';
import 'package:kidscar/data/models/trip_model.dart';

class AppPages {
  static final pages = [
    // Splash Screen - First page
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),

    GetPage(
      name: AppRoutes.roleSelection,
      page: () => const RoleSelectionView(),
    ),
    GetPage(
      name: AppRoutes.signUpParent,
      page: () => SignupParentView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SignupParentController>(() => SignupParentController());
      }),
    ),

    GetPage(
      name: AppRoutes.signIn,
      page: () => SigninView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SignInController>(() => SignInController());
      }),
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => ResetPasswordView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ResetPasswordController>(() => ResetPasswordController());
      }),
    ),
    GetPage(
      name: AppRoutes.map,
      page: () => MapView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MapController>(() => MapController());
      }),
    ),
    GetPage(
      name: AppRoutes.mapTest,
      page: () => const MapTestView(),
    ),
    GetPage(
      name: AppRoutes.parentHome,
      page: () => ParentHomeView(),
      // Add binding if needed
    ),
    GetPage(
      name: AppRoutes.driverHome,
      page: () => DriverHomeView(),
      // Add binding if needed
    ),
    GetPage(
      name: AppRoutes.driverTrips,
      page: () => const DriverTripsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DriverTripsController>(() => DriverTripsController());
      }),
    ),
    GetPage(
      name: AppRoutes.driverTripDetail,
      page: () => const TripDetailView(),
      binding: BindingsBuilder(() {
        // Ensure LocationRepository is available
        if (!Get.isRegistered<LocationRepository>()) {
          Get.put<LocationRepositoryImpl>(LocationRepositoryImpl());
          Get.lazyPut<LocationRepository>(() => Get.find<LocationRepositoryImpl>());
        }
        
        // Ensure GetRoutePathUseCase is available (with fenix to recreate if disposed)
        if (!Get.isRegistered<GetRoutePathUseCase>()) {
          Get.lazyPut<GetRoutePathUseCase>(
            () => GetRoutePathUseCase(Get.find<LocationRepository>()),
            fenix: true, // Recreate if disposed
          );
        }
        
        // Ensure GetRoutePoisUseCase is available (with fenix to recreate if disposed)
        if (!Get.isRegistered<GetRoutePoisUseCase>()) {
          Get.lazyPut<GetRoutePoisUseCase>(
            () => GetRoutePoisUseCase(Get.find<LocationRepository>()),
            fenix: true, // Recreate if disposed
          );
        }
        
        final trip = Get.arguments as TripModel;
        Get.lazyPut<TripDetailController>(() => TripDetailController(trip));
      }),
    ),
    GetPage(
      name: AppRoutes.driverAccount,
      page: () => const DriverProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DriverProfileController>(() => DriverProfileController());
      }),
    ),
    GetPage(
      name: AppRoutes.driverNotifications,
      page: () => const DriverNotificationsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DriverNotificationsController>(
          () => DriverNotificationsController(),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.driverEditProfile,
      page: () => const DriverEditProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DriverEditProfileController>(
          () => DriverEditProfileController(),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.driverViewProfile,
      page: () => const DriverViewProfileView(),
      binding: BindingsBuilder(() {
        // Reuse the profile controller if it exists, otherwise create it
        if (!Get.isRegistered<DriverProfileController>()) {
          Get.lazyPut<DriverProfileController>(() => DriverProfileController());
        }
      }),
    ),
    GetPage(
      name: AppRoutes.driverVehicleDocuments,
      page: () => const DriverVehicleDocumentsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DriverVehicleDocumentsController>(
          () => DriverVehicleDocumentsController(),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.driverLanguage,
      page: () => const DriverLanguageView(),
    ),
    GetPage(
      name: AppRoutes.signUpDriver,
      page: () => const DriverSignUpView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DriverSignUpController>(() => DriverSignUpController());
      }),
    ),
    GetPage(
      name: AppRoutes.attachFileDriver,
      page: () => const FileAttachDriverView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<FileAttachDriverController>(
          () => FileAttachDriverController(),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.driverMainView,
      page: () => const DriverMainView(),
      binding: BindingsBuilder(() {
        // Ensure LocationRepository is available
        if (!Get.isRegistered<LocationRepository>()) {
          Get.put<LocationRepositoryImpl>(LocationRepositoryImpl());
          Get.lazyPut<LocationRepository>(() => Get.find<LocationRepositoryImpl>());
        }
        
        // Ensure GetRoutePathUseCase is available (permanent for driver main)
        if (!Get.isRegistered<GetRoutePathUseCase>()) {
          Get.lazyPut<GetRoutePathUseCase>(
            () => GetRoutePathUseCase(Get.find<LocationRepository>()),
            fenix: true, // Recreate if disposed
          );
        }
        
        // Ensure GetRoutePoisUseCase is available (permanent for driver main)
        if (!Get.isRegistered<GetRoutePoisUseCase>()) {
          Get.lazyPut<GetRoutePoisUseCase>(
            () => GetRoutePoisUseCase(Get.find<LocationRepository>()),
            fenix: true, // Recreate if disposed
          );
        }
        
        Get.lazyPut<DriverMainController>(() => DriverMainController());
      }),
    ),
    GetPage(
      name: AppRoutes.parentMainView,
      page: () => const ParentMainView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ParentMainController>(() => ParentMainController());
      }),
    ),
    GetPage(
      name: AppRoutes.parentEditProfile,
      page: () => const ParentEditProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ParentEditProfileController>(
          () => ParentEditProfileController(),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.parentNotifications,
      page: () => const ParentNotificationsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ParentNotificationsController>(
          () => ParentNotificationsController(),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.parentLanguage,
      page: () => ParentLanguageView(),
    ),
    GetPage(
      name: AppRoutes.parentTripDetail,
      page: () => const ParentTripDetailView(),
      binding: BindingsBuilder(() {
        // Ensure LocationRepository is available
        if (!Get.isRegistered<LocationRepository>()) {
          Get.put<LocationRepositoryImpl>(LocationRepositoryImpl());
          Get.lazyPut<LocationRepository>(() => Get.find<LocationRepositoryImpl>());
        }
        
        // Ensure GetRoutePathUseCase is available (with fenix to recreate if disposed)
        if (!Get.isRegistered<GetRoutePathUseCase>()) {
          Get.lazyPut<GetRoutePathUseCase>(
            () => GetRoutePathUseCase(Get.find<LocationRepository>()),
            fenix: true, // Recreate if disposed
          );
        }
        
        final trip = Get.arguments as TripModel;
        Get.put<ParentTripDetailController>(
          ParentTripDetailController(trip),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.parentViewProfile,
      page: () => const ParentViewProfileView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ParentMainController>()) {
          Get.lazyPut<ParentMainController>(() => ParentMainController());
        }
      }),
    ),
    GetPage(
      name: AppRoutes.privacySecurity,
      page: () => const PrivacyAndSecurityView(),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ChangePasswordController>(
          () => ChangePasswordController(),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.subscription,
      page: () => const SubscriptionView(),
      binding: BindingsBuilder(() {
        // Ensure LocationRepository is available
        if (!Get.isRegistered<LocationRepository>()) {
          Get.put<LocationRepositoryImpl>(LocationRepositoryImpl());
          Get.lazyPut<LocationRepository>(() => Get.find<LocationRepositoryImpl>());
        }
        
        // Ensure GetRoutePathUseCase is available (with fenix to recreate if disposed)
        if (!Get.isRegistered<GetRoutePathUseCase>()) {
          Get.lazyPut<GetRoutePathUseCase>(
            () => GetRoutePathUseCase(Get.find<LocationRepository>()),
            fenix: true, // Recreate if disposed
          );
        }
        
        Get.lazyPut<SubscriptionController>(() => SubscriptionController());
      }),
    ),
    GetPage(
      name: AppRoutes.driverSelection,
      page: () => const DriverSelectionView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DriverSelectionController>(
          () => DriverSelectionController(),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.instantRide,
      page: () => const InstantRideView(),
      binding: BindingsBuilder(() {
        // Ensure LocationRepository is available
        if (!Get.isRegistered<LocationRepository>()) {
          Get.put<LocationRepositoryImpl>(LocationRepositoryImpl());
          Get.lazyPut<LocationRepository>(() => Get.find<LocationRepositoryImpl>());
        }
        
        // Ensure GetRoutePathUseCase is available (with fenix to recreate if disposed)
        if (!Get.isRegistered<GetRoutePathUseCase>()) {
          Get.lazyPut<GetRoutePathUseCase>(
            () => GetRoutePathUseCase(Get.find<LocationRepository>()),
            fenix: true, // Recreate if disposed
          );
        }
        
        Get.lazyPut<InstantRideController>(() => InstantRideController());
      }),
    ),
    GetPage(
      name: AppRoutes.instantRideDriverSelection,
      page: () => const InstantRideDriverSelectionView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<InstantRideDriverSelectionController>(
          () => InstantRideDriverSelectionController(),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.myKids,
      page: () => const MyKidsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MyKidsController>(() => MyKidsController());
      }),
    ),
    GetPage(
      name: AppRoutes.addEditKid,
      page: () => AddEditKidView(kid: Get.arguments),
      binding: BindingsBuilder(() {
        Get.lazyPut<MyKidsController>(() => MyKidsController());
      }),
    ),
    GetPage(
      name: AppRoutes.driverSelfieVerification,
      page: () => const SelfieVerificationView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SelfieVerificationController>(
          () => SelfieVerificationController(),
        );
      }),
    ),
  ];
}
