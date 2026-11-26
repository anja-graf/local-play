
import 'game_model.dart';
import 'game_session.dart';
import 'package:localplay/core/networking/communication/network_message.dart';


/// Game-specific dispatch. No HTTP server, sockets, ports or mDNS here.
class GameMessageHandler {
  final GameSession session;
  GameMessageHandler(this.session);

  // Only expose known assets, never arbitrary bundle paths from a URL.
  static Map<String, String> get cardAssets => {
    '/cards/back.svg': 'assets/cards/standard/back.svg',
    for (final suit in suits)
      for (final rank in ranks)
        '/cards/${suit}_$rank.svg': 'assets/cards/standard/${suit}_$rank.svg',
    for (final role in ['werewolf', 'seer', 'villager'])
      '/assets/cards/werewolf/$role.svg':
          'assets/cards/werewolf/$role.svg',
  };

  String _player(String? token) {
    if (token == null || token.isEmpty) {
      throw const NetworkMessageException('Join first', 401);
    }
    try {
      return session.authenticate(token);
    } on RuleError catch (e) {
      throw NetworkMessageException(e.message, 401);
    }
  }

  Map<String, dynamic> handle(NetworkMessage message, String? token) {
    try {
      final payload = message.payload;
      switch (message.type) {
        case 'join':
          require(payload['name'] is String, 'Invalid name');
          return {'token': session.join(payload['name'] as String)};
        case 'state':
          return session.view(_player(token));
        case 'action':
          final id = _player(token);
          require(payload['version'] is int, 'Missing state version');
          session.apply(id, TableAction.fromJson(payload),
              version: payload['version'] as int);
          return session.view(id);
        case 'leave':
          session.leave(_player(token));
          return {'ok': true};
        default:
          throw const NetworkMessageException('Unknown message type');
      }
    } on RuleError catch (e) {
      throw NetworkMessageException(e.message);
    }
  }
}
