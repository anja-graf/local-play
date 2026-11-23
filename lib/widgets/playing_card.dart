import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PlayingCard extends StatelessWidget {
  final String symbol;
  final Color color;
  final double rotation;

  const PlayingCard({
    super.key,
    required this.symbol,
    required this.color,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 100,
        height: 145,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.text, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 5,
              offset: const Offset(3, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          symbol,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
