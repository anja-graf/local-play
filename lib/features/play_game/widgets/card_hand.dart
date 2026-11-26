import 'package:flutter/material.dart';
import 'playing_card.dart';

class CardHand extends StatelessWidget {
  final List<String> cards;
  final Set<String> selected;
  final ValueChanged<String>? onToggleCard;
  final String emptyText;

  const CardHand({
    super.key,
    required this.cards,
    this.selected = const <String>{},
    this.onToggleCard,
    this.emptyText = 'No cards',
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return Text(emptyText);
    return Wrap(children: [
      for (final id in cards)
        PlayingCard(
          assetPath: 'assets/cards/standard/$id.svg',
          label: id.replaceAll('_', ' '),
          selected: onToggleCard != null && selected.contains(id),
          onTap: onToggleCard == null ? null : () => onToggleCard!(id),
        ),
    ]);
  }
}
