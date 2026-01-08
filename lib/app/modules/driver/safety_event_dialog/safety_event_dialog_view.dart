import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../core/services/safety_event_service.dart';
import '../../../../data/models/trip_model.dart';
import 'safety_event_dialog_controller.dart';

class SafetyEventDialog extends StatelessWidget {
  const SafetyEventDialog({super.key, required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SafetyEventDialogController());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorManager.primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: ColorManager.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.security,
                    color: ColorManager.primaryColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'simulate_safety_event'.tr,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: ColorManager.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'for_testing_purposes'.tr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: ColorManager.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20.sp,
                    color: ColorManager.textSecondary,
                  ),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            // Event options
            Obx(
              () => Column(
                children: [
                  _SafetyEventOption(
                    icon: Icons.volume_up,
                    title: 'loud_sound_detected'.tr,
                    subtitle: 'simulate_loud_sound'.tr,
                    color: Colors.orange,
                    onTap: controller.isProcessing.value
                        ? null
                        : () => controller.simulateSafetyEvent(
                            SafetyEventType.loudSound,
                            trip,
                          ),
                  ),
                  SizedBox(height: 12.h),
                  _SafetyEventOption(
                    icon: Icons.warning_amber_rounded,
                    title: 'off_road_detected'.tr,
                    subtitle: 'simulate_off_road'.tr,
                    color: Colors.red,
                    onTap: controller.isProcessing.value
                        ? null
                        : () => controller.simulateSafetyEvent(
                            SafetyEventType.offRoad,
                            trip,
                          ),
                  ),
                  SizedBox(height: 12.h),
                  _SafetyEventOption(
                    icon: Icons.error_outline,
                    title: 'unexpected_stop_detected'.tr,
                    subtitle: 'simulate_unexpected_stop'.tr,
                    color: Colors.deepOrange,
                    onTap: controller.isProcessing.value
                        ? null
                        : () => controller.simulateSafetyEvent(
                            SafetyEventType.unexpectedStop,
                            trip,
                          ),
                  ),
                ],
              ),
            ),
            if (controller.isProcessing.value) ...[
              SizedBox(height: 16.h),
              Center(
                child: CircularProgressIndicator(
                  color: ColorManager.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SafetyEventOption extends StatelessWidget {
  const _SafetyEventOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ColorManager.textSecondary,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
