import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PlayingCard extends StatelessWidget {
  final String assetPath;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const PlayingCard({
    super.key,
    required this.assetPath,
    required this.label,
    this.selected = false,
    this.onTap,
    this.width = 72,
    this.height = 102,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SvgPicture.asset(
        assetPath, width: width, height: height,
        fit: BoxFit.contain, semanticsLabel: label,
      ),
    ),
  );
}
