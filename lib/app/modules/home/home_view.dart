import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../custom_widgets/custom_text_field.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/custom_badge.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 32.h),
                // Badge at the top right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomBadge(
                      text: 'English',
                      icon: Icons.language,
                      onTap: () {},
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                // Logo
                Container(
                  height: 90.w,
                  width: 90.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.directions_car,
                      size: 56.sp,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  'Welcome to KidsCar',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                CustomTextField(hintText: 'Full Name'),
                CustomTextField(hintText: 'email or phone number'),
                CustomTextField(
                  hintText: 'Password',
                  obscureText: true,
                  suffixIcon: Icon(Icons.visibility_off),
                ),
                CustomTextField(
                  hintText: 'Confirm Password',
                  obscureText: true,
                  suffixIcon: Icon(Icons.visibility_off),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Checkbox(value: false, onChanged: (v) {}),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text:
                              'I agree to the privacy and security policies ? ',
                          style: TextStyle(fontSize: 12.sp),
                          children: [
                            TextSpan(
                              text: 'See',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                CustomButton(
                  text: 'Sign Up',
                  onPressed: () {},
                  height: 48.h,
                  textStyle: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text('or'.tr, style: TextStyle(fontSize: 14.sp)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have Account ? ',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
