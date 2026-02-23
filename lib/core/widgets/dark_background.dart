import 'package:flutter/material.dart';
import '../theme/nexora_theme.dart';

class DarkBackground extends StatelessWidget {
  final Widget child;

  const DarkBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: NexoraGradients.mainBackground),
      child: child,
    );
  }
}
