import 'dart:math';
import '../../../../core/game/game_model.dart';

class _TableCard {
  final String id;
  bool faceUp;
  _TableCard(this.id, this.faceUp);
}

class FreePlay extends StandardCardGame {
  static const gameName = 'Classic Cards · Free Play';
  static const minPlayers = 1;
  static const maxPlayers = 6;
  final List<_TableCard> _pile = [];
  String _status = 'Free play: agree on your own rules.';
  FreePlay(List<TablePlayer> players, Random random, int initialHandSize) : super(players, random) {
    require(players.length >= minPlayers && players.length <= maxPlayers, 'Invalid number of Free Play players');
    require(initialHandSize >= 0 && initialHandSize * players.length <= deck.length, 'Too many starting cards');
    for (var i = 0; i < initialHandSize; i++) {
      for (final p in players) { draw(p.id); }
    }
  }
  @override GameType get type => GameType.freePlay;
  @override String get title => gameName;
  @override bool get finished => false;
  @override void apply(String playerId, TableAction action) {
    final id = action.id;
    final cards = action.cards;
    final name = nameOf(playerId);
    if (id == 'draw') {
      draw(playerId); _status = '$name drew a card.';
    } else if (id == 'play' || id == 'playHidden') {
      checkSelection(playerId, cards);
      removeCards(playerId, cards);
      _pile.addAll(cards.map((c) => _TableCard(c, id == 'play')));
      _status = '$name played ${cards.length} card(s).';
    } else if (id == 'take') {
      require(_pile.isNotEmpty, 'The table is empty');
      handOf(playerId).add(_pile.removeLast().id); _status = '$name took a table card.';
    } else if (id == 'flip') {
      require(_pile.isNotEmpty, 'The table is empty');
      _pile.last.faceUp = !_pile.last.faceUp; _status = '$name flipped the top card.';
    } else if (id.startsWith('give:')) {
      final target = id.substring(5);
      require(target != playerId && hands.containsKey(target), 'Unknown recipient');
      checkSelection(playerId, cards);
      removeCards(playerId, cards); handOf(target).addAll(cards);
      _status = '$name gave ${cards.length} card(s) to ${nameOf(target)}.';
    } else if (id == 'shuffle' || id == 'deal' || id == 'collect') {
      require(playerId == 'host', 'Only the host can do that');
      if (id == 'shuffle') {
        deck.shuffle(random); _status = 'Draw pile shuffled.';
      } else if (id == 'deal') {
        require(deck.length >= players.length, 'Not enough cards to deal to everyone');
        for (final p in players) { draw(p.id); }
        _status = 'One card dealt to each player.';
      } else {
        for (final h in hands.values) { deck.addAll(h); h.clear(); }
        deck.addAll(_pile.map((c) => c.id)); _pile.clear(); deck.shuffle(random);
        _status = 'All cards collected and shuffled.';
      }
    } else { throw const RuleError('Unknown action'); }
  }
  @override GameViewState view(String playerId) => projection(
    playerId: playerId, status: _status, hand: List.of(handOf(playerId)),
    table: _pile.reversed.take(8).toList().reversed.map((c) => c.faceUp ? c.id : 'back').toList(),
    tableLabel: 'Table · ${_pile.length} cards (top at right)', info: 'Draw pile: ${deck.length}',
    publicPlayers: cardPlayers(), actions: [
      if (deck.isNotEmpty) actionButton('draw', 'Draw card'),
      if (handOf(playerId).isNotEmpty) ...[
        actionButton('play', 'Play face up', selection: true),
        actionButton('playHidden', 'Play face down', selection: true),
        for (final p in players) if (p.id != playerId) actionButton('give:${p.id}', 'Give to ${p.name}', selection: true),
      ],
      if (_pile.isNotEmpty) ...[actionButton('take', 'Take top card'), actionButton('flip', 'Flip top card')],
      if (playerId == 'host') ...[
        if (deck.isNotEmpty) actionButton('shuffle', 'Shuffle draw pile'),
        if (deck.length >= players.length) actionButton('deal', 'Deal one to everyone'),
        actionButton('collect', 'Collect all cards'),
      ],
    ],
  );
}
