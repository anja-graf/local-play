import 'package:localplay/core/networking/events/network_event.dart';
import 'package:localplay/core/networking/communication/networking_service.dart';
import 'package:localplay/core/cards/game_action.dart';

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