import 'package:flutter/material.dart';
import '../../../../core/game/game_model.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/player_list.dart';
import '../../widgets/private_info.dart';

class WerewolfView extends StatelessWidget {
  final GameViewState view;
  final bool Function(TableAction) onAction;

  const WerewolfView({super.key, required this.view, required this.onAction});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(view.status, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(view.info),
      const SizedBox(height: 12),
      PrivateInfo(text: view.privateText,
        assetPath: view.privateCard),
      const SizedBox(height: 16),
      Text('Village', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      PlayerList(players: view.players,
        you: view.you),
      const SizedBox(height: 16),
      ActionButtons(actions: view.actions,
        waiting: view.phase == GamePhase.playing, onAction: (action) { onAction(action.toAction()); }),
    ],
  );
}
