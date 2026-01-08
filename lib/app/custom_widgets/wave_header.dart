import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kidscar/core/managers/assets_manager.dart';

import 'package:kidscar/app/custom_widgets/language_toggle_button.dart';
import 'package:kidscar/core/managers/color_manager.dart';

class WaveHeader extends StatelessWidget {
  final String? logoPath;
  final VoidCallback? onBackTap;
  final bool showBackButton;
  final bool showLanguageButton;
  final double height;
  final String? title;

  const WaveHeader({
    super.key,
    this.logoPath,
    this.onBackTap,
    this.showBackButton = true,
    this.showLanguageButton = false,
    this.height = 190,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: 165.0.h,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background SVG (should be below title)
          Positioned.fill(
            child: SvgPicture.asset(
              AssetsManager.curveBadge,
              fit: BoxFit.fitWidth,
              height: 190.0.h,
              alignment: Alignment.topCenter,
            ),
          ),
          // Title at the top center (above SVG)
          if (title != null)
            Positioned(
              top: 46.h,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  title!,
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Back Button (left for LTR, right for RTL)
          if (showBackButton)
            Positioned(
              top: 40.h,
              left: isRtl ? null : 16.w,
              right: isRtl ? 16.w : null,
              child: GestureDetector(
                onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
                child: Container(
                  height: 40.w,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22.w,
                  ),
                ),
              ),
            ),

          // Language Button (right for LTR, left for RTL)
          if (showLanguageButton)
            Positioned(
              top: 40.h,
              left: isRtl ? 16.w : null,
              right: isRtl ? null : 16.w,
              child: LanguageToggleButton(),
            ),

          // Centered Logo (optional)
          if (logoPath != null && logoPath!.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 116.w,
                width: 116.w,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 18.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Image.asset(logoPath!, fit: BoxFit.cover),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
