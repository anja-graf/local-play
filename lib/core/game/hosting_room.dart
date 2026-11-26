import '../networking/communication/host_service.dart';
import '../networking/communication/web_client_assets.dart';
import 'game_definition.dart';
import 'game_model.dart';
import 'game_session.dart';
import 'game_message_handler.dart';
import '../networking/communication/local_http_server.dart';

/// Owns the multiplayer connection and room across page navigation.
class HostingRoom {
  final GameSession session;
  late final HostService hostService;
  HostingInfo? _info;
  HostingInfo? get info => _info;
  bool get isHosting => _info != null;

  HostingRoom(GameDefinition initialGame) : session = GameSession(initialGame) {
    final handler = GameMessageHandler(session);

    final server = LocalHttpServer(
      onMessage: handler.handle,
      webAsset: 'assets/web_client/index.html',
      staticAssets: {
        ...GameMessageHandler.cardAssets,
        ...webClientAssets,

        for (final role in ['werewolf', 'seer', 'villager'])
          '/assets/cards/werewolf/$role.svg': 'assets/cards/werewolf/$role.svg',
      },
    );

    hostService = HostService(server: server);
  }

  Future<void> startHosting() async {
    if (isHosting) return;
    _info = await hostService.startHosting();
  }

  Future<void> stopHosting() async {
    if (!isHosting) return;
    require(!session.started, 'End the current game first');
    await hostService.stopHosting();
    _info = null;
    for (final player in session.humans) {
      if (player.id != GameSession.hostId) session.leave(player.id);
    }
  }

  Future<void> close() async {
    try {
      if (session.started) session.reset();
      await stopHosting();
    } finally {
      await session.close();
    }
  }
}
