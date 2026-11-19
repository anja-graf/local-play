enum NetworkEventType {
  connected,
  disconnected,
  playerJoined,
  playerLeft,
  lobbyUpdated,
  gameStateUpdated,
  error,
}

class NetworkEvent {
  final NetworkEventType type;
  final dynamic data;

  NetworkEvent({
    required this.type,
    this.data,
  });
}