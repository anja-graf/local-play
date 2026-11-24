import '../events/network_event.dart';
import 'package:localplay/core/cards/game_action.dart';

abstract class NetworkingService {
  Stream<NetworkEvent> get events;

  Future<void> sendAction(GameAction action);

  Future<void> disconnect();
}