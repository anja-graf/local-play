import 'dart:math';

import 'game_model.dart';

/// Describes a game before it is started. No mutable round state or Flutter UI.
abstract class GameDefinition {
  const GameDefinition();

  GameType get type;
  String get name;
  String get description;
  String get lobbyInfo;
  String get symbol;

  /// Total participants, including the host and any bots (not the dealer).
  int get minPlayers;
  int get maxPlayers;
  bool get supportsBots => false;

  /// Null means there is no configurable starting hand size.
  int? get maxInitialHandSize => null;
  bool get configurableHandSize => maxInitialHandSize != null;

  String get playerRange => minPlayers == maxPlayers
  ? '$minPlayers players'
  : '$minPlayers–$maxPlayers players';

  TableGame createGame(
    List<TablePlayer> players,
    Random random, {
      int initialHandSize = 5,
    });
}
