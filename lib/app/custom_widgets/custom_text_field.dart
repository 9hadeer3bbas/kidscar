import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kidscar/core/managers/color_manager.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;
  final FocusNode? focusNode;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.errorText,
    this.focusNode,
    this.onSuffixTap,
    this.onFieldSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: Offset(0, 0),
                  blurRadius: 12,
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              validator: validator,
              focusNode: focusNode,
              onFieldSubmitted: onFieldSubmitted,
              onChanged: onChanged,

              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp),
              cursorColor: ColorManager.primaryColor,
              decoration: InputDecoration(
                filled: true,
                fillColor: ColorManager.white,
                hintText: hintText,
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
                prefixIcon: prefixIcon,
                prefixIconConstraints: BoxConstraints(
                  minWidth: 40.w,
                  minHeight: 40.h,
                ),
                suffixIcon: suffixIcon != null
                    ? GestureDetector(onTap: onSuffixTap, child: suffixIcon)
                    : null,
                suffixIconConstraints: BoxConstraints(minWidth: 40.w),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),

                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ColorManager.divider),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ColorManager.primaryColor),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: ColorManager.primaryColor),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                errorText: errorText,
                errorStyle: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
