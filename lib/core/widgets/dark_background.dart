import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/nexora_theme.dart';

class DarkBackground extends StatelessWidget {
  final Widget child;

  const DarkBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: NexoraGradients.mainBackground),
      child: Stack(
        children: [
          // Top subtle glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    NexoraColors.primaryPurple.withOpacity(0.08),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),
          // Background Decor Circles
          Positioned(
            top: -150.h,
            right: -100.w,
            child: Container(
              width: 400.r,
              height: 400.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NexoraColors.primaryPurple.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100.h,
            left: -150.w,
            child: Container(
              width: 450.r,
              height: 450.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NexoraColors.primaryPurple.withOpacity(0.05),
              ),
            ),
          ),
          // Bottom subtle glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    NexoraColors.primaryPurple.withOpacity(0.12),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
