import 'dart:math';
import 'models/game_type.dart';
import 'models/table_player.dart';
import 'models/table_action.dart';
import 'models/game_view_state.dart';

abstract class TableGame {
  final List<TablePlayer> players;
  final Random random;
  TableGame(List<TablePlayer> players, this.random) : players = List.unmodifiable(players);
  GameType get type;
  String get title;
  bool get finished;

  /// Opt in only if another player's action cannot invalidate the meaning of
  /// a pending action in the same epoch. The game still validates every action.
  bool get allowsConcurrentActions => false;
  /// Change whenever pending actions from the old phase must be invalidated.
  int get actionEpoch => 0;

  void apply(String playerId, TableAction action);
  GameViewState view(String playerId);
  String nameOf(String id) => players.firstWhere((p) => p.id == id).name;
  bool isBot(String id) => players.firstWhere((p) => p.id == id).bot;

  GameViewState projection({required String playerId, required String status,
    List<String> hand = const [], List<String> table = const [],
    String tableLabel = 'Table', String privateText = '', String? privateCard,
    String info = '', List<ActionView> actions = const [],
    required List<PlayerView> publicPlayers}) => GameViewState(
      gameType: type, phase: finished ? GamePhase.finished : GamePhase.playing,
      title: title, status: status, you: playerId, hand: hand, table: table,
      tableLabel: tableLabel, privateText: privateText, privateCard: privateCard,
      info: info, actions: actions, players: publicPlayers);
}
