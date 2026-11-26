import 'package:flutter/material.dart';
import '../../../core/game/game_model.dart';

class PlayerList extends StatelessWidget {
  final List<PlayerView> players;
  final String you;

  const PlayerList({super.key, required this.players, required this.you});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6, runSpacing: 6,
    children: [
      for (final p in players)
        Chip(
          avatar: Icon(p.bot ? Icons.smart_toy : Icons.person, size: 18),
          label: Text(
            '${p.turn ? '▶ ' : ''}${p.name}'
            '${p.id == you ? ' (you)' : ''}'
            '${p.count != null ? ' · ${p.count} cards' : ''}'
            '${p.note.isNotEmpty ? ' · ${p.note}' : ''}',
          ),
        ),
    ],
  );
}
