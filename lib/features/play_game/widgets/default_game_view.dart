import 'package:flutter/material.dart';
import '../../../core/game/game_model.dart';
import 'action_buttons.dart';
import 'card_hand.dart';
import 'player_list.dart';
import 'private_info.dart';

class DefaultGameView extends StatefulWidget {
  final GameViewState view;
  final bool Function(TableAction) onAction;
  const DefaultGameView({super.key, required this.view, required this.onAction});
  @override State<DefaultGameView> createState() => _DefaultGameViewState();
}

class _DefaultGameViewState extends State<DefaultGameView> {
  final selected = <String>{};

  @override void didUpdateWidget(covariant DefaultGameView oldWidget) {
    super.didUpdateWidget(oldWidget);
    selected.retainAll(widget.view.hand);
    if (widget.view.phase != GamePhase.playing) selected.clear();
  }

  void toggleCard(String id) => setState(() {
    if (!selected.add(id)) selected.remove(id);
  });

  void perform(ActionView action) {
    if (widget.onAction(action.toAction(selected))) {
      setState(selected.clear);
    }
  }

  @override Widget build(BuildContext context) {
    final view = widget.view;
    final canSelect = view.actions.any((action) => action.selection);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(view.status, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8), Text(view.info),
      PrivateInfo(text: view.privateText, assetPath: view.privateCard),
      const SizedBox(height: 12), PlayerList(players: view.players, you: view.you),
      if (view.table.isNotEmpty || view.hand.isNotEmpty) ...[
        const Divider(height: 28),
        Text(view.tableLabel, style: Theme.of(context).textTheme.titleMedium),
        CardHand(cards: view.table, emptyText: 'Empty'),
        const SizedBox(height: 16),
        Text('Your hand', style: Theme.of(context).textTheme.titleMedium),
        CardHand(cards: view.hand, selected: selected,
          onToggleCard: canSelect ? toggleCard : null),
      ],
      const SizedBox(height: 12),
      ActionButtons(actions: view.actions, hasSelection: selected.isNotEmpty,
        waiting: view.phase == GamePhase.playing, onAction: perform),
    ]);
  }
}
