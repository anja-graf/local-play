import 'dart:math';
import '../../../../core/game/game_model.dart';

class President extends StandardCardGame {
  static const gameName = 'President';
  static const minPlayers = 3;
  static const maxPlayers = 6;
  static const _order = ['three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'jack', 'queen', 'king', 'ace', 'two'];
  final List<String> _placements = [];
  final Set<String> _passed = {};
  List<String> _table = [];
  late String _turn;
  String? _leader;
  String _status = 'Play a single card or a group of equal ranks.';
  President(List<TablePlayer> players, Random random) : super(players, random) {
    require(players.length >= minPlayers && players.length <= maxPlayers, 'Invalid number of President players');
    var i = 0;
    while (deck.isNotEmpty) { draw(players[i++ % players.length].id); }
    for (final hand in hands.values) { hand.sort((a,b) => _value(a).compareTo(_value(b))); }
    _turn = players.firstWhere((p) => handOf(p.id).contains('club_three')).id;
    _runBots();
  }
  int _value(String card) => _order.indexOf(rankOf(card));
  List<String> get _active => players.map((p) => p.id).where((id) => !_placements.contains(id)).toList();
  @override GameType get type => GameType.president;
  @override String get title => '$gameName / Arschloch';
  @override bool get finished => _placements.length == players.length;
  String _next(String after, List<String> eligible) {
    final start = players.indexWhere((p) => p.id == after);
    for (var i = 1; i <= players.length; i++) {
      final id = players[(start + i) % players.length].id;
      if (eligible.contains(id)) return id;
    }
    throw StateError('No eligible player');
  }
  @override void apply(String playerId, TableAction action) {
    _move(playerId, action); _runBots();
  }
  void _move(String id, TableAction action) {
    require(!finished && id == _turn, 'It is not your turn');
    if (action.id == 'play') {
      final cards = action.cards;
      checkSelection(id, cards);
      require(cards.every((c) => rankOf(c) == rankOf(cards.first)), 'All selected cards must have the same rank');
      if (_table.isNotEmpty) {
        require(cards.length == _table.length && _value(cards.first) > _value(_table.first), 'Play the same number of cards with a higher rank');
      }
      removeCards(id, cards); _table = List.of(cards); _leader = id;
      _status = '${nameOf(id)} played ${cards.length} × ${rankOf(cards.first)}.';
      if (handOf(id).isEmpty) {
        _placements.add(id); _status += ' Finished #${_placements.length}!';
        if (_active.length == 1) {
          _placements.add(_active.single); _status = '${nameOf(_placements.first)} wins!'; return;
        }
      }
    } else if (action.id == 'pass') {
      require(_table.isNotEmpty, 'You must lead with a card');
      _passed.add(id); _status = '${nameOf(id)} passed.';
    } else { throw const RuleError('Unknown action'); }
    final eligible = _active.where((p) => !_passed.contains(p) && p != _leader).toList();
    if (eligible.isEmpty) {
      final lead = _leader!;
      _turn = _active.contains(lead) ? lead : _next(lead, _active);
      _passed.clear(); _table = []; _leader = null;
      _status += ' New trick: ${nameOf(_turn)} leads.';
    } else { _turn = _next(id, eligible); }
  }
  void _runBots() {
    for (var guard = 0; !finished && isBot(_turn); guard++) {
      if (guard > 3000) throw StateError('Bot loop exceeded limit');
      final hand = handOf(_turn);
      final groups = <String, List<String>>{};
      for (final c in hand) { groups.putIfAbsent(rankOf(c), () => []).add(c); }
      final need = _table.isEmpty ? 1 : _table.length;
      List<String>? choice;
      for (final group in groups.values) {
        if (group.length >= need && (_table.isEmpty || _value(group.first) > _value(_table.first))) {
          choice = group.take(need).toList(); break;
        }
      }
      _move(_turn, choice == null ? const TableAction('pass') : TableAction('play', choice));
    }
  }
  @override GameViewState view(String playerId) => projection(
    playerId: playerId, status: finished ? _status : '$_status\nTurn: ${nameOf(_turn)}', hand: List.of(handOf(playerId)), table: List.of(_table),
    tableLabel: 'Current trick', info: '3 low · 2 high. Match group size and beat rank. Pass until next trick.',
    publicPlayers: cardPlayers(turn: finished ? null : _turn, notes: {
      for (var i = 0; i < _placements.length; i++) _placements[i]: '#${i+1}',
      for (final p in _passed) if (!_placements.contains(p)) p: 'Passed',
    }), actions: [
      if (!finished && _turn == playerId) ...[
        actionButton('play', 'Play selected cards', selection: true),
        if (_table.isNotEmpty) actionButton('pass', 'Pass'),
      ],
    ],
  );
}
