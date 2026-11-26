import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/networking/communication/host_service.dart';
import '../../core/game/game_session.dart';
import '../../core/game/hosting_room.dart';
import '../play_game/game_page.dart';

class HostPage extends StatefulWidget {
  final HostingRoom room;
  const HostPage({super.key, required this.room});
  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  HostingRoom get room => widget.room;
  GameSession get session => room.session;
  late final StreamSubscription<void> subscription;
  HostingInfo? get info => room.info;
  bool busy = false;
  String? error;
  int initialHandSize = 5;

  @override
  void initState() {
    super.initState();
    final handMax = session.definition.maxInitialHandSize;
    if (handMax != null && initialHandSize > handMax) {
      initialHandSize = handMax;
    }
    subscription = session.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> start() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await room.startHosting();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> stop() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await room.stopHosting();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> startGame() async {
    if (busy || !session.canStart) return;
    setState(() => error = null);
    try {
      session.start(initialHandSize: initialHandSize);
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => GamePage(session: session)),
      );
      if (!mounted) return;
      session.reset();

      if (room.isHosting) {
        final stopServer = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Keep the server running?'),
            content: const Text(
              'Connected players can join your next game without reconnecting.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Stop Server'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep Server'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (stopServer == true) {
          await stop();
          if (!mounted || room.isHosting) return;
        }
        // Dismissing via system back keeps the connection.
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  String get _gameUrl => 'http://${info?.hotspot.address ?? 'game.local'}/';

  void _showWebsiteQr() {
    final url = _gameUrl;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join LocalPlay'),
        content: SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 220, height: 220, child: QrImageView(data: url)),
              const SizedBox(height: 12),
              SelectableText(url),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: Text(session.definition.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FilledButton(
            onPressed: busy ? null : (info == null ? start : stop),
            child: Text(
              busy
                  ? 'Please wait...'
                  : info == null
                  ? 'Start Server'
                  : 'Stop Server',
            ),
          ),
          if (error != null)
            Text(
              'Error: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (info != null) ...[
            const SizedBox(height: 20),
            const Text(
              '1. Scan to join the Wi-Fi',
              style: TextStyle(fontSize: 18),
            ),
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: wifiQr(info!.hotspot.ssid, info!.hotspot.password),
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
            ),
            SelectableText('Network: ${info!.hotspot.ssid}'),
            SelectableText('Password: ${info!.hotspot.password}'),
            const SizedBox(height: 24),
            const Text(
              '2. Open the game in your browser',
              style: TextStyle(fontSize: 18),
            ),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    info!.mdnsStarted ? 'http://game.local' : _gameUrl,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  tooltip: 'Website QR Code',
                  onPressed: _showWebsiteQr,
                ),
              ],
            ),
            if (info!.hotspot.address != null)
              SelectableText('IP fallback: $_gameUrl'),
            if (!info!.mdnsStarted)
              const Text('mDNS could not start; use the IP address.'),
            const Text('“No Internet Connection” warning is normal.'),
          ],
          const SizedBox(height: 20),
          Text(
            'Players (${session.humans.length}/${session.definition.maxPlayers})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final p in session.humans)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person),
              title: Text(p.name),
              trailing: p.id == GameSession.hostId
                  ? const Text('You')
                  : IconButton(
                      icon: const Icon(Icons.person_remove),
                      tooltip: 'Remove player',
                      onPressed: busy ? null : () => session.leave(p.id),
                    ),
            ),
          const SizedBox(height: 12),
          Text(session.definition.playerRange),
          Text(session.definition.lobbyInfo),
          if (session.botsNeeded > 0)
            Text('${session.botsNeeded} bot(s) will be added when you start.'),
          if (session.definition.configurableHandSize) ...[
            const SizedBox(height: 12),
            Text('Starting cards per player: $initialHandSize'),
            Slider(
              value: initialHandSize.toDouble(),
              min: 0,
              max: session.definition.maxInitialHandSize!.toDouble(),
              divisions: session.definition.maxInitialHandSize! > 0
                  ? session.definition.maxInitialHandSize!
                  : null,
              label: '$initialHandSize',
              onChanged: busy || session.definition.maxInitialHandSize == 0
                  ? null
                  : (v) => setState(() => initialHandSize = v.round()),
            ),
          ],
          if (session.startBlockReason != null && !session.started)
            Text(
              session.startBlockReason!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton.icon(
            onPressed: busy || !session.canStart ? null : startGame,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Game'),
          ),
        ),
      ),
    ),
  );
}

String wifiQr(String ssid, String password) {
  String escape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(';', r'\;')
      .replaceAll(':', r'\:')
      .replaceAll(',', r'\,')
      .replaceAll('"', r'\"');
  return 'WIFI:T:WPA;S:${escape(ssid)};P:${escape(password)};;';
}
