import 'dart:math';
import '../../../../core/game/game_model.dart';

int blackjackScore(List<String> cards) {
  var total = 0;
  var aces = 0;
  for (final card in cards) {
    final rank = rankOf(card);
    if (rank == 'ace') { total += 11; aces++; }
    else { total += min(10, ranks.indexOf(rank) + 1); }
  }
  while (total > 21 && aces > 0) { total -= 10; aces--; }
  return total;
}
bool _natural(List<String> cards) => cards.length == 2 && blackjackScore(cards) == 21;

class Blackjack extends StandardCardGame {
  static const gameName = 'Blackjack';
  static const minPlayers = 1;
  static const maxPlayers = 6;
  final List<String> _dealer = [];
  final Set<String> _stood = {};
  final Map<String, String> _results = {};
  bool _done = false;

  Blackjack(List<TablePlayer> players, Random random) : super(players, random) {
    require(players.length >= minPlayers && players.length <= maxPlayers, 'Invalid number of Blackjack players');
    for (var i = 0; i < 2; i++) {
      for (final p in players) { draw(p.id); }
      _dealer.add(deck.removeLast());
    }
    if (_natural(_dealer)) { _finish(); } else { _advance(); }
  }
  @override GameType get type => GameType.blackjack;
  @override String get title => gameName;
  @override bool get finished => _done;
  @override bool get allowsConcurrentActions => true;
  @override int get actionEpoch => _done ? 1 : 0;

  bool _canAct(String id) => !_done && hands.containsKey(id) &&
      !_stood.contains(id) && blackjackScore(handOf(id)) < 21 && deck.isNotEmpty;

  @override void apply(String playerId, TableAction action) {
    require(_canAct(playerId), 'Your hand is already complete');
    if (action.id == 'hit') {
      draw(playerId);
      if (blackjackScore(handOf(playerId)) >= 21) _stood.add(playerId);
    } else if (action.id == 'stand') {
      _stood.add(playerId);
    } else { throw const RuleError('Unknown action'); }
    _advance();
  }

  void _advance() {
    // Each player has an independent hand. Bots (if any) act automatically.
    for (final p in players.where((p) => p.bot && _canAct(p.id))) {
      while (blackjackScore(handOf(p.id)) < 17 && deck.isNotEmpty) { draw(p.id); }
      _stood.add(p.id);
    }
    if (players.any((p) => _canAct(p.id))) return;
    // All players stood, reached 21, busted, or the deck is exhausted.
    while (blackjackScore(_dealer) < 17 && deck.isNotEmpty) { _dealer.add(deck.removeLast()); }
    _finish();
  }

  void _finish() {
    final dealerScore = blackjackScore(_dealer);
    for (final p in players) {
      final h = handOf(p.id);
      final score = blackjackScore(h);
      _results[p.id] = score > 21 ? 'Bust — lost' :
        _natural(h) && _natural(_dealer) ? 'Push' :
        _natural(h) ? 'Blackjack — won' : _natural(_dealer) ? 'Lost' :
        dealerScore > 21 || score > dealerScore ? 'Won' : score == dealerScore ? 'Push' : 'Lost';
    }
    _done = true;
  }

  @override GameViewState view(String playerId) => projection(
    playerId: playerId,
    status: _done ? 'Dealer: ${blackjackScore(_dealer)}. Round complete.' :
      _canAct(playerId) ? 'Choose Hit or Stand.' : 'Waiting for the other players…',
    hand: handOf(playerId), table: _done ? _dealer : [_dealer.first, 'back'],
    tableLabel: 'Dealer', privateText: 'Your total: ${blackjackScore(handOf(playerId))}${_done ? ' — ${_results[playerId]}' : ''}',
    info: 'All players act independently. Dealer plays after everyone finishes. Dealer stands on all 17s. No bets, splits, doubling or insurance.',
    publicPlayers: cardPlayers(active: {for (final p in players) if (_canAct(p.id)) p.id},
      notes: _done ? _results : {for (final p in players) if (!_canAct(p.id)) p.id: 'Done'}),
    actions: [if (_canAct(playerId)) ...[actionButton('hit', 'Hit'), actionButton('stand', 'Stand')]],
  );
}
