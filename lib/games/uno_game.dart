
import 'dart:math';

enum UnoColor {
  red,
  yellow,
  green,
  blue,
  wild,
}

class UnoCard {
  final UnoColor color;
  final String value;

  const UnoCard(this.color, this.value);

  bool get isWild => color == UnoColor.wild;

  bool get isAction =>
      ['Skip', 'Reverse', '+2', '+4'].contains(value);

  String get label => value;
}

class UnoPlayer {
  final String name;
  final List<UnoCard> hand;
  final bool isBot;

  UnoPlayer(
    this.name, {
    List<UnoCard>? cards,
    this.isBot = false,
  }) : hand = cards ?? [];
}

class UnoGame {
  final List<UnoPlayer> players;

  final List<UnoCard> drawPile = [];
  final List<UnoCard> discardPile = [];

  int currentPlayer = 0;
  int direction = 1;

  UnoColor activeColor = UnoColor.red;

  String? winner;
  String message = 'Game started';

  UnoGame(
    List<String> playerNames, {
    Set<int> botPlayers = const <int>{},
  }) : players = playerNames.asMap().entries.map((entry) {
          return UnoPlayer(
            entry.value,
            isBot: botPlayers.contains(entry.key),
          );
        }).toList() {
    _createDeck();

    _shuffle(drawPile);

    // Give each player seven cards.
    for (var i = 0; i < 7; i++) {
      for (final player in players) {
        player.hand.add(_drawFromPile());
      }
    }

    // Start with a normal number card.
    var firstCard = _drawFromPile();

    while (firstCard.isAction || firstCard.isWild) {
      drawPile.add(firstCard);
      _shuffle(drawPile);
      firstCard = _drawFromPile();
    }

    discardPile.add(firstCard);

    activeColor = firstCard.color;

    message = '${players[currentPlayer].name} starts';
  }

  UnoCard get topCard => discardPile.last;

  UnoPlayer get activePlayer => players[currentPlayer];

  // Create the UNO deck.
  void _createDeck() {
    for (final color in [
      UnoColor.red,
      UnoColor.yellow,
      UnoColor.green,
      UnoColor.blue,
    ]) {
      // One zero card.
      drawPile.add(UnoCard(color, '0'));

      // Two cards of every number from 1 to 9.
      for (var number = 1; number <= 9; number++) {
        drawPile.add(UnoCard(color, '$number'));
        drawPile.add(UnoCard(color, '$number'));
      }

      // Two of every action card.
      for (final action in ['Skip', 'Reverse', '+2']) {
        drawPile.add(UnoCard(color, action));
        drawPile.add(UnoCard(color, action));
      }
    }

    // Wild cards and Wild Draw Four cards.
    for (var i = 0; i < 4; i++) {
      drawPile.add(const UnoCard(UnoColor.wild, 'Wild'));
      drawPile.add(const UnoCard(UnoColor.wild, '+4'));
    }
  }

  void _shuffle(List<UnoCard> cards) {
    cards.shuffle(Random());
  }

  // Draw a card from the deck.
  UnoCard _drawFromPile() {
    if (drawPile.isEmpty) {
      if (discardPile.length <= 1) {
        throw StateError('No cards available');
      }

      // Keep the top card and recycle the other discard cards.
      final top = discardPile.removeLast();

      drawPile.addAll(discardPile);

      discardPile
        ..clear()
        ..add(top);

      _shuffle(drawPile);
    }

    return drawPile.removeLast();
  }

  // Check if a card can be played.
  bool canPlay(UnoCard card) {
    return card.isWild ||
        card.color == activeColor ||
        card.value == topCard.value;
  }

  // Draw one card and finish the turn.
  void drawCard() {
    if (winner != null) return;

    try {
      activePlayer.hand.add(_drawFromPile());

      message = '${activePlayer.name} drew a card';

      _advanceTurn();
    } catch (_) {
      message = 'No cards available to draw';
    }
  }

  // Play a card.
  void playCard(
    UnoCard card, {
    UnoColor? chosenColor,
  }) {
    if (winner != null ||
        !activePlayer.hand.contains(card) ||
        !canPlay(card)) {
      return;
    }

    activePlayer.hand.remove(card);

    discardPile.add(card);

    // Update the active colour.
    activeColor = card.isWild
        ? (chosenColor ?? UnoColor.red)
        : card.color;

    // Check winner.
    if (activePlayer.hand.isEmpty) {
      winner = activePlayer.name;
      message = '${activePlayer.name} wins!';
      return;
    }

    message = '${activePlayer.name} played ${card.label}';

    int steps = 1;

    switch (card.value) {
      case 'Skip':
        steps = 2;
        message += ' - next player skipped';
        break;

      case 'Reverse':
        direction *= -1;

        if (players.length == 2) {
          steps = 2;
        }

        message += ' - direction reversed';
        break;

      case '+2':
        final target = _nextIndex(currentPlayer);

        _drawForPlayer(target, 2);

        steps = 2;

        message += ' - ${players[target].name} draws 2';
        break;

      case '+4':
        final target = _nextIndex(currentPlayer);

        _drawForPlayer(target, 4);

        steps = 2;

        message += ' - ${players[target].name} draws 4';
        break;
    }

    // Move to the next player.
    for (var i = 0; i < steps; i++) {
      currentPlayer = _nextIndex(currentPlayer);
    }
  }

  int _nextIndex(int from) {
    return (from + direction + players.length) %
        players.length;
  }

  void _drawForPlayer(int playerIndex, int amount) {
    for (var i = 0; i < amount; i++) {
      try {
        players[playerIndex].hand.add(_drawFromPile());
      } catch (_) {
        break;
      }
    }
  }

  void _advanceTurn() {
    currentPlayer = _nextIndex(currentPlayer);
  }
}
