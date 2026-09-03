import 'package:flutter/material.dart';
import '../theme.dart';

class PinDots extends StatelessWidget {
  final int length;
  final int filled;
  final bool error;

  const PinDots({super.key, required this.length, required this.filled, this.error = false});

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.terracotta : AppColors.gold;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: color, width: 1.6),
          ),
        );
      }),
    );
  }
}
