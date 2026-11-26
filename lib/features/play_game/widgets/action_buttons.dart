import 'package:flutter/material.dart';
import '../../../core/game/game_model.dart';

class ActionButtons extends StatelessWidget {
  final List<ActionView> actions;
  final bool hasSelection;
  final bool waiting;
  final ValueChanged<ActionView> onAction;

  const ActionButtons({
    super.key,
    required this.actions,
    required this.onAction,
    this.hasSelection = false,
    this.waiting = false,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty && waiting) {
      return const Text('Waiting for other players…');
    }
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final action in actions)
        FilledButton(
          onPressed: action.selection && !hasSelection
              ? null : () => onAction(action),
          child: Text(action.label),
        ),
    ]);
  }
}
