import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/game/game_model.dart';
import '../../core/game/game_session.dart';
import 'game_registry.dart';

class GamePage extends StatefulWidget {
  final GameSession session;
  const GamePage({super.key, required this.session});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final StreamSubscription<void> subscription;
  late GameViewState view;
  String? error;

  @override
  void initState() {
    super.initState();
    view = widget.session.viewState(GameSession.hostId);
    subscription = widget.session.changes.listen((_) {
      if (mounted) setState(refresh);
    });
  }

  void refresh() => view = widget.session.viewState(GameSession.hostId);

  bool perform(TableAction action, int version) {
    try {
      widget.session.apply(GameSession.hostId, action, version: version);
      setState(() { error = null; refresh(); });
      return true;
    } catch (e) {
      setState(() { error = e.toString(); refresh(); });
      return false;
    }
  }

  Future<void> _returnToLobby() async {
    final answer = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End game?'),
        content: const Text('This ends the current round for everyone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('End round')),
        ],
      ));
    if (answer == true && mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    unawaited(subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = view;
    return Scaffold(
    appBar: AppBar(title: Text(current.title),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _returnToLobby)),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      if (error != null) ...[
        Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 12),
      ],
      GameRegistry.buildView(type: current.gameType, view: current,
        onAction: (action) => perform(action, current.version)),
      if (current.phase == GamePhase.finished) ...[
        const SizedBox(height: 12),
        FilledButton(onPressed: _returnToLobby, child: const Text('Back to game selection')),
      ],
    ]),
    );
  }
}
