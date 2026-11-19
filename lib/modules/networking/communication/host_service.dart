import 'package:localplay/modules/networking/events/network_event.dart';
import 'package:localplay/modules/networking/communication/networking_service.dart';
import 'package:localplay/modules/games/game_action.dart';

class HostService implements NetworkingService {
  @override
  Future<void> disconnect() {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  // TODO: implement events
  Stream<NetworkEvent> get events => throw UnimplementedError();

  @override
  Future<void> sendAction(GameAction action) {
    // TODO: implement sendAction
    throw UnimplementedError();
  }
  // Starts TCP server
  // Accepts clients
  // Broadcasts messages
  // Implements interface
}