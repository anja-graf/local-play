import 'package:flutter/material.dart';

class ShuffleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ShuffleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.shuffle),
      label: const Text('Shuffle cards'),
    );
  }
}
