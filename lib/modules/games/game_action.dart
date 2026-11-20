enum GameActionType {
  playCard,
}

class GameAction {
  final GameActionType type;
  final String card;

  const GameAction({
    required this.type,
    required this.card,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'card': card,
  };

  factory GameAction.fromJson(Map<String, dynamic> json) {
    return GameAction(
      type: GameActionType.values.byName(json['type'] as String),
      card: json['card'] as String,
    );
  }
}