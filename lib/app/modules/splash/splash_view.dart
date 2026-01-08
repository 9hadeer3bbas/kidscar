import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/core/managers/assets_manager.dart';
import 'package:kidscar/core/services/auth_flow_service.dart';
import 'package:kidscar/core/routes/get_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _textAnimationController;
  late AnimationController _loadingAnimationController;
  late AnimationController _backgroundAnimationController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _loadingOpacityAnimation;
  late Animation<double> _loadingScaleAnimation;
  late Animation<double> _backgroundOpacityAnimation;
  late Animation<Offset> _backgroundSlideAnimation;

  // Loading state management
  String _loadingText = 'Initializing...';
  int _loadingDots = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAuthFlow();
    _startLoadingDotsAnimation();
  }

  void _initializeAnimations() {
    // Logo animations
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Text animations
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Loading animations
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _loadingOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _loadingScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Background animations
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _backgroundOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _backgroundSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _backgroundAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Start animations in sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    if (!mounted) return;

    // Start background animation
    _backgroundAnimationController.forward();

    // Wait a bit then start logo
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoAnimationController.forward();

    // Wait for logo to be halfway done then start text
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _textAnimationController.forward();

    // Wait for text to be halfway done then start loading
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _loadingAnimationController.forward();
  }

  void _startLoadingDotsAnimation() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _loadingDots = (_loadingDots + 1) % 4;
        });
        _startLoadingDotsAnimation();
      }
    });
  }

  Future<void> _initializeAuthFlow() async {
    try {
      // Wait for minimum splash duration
      await Future.delayed(const Duration(milliseconds: 2000));

      // Initialize AuthFlowService
      Get.put(AuthFlowService());

      // Update loading text
      if (mounted) {
        setState(() {
          _loadingText = 'Checking authentication...';
        });
      }

      // Wait for auth service to initialize
      final authService = AuthFlowService.instance;

      // Wait for initialization to complete
      while (!authService.isInitialized.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Wait for auth check to complete
      while (authService.isCheckingAuth.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Navigate based on auth status
      await authService.navigateToInitialScreen();
    } catch (e) {
      print('❌ SplashScreen: Error during initialization - $e');
      // Fallback navigation
      Get.offAllNamed(AppRoutes.roleSelection);
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _textAnimationController.dispose();
    _loadingAnimationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColorManager.primaryColor,
                ColorManager.primaryLight,
                ColorManager.white,
                ColorManager.backgroundColor,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SlideTransition(
            position: _backgroundSlideAnimation,
            child: FadeTransition(
              opacity: _backgroundOpacityAnimation,
              child: Stack(
                children: [
                  // Background decorative elements
                  _buildBackgroundElements(),

                  // Main content
                  _buildMainContent(),

                  // Loading indicator
                  _buildLoadingIndicator(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundElements() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Floating circles
          Positioned(
            top: 100.h,
            right: -50.w,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 150.h,
            left: -80.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            top: 300.h,
            left: 50.w,
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo section
            AnimatedBuilder(
              animation: _logoAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScaleAnimation.value,
                  child: Transform.rotate(
                    angle: _logoRotationAnimation.value,
                    child: FadeTransition(
                      opacity: _logoOpacityAnimation,
                      child: Container(
                        width: 180.w,
                        height: 180.w,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30.r,
                              offset: Offset(0, 15.h),
                              spreadRadius: 5.r,
                            ),
                            BoxShadow(
                              color: ColorManager.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 40.r,
                              offset: Offset(0, 20.h),
                              spreadRadius: 10.r,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          AssetsManager.logoImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 60.h),

            // App name and tagline
            AnimatedBuilder(
              animation: _textAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _textSlideAnimation.value),
                  child: FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Column(
                      children: [
                        // App name with modern typography
                        Text(
                          'KidsCar',
                          style: TextStyle(
                            fontSize: 42.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: 3.w,
                            decoration: TextDecoration.none,
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Modern tagline
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(25.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.w,
                            ),
                          ),
                          child: Text(
                            'Safe Rides for Your Kids',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.black.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5.w,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Positioned(
      bottom: 80.h,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _loadingAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _loadingScaleAnimation.value,
              child: FadeTransition(
                opacity: _loadingOpacityAnimation,
                child: Column(
                  children: [
                    // Modern loading indicator
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2.w,
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 30.w,
                          height: 30.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.w,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.9),
                            ),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Loading text with animated dots
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.w,
                        ),
                      ),
                      child: Text(
                        '$_loadingText${'.' * _loadingDots}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5.w,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
