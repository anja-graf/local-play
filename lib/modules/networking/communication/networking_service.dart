import '../events/network_event.dart';
import 'package:localplay/modules/games/game_action.dart';

abstract class NetworkingService {
  Stream<NetworkEvent> get events;

  Future<void> sendAction(GameAction action);

  Future<void> disconnect();
}