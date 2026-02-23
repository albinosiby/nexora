import 'package:flutter/material.dart';
import '../theme/nexora_theme.dart';

/// Solid container widget - previously used glassmorphism, now uses solid styling
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const GlassContainer({
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: NexoraColors.cardBackground,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: NexoraColors.cardBorder),
        ),
        child: child,
      ),
    );
  }
}
