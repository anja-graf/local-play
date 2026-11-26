import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/game/game_model.dart';
import '../../core/game/game_definition.dart';
import '../../core/game/hosting_room.dart';
import '../play_game/game_registry.dart';
import '../lobby/host_page.dart';

class SelectGamePage extends StatefulWidget {
  const SelectGamePage({super.key});
  @override
  State<SelectGamePage> createState() => _SelectGamePageState();
}

class _SelectGamePageState extends State<SelectGamePage> {
  final room = HostingRoom(GameRegistry.forType(GameType.freePlay));
  bool busy = false;

  Future<void> _openGame(GameDefinition game) async {
    if (busy) return;
    room.session.selectGame(game);
    await Navigator.push(context, MaterialPageRoute<void>(
      builder: (_) => HostPage(room: room),
    ));
    if (mounted) setState(() {});
  }

  Future<void> _stopServer() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await room.stopHosting();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _closeRoom() async {
    try {
      await room.close();
    } catch (e) {
      debugPrint('Room cleanup failed: $e');
    }
  }

  @override
  void dispose() {
    unawaited(_closeRoom());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('LocalPlay')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Select a game', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('Play together without internet.'),
      const SizedBox(height: 16),
      if (room.isHosting) Card(child: ListTile(
        leading: const Icon(Icons.wifi),
        title: const Text('Server running'),
        subtitle: const Text('Your room remains open'),
        trailing: TextButton(onPressed: busy ? null : _stopServer,
          child: const Text('Stop Server')),
      )),
      for (final game in GameRegistry.games) Card(child: ListTile(
        leading: SizedBox(width: 40,
          child: Center(child: Text(game.symbol, style: const TextStyle(fontSize: 28)))),
        title: Text(game.name),
        subtitle: Text('${game.description} · ${game.playerRange}'
            '${game.supportsBots ? ' (including bots)' : ''}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: busy ? null : () => _openGame(game),
      )),
    ]),
  );
}
