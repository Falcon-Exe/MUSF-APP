// lib/features/home/presentation/widgets/flip_dashboard_card.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlipDashboardCard extends StatelessWidget {
  final bool isFlipped;
  final Widget front;
  final Widget back;

  const FlipDashboardCard({
    super.key,
    required this.isFlipped,
    required this.front,
    required this.back,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isFlipped ? math.pi : 0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final bool isBackVisible = value > math.pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(value),
          alignment: Alignment.center,
          child: isBackVisible
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: back,
                )
              : front,
        );
      },
    );
  }
}
