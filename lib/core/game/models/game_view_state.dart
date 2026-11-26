import 'game_type.dart';
import 'table_action.dart';
import 'table_player.dart';

/// Public player information only. Never include a hidden hand or living role.
class PlayerView {
  final String id;
  final String name;
  final bool bot;
  final bool turn;
  final int? count;
  final String note;

  const PlayerView({required this.id, required this.name, this.bot = false,
    this.turn = false, this.count, this.note = ''});

  factory PlayerView.fromPlayer(TablePlayer player, {bool turn = false,
    int? count, String note = ''}) => PlayerView(id: player.id, name: player.name,
      bot: player.bot, turn: turn, count: count, note: note);

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'bot': bot, 'turn': turn,
    if (count != null) 'count': count, 'note': note,
  };
}

/// Immutable projection for ONE authenticated player. Not the internal game.
class GameViewState {
  final GameType gameType;
  final GamePhase phase;
  final String title;
  final String status;
  final String you;
  final int version;
  final String info;
  final List<String> hand;
  final List<String> table;
  final String tableLabel;
  final String privateText;
  final String? privateCard;
  final List<PlayerView> players;
  final List<ActionView> actions;

  GameViewState({required this.gameType, required this.phase,
    required this.title, required this.status, required this.you,
    this.version = 0, this.info = '', List<String> hand = const [],
    List<String> table = const [], this.tableLabel = 'Table',
    this.privateText = '', this.privateCard, required List<PlayerView> players,
    List<ActionView> actions = const []}) : hand = List.unmodifiable(hand),
      table = List.unmodifiable(table), players = List.unmodifiable(players),
      actions = List.unmodifiable(actions);

  /// The session, not the game, owns the globally increasing wire version.
  GameViewState withVersion(int value) => GameViewState(gameType: gameType,
    phase: phase, title: title, status: status, you: you, version: value,
    info: info, hand: hand, table: table, tableLabel: tableLabel,
    privateText: privateText, privateCard: privateCard, players: players,
    actions: actions);

  Map<String, dynamic> toJson() => {
    'gameType': gameType.name, 'phase': phase.name, 'title': title,
    'status': status, 'you': you, 'version': version, 'info': info,
    'hand': hand, 'table': table, 'tableLabel': tableLabel,
    'privateText': privateText, if (privateCard != null) 'privateCard': privateCard,
    'players': players.map((p) => p.toJson()).toList(),
    'actions': actions.map((a) => a.toJson()).toList(),
  };
}
