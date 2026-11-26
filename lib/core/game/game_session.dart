import 'dart:async';
import 'dart:math';
import 'game_model.dart';
import 'game_definition.dart';

class GameSession {
  static const hostId = 'host';
  GameDefinition _definition;
  GameDefinition get definition => _definition;
  GameType get type => definition.type;

  int get botsNeeded => definition.supportsBots
      ? max(0, definition.minPlayers - _humans.length)
      : 0;

  /// Switching games preserves existing players, even if the new game is full.
  /// The host can remove excess players before starting.
  String? get startBlockReason {
    if (_closed) return 'Session is closed';
    if (started) return 'Game already started';
    if (_humans.length > definition.maxPlayers) {
      return 'Too many players. Remove ${_humans.length - definition.maxPlayers} '
          'before starting (max ${definition.maxPlayers}).';
    }
    if (_humans.length + botsNeeded < definition.minPlayers) {
      return 'At least ${definition.minPlayers} players are required.';
    }
    return null;
  }

  bool get canStart => startBlockReason == null;
  final Random _random;
  final Random _secure = Random.secure();
  final _changes = StreamController<void>.broadcast();
  final Map<String, TablePlayer> _humans = {hostId: const TablePlayer(hostId, 'Host')};
  final Map<String, String> _tokens = {};
  TableGame? _game;
  int _nextId = 1;
  int _version = 0;
  int _phaseVersion = 0;
  final Map<String, int> _lastActionVersion = {};
  bool _closed = false;
  GameSession(this._definition, {Random? random}) : _random = random ?? Random();
  Stream<void> get changes => _changes.stream;
  bool get started => _game != null;
  List<TablePlayer> get humans => List.unmodifiable(_humans.values);
  void _notify() { _version++; if (!_closed) _changes.add(null); }
  String join(String name) {
    require(!_closed && !started, 'The lobby is closed for this round');
    require(_humans.length < definition.maxPlayers,
        'Lobby is full (max ${definition.maxPlayers} players)');
    name = name.trim();
    require(name.isNotEmpty && name.length <= 24, 'Choose a name with 1–24 characters');
    require(!_humans.values.any((p) => p.name.toLowerCase() == name.toLowerCase()), 'Name already in use');
    final id = 'player${_nextId++}';
    final token = List.generate(32, (_) => _secure.nextInt(256).toRadixString(16).padLeft(2,'0')).join();
    _humans[id] = TablePlayer(id, name); _tokens[token] = id; _notify();
    return token;
  }
  String authenticate(String token) {
    final id = _tokens[token];
    require(id != null && _humans.containsKey(id), 'Session expired. Join again.');
    return id!;
  }
  void leave(String id) {
    require(!started && id != hostId && _humans.containsKey(id), 'Cannot leave during a round');
    _humans.remove(id); _tokens.removeWhere((_, v) => v == id); _notify();
  }
  void start({int initialHandSize = 5}) {
    final blocker = startBlockReason;
    require(blocker == null, blocker ?? 'Cannot start game');
    final players = humans.toList();
    final missing = botsNeeded;
    for (var i = 1; i <= missing; i++) {
      players.add(TablePlayer('bot$i', 'Bot $i', bot: true));
    }
    final handMax = definition.maxInitialHandSize;
    if (handMax != null) {
      require(initialHandSize >= 0 && initialHandSize <= handMax,
          'Choose between 0 and $handMax starting cards');
    }
    _game = definition.createGame(players, _random, initialHandSize: initialHandSize);
    _notify();
    _phaseVersion = _version;
    _lastActionVersion.clear();
  }
  // Switch games without replacing the room or invalidating player tokens.
  void selectGame(GameDefinition definition) {
    require(!_closed && !started, 'End the current game first');
    if (identical(_definition, definition)) return;
    _definition = definition;
    _notify();
  }
  void reset() {
    _game = null;
    _lastActionVersion.clear();
    _notify();
    _phaseVersion = _version;
  }

  void apply(String id, TableAction action, {required int version}) {
    require(!_closed && _humans.containsKey(id), 'Unknown player');
    final game = _game;
    require(game != null, 'Wait for the host to start');
    final currentGame = game!;
    require(!currentGame.finished, 'Round is finished');
    // Strict by default. Concurrent games accept a view from this phase,
    // provided the same player has not already submitted a newer action.
    final minimum = currentGame.allowsConcurrentActions
        ? max(_phaseVersion, _lastActionVersion[id] ?? _phaseVersion)
        : _version;
    require(version >= minimum && version <= _version, 'State changed. Try again.');
    final epoch = currentGame.actionEpoch;
    currentGame.apply(id, action);
    _notify();
    _lastActionVersion[id] = _version;
    if (currentGame.actionEpoch != epoch) _phaseVersion = _version;
  }

  GameViewState viewState(String id) {
    require(_humans.containsKey(id), 'Unknown player');
    final game = _game;
    if (game != null) return game.view(id).withVersion(_version);
    return GameViewState(gameType: type, phase: GamePhase.lobby,
      title: definition.name, status: startBlockReason ?? 'Waiting for the host to start the game',
      you: id, version: _version,
      info: '${definition.playerRange} · ${definition.lobbyInfo}',
      players: [for (final p in humans) PlayerView.fromPlayer(p)]);
  }

  // Compatibility adapter: GameMessageHandler can keep its existing calls.
  Map<String, dynamic> view(String id) => viewState(id).toJson();
  Future<void> close() async { _closed = true; await _changes.close(); }
}
