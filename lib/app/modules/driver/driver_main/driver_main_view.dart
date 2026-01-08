import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidscar/app/modules/driver/driver_home/driver_home_view.dart';
import 'package:kidscar/app/modules/driver/trips/driver_trips_view.dart';
import 'package:kidscar/app/modules/driver/profile/driver_profile_view.dart';
import 'package:kidscar/app/modules/driver/profile/driver_profile_controller.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/core/managers/assets_manager.dart';
import '../../../custom_widgets/modern_bottom_nav_bar.dart';
import 'driver_main_controller.dart';

class DriverMainView extends GetView<DriverMainController> {
  const DriverMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: Obx(() => _getPage(controller.selectedIndex.value)),
      extendBody: true,
      bottomNavigationBar: Obx(
        () => ModernBottomNavBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changeTabIndex,
          items: _buildNavigationItems(),
        ),
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const DriverHomeView();
      case 1:
        return const DriverTripsView();
      case 2:
        // Ensure DriverProfileController is initialized before showing the view
        if (!Get.isRegistered<DriverProfileController>()) {
          Get.put<DriverProfileController>(DriverProfileController());
        }
        return const DriverProfileView();
      default:
        return const DriverHomeView();
    }
  }

  List<NavItem> _buildNavigationItems() {
    return [
      NavItem(iconPath: AssetsManager.mapIcon, label: 'nav_home'.tr),
      NavItem(iconPath: AssetsManager.carIcon, label: 'nav_trips'.tr),
      NavItem(iconPath: AssetsManager.userIcon, label: 'nav_account'.tr),
    ];
  }
}
