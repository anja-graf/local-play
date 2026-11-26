import 'package:flutter/material.dart';
import 'playing_card.dart';

class PrivateInfo extends StatelessWidget {
  final String text;
  final String? assetPath;

  const PrivateInfo({super.key, required this.text, this.assetPath});

  @override
  Widget build(BuildContext context) {
    final asset = assetPath;
    if (text.isEmpty && (asset == null || asset.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (asset != null && asset.isNotEmpty) ...[
              Center(child: PlayingCard(
                assetPath: asset, label: 'Your private card',
                width: 140, height: 200,
              )),
              if (text.isNotEmpty) const SizedBox(height: 12),
            ],
            if (text.isNotEmpty)
              Text(text, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
