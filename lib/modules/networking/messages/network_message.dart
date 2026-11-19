enum MessageType {
  join,
  leave,
  lobbyUpdate,
  gameAction,
  gameStateUpdate,
  error
}

class NetworkMessage {
  final MessageType type;
  final Map<String, dynamic> data;

  NetworkMessage({
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
    };
  }

  factory NetworkMessage.fromJson(Map<String, dynamic> json) {
    return NetworkMessage(
      type: MessageType.values.byName(json['type'] as String),
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}