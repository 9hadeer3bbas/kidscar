import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../custom_widgets/custom_text_field.dart';
import '../../custom_widgets/custom_button.dart';
import '../../../core/managers/color_manager.dart';
import '../../../core/managers/assets_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'reset_password_controller.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Blue wave background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: ColorManager.signUpGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: CustomPaint(
                painter: _WavePainter(),
                child: SizedBox(height: 220.h),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 24.h),
                    // Back arrow
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 28.sp,
                        ),
                        onPressed: () => Get.back(),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Enter New Password',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your new password must be different from previously used password.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    Obx(
                      () => CustomTextField(
                        hintText: 'Password',
                        controller: controller.passwordController,
                        obscureText: controller.obscurePassword.value,
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: SvgPicture.asset(
                            AssetsManager.lockIcon,
                            width: 20.w,
                            height: 20.w,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: controller.toggleObscurePassword,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(
                      () => CustomTextField(
                        hintText: 'Confirm Password',
                        controller: controller.confirmPasswordController,
                        obscureText: controller.obscureConfirmPassword.value,
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: SvgPicture.asset(
                            AssetsManager.lockIcon,
                            width: 20.w,
                            height: 20.w,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscureConfirmPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: controller.toggleObscureConfirmPassword,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    CustomButton(
                      text: 'Save',
                      onPressed: controller.saveNewPassword,
                      height: 44.h,
                      color: const Color(0xFF64B5F6),
                      textStyle: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the blue wave background
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.55,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.85,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
