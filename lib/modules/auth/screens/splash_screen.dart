import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/dark_background.dart';
import 'auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Navigate after delay
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Get.off(() => const AuthWrapper());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF060606), // Match native splash_bg
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 120.r,
                        height: 120.r,
                        decoration: BoxDecoration(
                          gradient: NexoraGradients.primaryButton,
                          shape: BoxShape.circle,
                          boxShadow: [NexoraShadows.purpleGlow],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo/image.png',
                            width: 120.r,
                            height: 120.r,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // App name
                      Text(
                        'Koottu',
                        style: NexoraTextStyles.headline2.copyWith(
                          letterSpacing: 6.w,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Tagline
                      Text(
                        'where campus hearts collide',
                        style: NexoraTextStyles.bodyMedium,
                      ),
                      SizedBox(height: 40.h),

                      // Simple loading indicator
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
