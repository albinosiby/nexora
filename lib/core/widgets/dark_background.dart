import 'package:flutter/material.dart';
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
