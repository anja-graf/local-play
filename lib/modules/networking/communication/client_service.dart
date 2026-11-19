import 'package:localplay/modules/networking/events/network_event.dart';
import 'package:localplay/modules/networking/communication/networking_service.dart';
import 'package:localplay/modules/games/game_action.dart';

class ClientService implements NetworkingService {
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
  // Connects to host
  // Sends messages
  // Receives updates
  // Implements interface
}