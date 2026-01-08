import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/managers/color_manager.dart';
import 'driver_notifications_controller.dart';

class DriverNotificationsView extends GetView<DriverNotificationsController> {
  const DriverNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.scaffoldBackground,
      body: Stack(
        children: [
          const _NotificationsBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
                  child: _NotificationsHeader(
                    title: 'notifications'.tr,
                    subtitle: 'your_notifications'.tr,
                    onBackTap: () => Get.back(),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const _LoadingState();
                    }

                    if (controller.notifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async => controller.refreshNotifications(),
                      color: ColorManager.primaryColor,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                          SliverToBoxAdapter(child: _buildHeader()),
                          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                          SliverToBoxAdapter(child: _buildFilterBar()),
                          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final notification =
                                    controller.filteredNotifications[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    left: 20.w,
                                    right: 20.w,
                                    bottom: 16.h,
                                  ),
                                  child: _NotificationTile(
                                    notification: notification,
                                    controller: controller,
                                  ),
                                );
                              },
                              childCount:
                                  controller.filteredNotifications.length,
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final unreadCount = controller.unreadCount.value;
      final totalCount = controller.notifications.length;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                gradient: LinearGradient(
                  colors: [
                    ColorManager.primaryColor,
                    ColorManager.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'your_notifications'.tr,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    unreadCount > 0
                        ? 'unread_notifications_count'.tr.replaceAll(
                            '{count}',
                            unreadCount.toString(),
                          )
                        : 'all_caught_up'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 8.h,
                    children: [
                      _MetricChip(
                        label: 'notifications'.tr,
                        value: totalCount,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                      ),
                      _MetricChip(
                        label: 'unread'.tr,
                        value: unreadCount,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (unreadCount > 0)
            GestureDetector(
              onTap: () => _showMarkAllAsReadDialog(Get.context!),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: ColorManager.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: ColorManager.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.done_all,
                      size: 18.sp,
                      color: ColorManager.primaryColor,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'mark_all_read'.tr,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildFilterBar() {
    return Obx(() {
      final selectedFilter = controller.selectedFilter.value;
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: NotificationFilter.values.map((filter) {
            final isSelected = filter == selectedFilter;
            return Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: ChoiceChip(
                label: Text(
                  _filterLabel(filter),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? ColorManager.white
                        : ColorManager.textSecondary,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => controller.changeFilter(filter),
                backgroundColor: Colors.white.withValues(alpha: 0.7),
                selectedColor: ColorManager.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                elevation: isSelected ? 4 : 0,
                pressElevation: 0,
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorManager.primaryColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 60.sp,
                color: ColorManager.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'no_notifications'.tr,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: ColorManager.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'no_notifications_desc'.tr,
              style: TextStyle(
                fontSize: 15.sp,
                color: ColorManager.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkAllAsReadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: ColorManager.primaryColor),
            SizedBox(width: 8.w),
            Text('mark_all_read'.tr),
          ],
        ),
        content: Text('mark_all_read_confirmation'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.markAllAsRead();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  String _filterLabel(NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.all:
        return 'all'.tr;
      case NotificationFilter.unread:
        return 'unread'.tr;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.controller,
  });

  final Map<String, dynamic> notification;
  final DriverNotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] == true;
    final type = notification['type'] as String?;
    final title = notification['title'] as String? ?? 'notification'.tr;
    final body = notification['body'] as String? ?? '';
    final createdAt = notification['createdAt'] as String?;

    final icon = controller.getNotificationIcon(type);
    final color = controller.getNotificationColor(type);
    final formattedDate = controller.formatDate(createdAt);

    return Dismissible(
      key: Key(notification['id'] ?? DateTime.now().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: ColorManager.error,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              'delete'.tr,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        controller.deleteNotification(notification['id']);
      },
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            controller.markAsRead(notification['id']);
          }
          _handleNotificationTap(notification);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: isRead
                      ? Colors.white.withValues(alpha: 0.92)
                      : ColorManager.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: isRead
                        ? ColorManager.divider.withValues(alpha: 0.4)
                        : ColorManager.primaryColor.withValues(alpha: 0.5),
                    width: isRead ? 1 : 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.3),
                            color.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(icon, style: TextStyle(fontSize: 26.sp)),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: isRead
                                            ? FontWeight.w600
                                            : FontWeight.w700,
                                        color: ColorManager.textPrimary,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      body,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: ColorManager.textSecondary,
                                        height: 1.45,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  margin: EdgeInsets.only(left: 10.w),
                                  width: 10.w,
                                  height: 10.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ColorManager.primaryColor,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Text(
                                  type?.replaceAll('_', ' ') ??
                                      'notification'.tr,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: color.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.access_time_rounded,
                                size: 14.sp,
                                color: ColorManager.textSecondary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: ColorManager.textSecondary.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] as String?;

    switch (type) {
      case 'new_subscription':
      case 'trip_completed':
      case 'trip_reminder':
        // Navigate to driver main view or trip details
        Get.back();
        break;
      case 'emergency':
        // Show emergency details
        Get.back();
        break;
      default:
        // Just close notification view
        break;
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: ColorManager.primaryColor),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.backgroundColor,
  });

  final String label;
  final int value;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsBackground extends StatelessWidget {
  const _NotificationsBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorManager.primaryColor.withValues(alpha: 0.15),
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -30,
              child: _BlurCircle(
                diameter: 180.w,
                color: ColorManager.primaryColor.withValues(alpha: 0.25),
              ),
            ),
            Positioned(
              top: 120,
              left: -60,
              child: _BlurCircle(
                diameter: 220.w,
                color: ColorManager.secondaryColor.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.title,
    required this.subtitle,
    required this.onBackTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBackTap,
          child: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(width: diameter, height: diameter, color: color),
      ),
    );
  }
}
