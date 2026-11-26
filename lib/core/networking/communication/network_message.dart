import 'dart:async';

typedef MessageHandler = FutureOr<Map<String, dynamic>> Function(
  NetworkMessage message,
  String? token,
);

class NetworkMessage {
  final String type;
  final Map<String, dynamic> payload;

  const NetworkMessage({
    required this.type,
    this.payload = const {},
  });

  factory NetworkMessage.fromJson(
    Map<String, dynamic> json,
  ) {
    final type = json['type'];
    final payload = json['payload'] ?? <String, dynamic>{};

    if (type is! String || type.isEmpty) {
      throw const NetworkMessageException(
        'Invalid message type',
      );
    }

    if (payload is! Map<String, dynamic>) {
      throw const NetworkMessageException(
        'Invalid payload',
      );
    }

    return NetworkMessage(
      type: type,
      payload: payload,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'payload': payload,
  };
}

class NetworkMessageException implements Exception {
  final String message;
  final int statusCode;

  const NetworkMessageException(
    this.message, [
    this.statusCode = 400,
  ]);

  @override
  String toString() => message;
}