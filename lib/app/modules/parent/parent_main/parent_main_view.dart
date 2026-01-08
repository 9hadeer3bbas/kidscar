import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidscar/app/modules/parent/parent_home/parent_home_view.dart';
import 'package:kidscar/app/modules/parent/parent_home/parent_home_controller.dart';
import 'package:kidscar/app/modules/parent/parent_activity/parent_activity_view.dart';
import 'package:kidscar/app/modules/parent/parent_activity/parent_activity_controller.dart';
import 'package:kidscar/app/modules/parent/parent_account/parent_account_view.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/core/managers/assets_manager.dart';
import '../../../custom_widgets/modern_bottom_nav_bar.dart';
import 'parent_main_controller.dart';

class ParentMainView extends GetView<ParentMainController> {
  const ParentMainView({super.key});

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
        return GetBuilder<ParentHomeController>(
          init: ParentHomeController(),
          builder: (controller) => const ParentHomeView(),
        );
      case 1:
        return GetBuilder<ParentActivityController>(
          init: ParentActivityController(),
          builder: (controller) => const ParentActivityView(),
        );
      case 2:
        return ParentAccountView();
      default:
        return GetBuilder<ParentHomeController>(
          init: ParentHomeController(),
          builder: (controller) => const ParentHomeView(),
        );
    }
  }

  List<NavItem> _buildNavigationItems() {
    return [
      NavItem(
        iconPath: AssetsManager.mapIcon,
        label: 'nav_home'.tr,
      ),
      NavItem(
        iconPath: AssetsManager.tripsIcon,
        label: 'nav_activity'.tr,
      ),
      NavItem(
        iconPath: AssetsManager.userIcon,
        label: 'nav_account'.tr,
      ),
    ];
  }
}
