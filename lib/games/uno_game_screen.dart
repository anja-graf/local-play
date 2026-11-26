
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'uno_game.dart';

class UnoGameScreen extends StatefulWidget {
  const UnoGameScreen({super.key});

  @override
  State<UnoGameScreen> createState() => _UnoGameScreenState();
}

class _UnoGameScreenState extends State<UnoGameScreen> {
  UnoGame? game;

  int playerCount = 2;

  bool playAlone = true;

  bool winnerDialogShown = false;

  bool robotThinking = false;

  // Card colours.
  Color getColor(UnoColor color) {
    switch (color) {
      case UnoColor.red:
        return const Color(0xFFE53935);
      case UnoColor.yellow:
        return const Color(0xFFFFD600);
      case UnoColor.green:
        return const Color(0xFF43A047);
      case UnoColor.blue:
        return const Color(0xFF1E88E5);
      case UnoColor.wild:
        return Colors.black;
    }
  }

  // Start a new game.
  void startGame() {
    setState(() {
      winnerDialogShown = false;
      robotThinking = false;

      if (playAlone) {
        game = UnoGame(
          ['You', 'Robot'],
          botPlayers: {1},
        );
      } else {
        game = UnoGame(
          List.generate(
            playerCount,
            (index) => 'Player ${index + 1}',
          ),
        );
      }
    });
  }

  // Show colour selection for Wild cards.
  Future<UnoColor?> chooseColor() {
    return showDialog<UnoColor>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Choose a colour'),
          content: Wrap(
            spacing: 12,
            children: [
              colorButton(dialogContext, UnoColor.red),
              colorButton(dialogContext, UnoColor.yellow),
              colorButton(dialogContext, UnoColor.green),
              colorButton(dialogContext, UnoColor.blue),
            ],
          ),
        );
      },
    );
  }

  Widget colorButton(
    BuildContext dialogContext,
    UnoColor color,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(dialogContext, color);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: getColor(color),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
        ),
      ),
    );
  }

  // Human plays a card.
  Future<void> playHumanCard(UnoCard card) async {
    final current = game;

    if (current == null ||
        current.winner != null ||
        current.activePlayer.isBot ||
        !current.canPlay(card)) {
      return;
    }

    UnoColor? chosenColor;

    if (card.isWild) {
      chosenColor = await chooseColor();

      if (chosenColor == null ||
          !mounted ||
          game != current) {
        return;
      }
    }

    setState(() {
      current.playCard(
        card,
        chosenColor: chosenColor,
      );
    });

    if (current.winner != null) {
      showWinner(current.winner!);
      return;
    }

    scheduleRobotTurn();
  }

  // Human draws a card.
  void drawHumanCard() {
    final current = game;

    if (current == null ||
        current.winner != null ||
        current.activePlayer.isBot) {
      return;
    }

    setState(() {
      current.drawCard();
    });

    scheduleRobotTurn();
  }

  // Robot chooses the colour with the most cards.
  UnoColor robotChooseColor(List<UnoCard> hand) {
    const colors = [
      UnoColor.red,
      UnoColor.yellow,
      UnoColor.green,
      UnoColor.blue,
    ];

    var bestColor = colors.first;
    var highestCount = -1;

    for (final color in colors) {
      final count = hand
          .where((card) => card.color == color)
          .length;

      if (count > highestCount) {
        highestCount = count;
        bestColor = color;
      }
    }

    return bestColor;
  }

  // Robot selects a card.
  UnoCard robotChooseCard(List<UnoCard> cards) {
    final sortedCards = List<UnoCard>.from(cards);

    int cardScore(UnoCard card) {
      switch (card.value) {
        case '+4':
          return 6;
        case '+2':
          return 5;
        case 'Skip':
          return 4;
        case 'Reverse':
          return 3;
        case 'Wild':
          return 2;
        default:
          return 1;
      }
    }

    sortedCards.sort(
      (a, b) => cardScore(b).compareTo(cardScore(a)),
    );

    return sortedCards.first;
  }

  // Robot plays automatically.
  Future<void> scheduleRobotTurn() async {
    final current = game;

    if (current == null ||
        current.winner != null ||
        !current.activePlayer.isBot ||
        robotThinking) {
      return;
    }

    robotThinking = true;

    setState(() {});

    await Future.delayed(
      const Duration(milliseconds: 1100),
    );

    if (!mounted ||
        game != current ||
        current.winner != null ||
        !current.activePlayer.isBot) {
      robotThinking = false;
      return;
    }

    final robot = current.activePlayer;

    final playableCards = robot.hand
        .where((card) => current.canPlay(card))
        .toList();

    if (playableCards.isEmpty) {
      current.drawCard();
    } else {
      final selectedCard = robotChooseCard(playableCards);

      UnoColor? chosenColor;

      if (selectedCard.isWild) {
        chosenColor = robotChooseColor(robot.hand);
      }

      current.playCard(
        selectedCard,
        chosenColor: chosenColor,
      );
    }

    robotThinking = false;

    if (!mounted || game != current) return;

    setState(() {});

    if (current.winner != null) {
      showWinner(current.winner!);
      return;
    }

    if (current.activePlayer.isBot) {
      scheduleRobotTurn();
    }
  }

  // Show winner dialog.
  void showWinner(String winner) {
    if (winnerDialogShown || !mounted) return;

    winnerDialogShown = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('UNO! 🎉'),
          content: Text('$winner wins the game!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                startGame();
              },
              child: const Text('Play again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  game = null;
                  winnerDialogShown = false;
                });
              },
              child: const Text('Main menu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF125B37),
      appBar: AppBar(
        title: const Text(
          'LOCALPLAY UNO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 101, 172, 138),
        actions: [
          if (game != null)
            IconButton(
              tooltip: 'Main menu',
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  game = null;
                  winnerDialogShown = false;
                  robotThinking = false;
                });
              },
            ),
        ],
      ),
      body: game == null
          ? homeScreen()
          : gameBoard(),
    );
  }

  // HOME SCREEN.
  Widget homeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.style,
              color: Colors.white,
              size: 95,
            ),
            const SizedBox(height: 12),
            const Text(
              'UNO',
              style: TextStyle(
                fontSize: 65,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 5,
              ),
            ),
            const Text(
              'PLAY WITH FRIENDS OR AGAINST A ROBOT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 35),
            const Text(
              'Choose Game Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('Solo vs Robot'),
                  selected: playAlone,
                  selectedColor: Colors.amber,
                  onSelected: (selected) {
                    setState(() {
                      playAlone = true;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Play with Friends'),
                  selected: !playAlone,
                  selectedColor: Colors.amber,
                  onSelected: (selected) {
                    setState(() {
                      playAlone = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!playAlone) ...[
              const Text(
                'Number of players',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: playerCount,
                dropdownColor: const Color(0xFF0B4027),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                items: [2, 3, 4].map((number) {
                  return DropdownMenuItem(
                    value: number,
                    child: Text('$number players'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    playerCount = value ?? 2;
                  });
                },
              ),
            ],
            const SizedBox(height: 25),
            SizedBox(
              width: 230,
              height: 54,
              child: ElevatedButton(
                onPressed: startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'START GAME',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // GAME BOARD.
  Widget gameBoard() {
    final current = game!;

    final humanPlayer = current.players.firstWhere(
      (player) => !player.isBot,
      orElse: () => current.activePlayer,
    );

    final isRobotTurn = current.activePlayer.isBot;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Player information.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: current.players.asMap().entries.map((entry) {
              final player = entry.value;
              final isActive =
                  entry.key == current.currentPlayer;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.amber
                      : const Color(0xFF0B4027),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white54),
                ),
                child: Text(
                  '${player.isBot ? '🤖 ' : ''}'
                  '${player.name} (${player.hand.length})',
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Turn information.
          Text(
            isRobotTurn
                ? (robotThinking
                    ? 'ROBOT IS THINKING 🤖'
                    : 'ROBOT TURN 🤖')
                : 'YOUR TURN',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            current.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),

          const Spacer(),

          // Draw pile and discard pile.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const Text(
                    'DRAW PILE',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: isRobotTurn ? null : drawHumanCard,
                    child: cardBack(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${current.drawPile.length} cards',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(width: 35),

              Column(
                children: [
                  const Text(
                    'DISCARD PILE',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  cardFace(
                    current.topCard,
                    width: 85,
                    height: 125,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Colour: ${current.activeColor.name.toUpperCase()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Player's hand heading.
          Text(
            isRobotTurn
                ? 'YOUR CARDS - ROBOT TURN'
                : 'YOUR CARDS (${humanPlayer.hand.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          // NEW FAN-SHAPED CARD HAND.
          fanHand(current, humanPlayer),

          const SizedBox(height: 12),

          // Draw button.
          ElevatedButton.icon(
            onPressed: isRobotTurn ? null : drawHumanCard,
            icon: const Icon(Icons.add),
            label: const Text('DRAW CARD'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),

          const SizedBox(height: 15),
        ],
      ),
    );
  }

  // FAN-SHAPED PLAYER HAND.
  Widget fanHand(UnoGame current, UnoPlayer humanPlayer) {
    final cards = humanPlayer.hand;
    final count = cards.length;

    if (count == 0) {
      return const SizedBox(
        height: 145,
        child: Center(
          child: Text(
            'No cards',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const cardWidth = 76.0;
        const cardHeight = 114.0;

        // Overlap cards to make a realistic hand.
        final double overlap = count <= 5
            ? 48
            : count <= 8
                ? 35
                : count <= 12
                    ? 25
                    : 18;

        final totalWidth =
            cardWidth + (count - 1) * overlap;

        final scale = math.min(
          1.0,
          constraints.maxWidth / totalWidth,
        );

        final actualWidth = cardWidth * scale;
        final actualHeight = cardHeight * scale;
        final actualOverlap = overlap * scale;

        final fanWidth =
            actualWidth + (count - 1) * actualOverlap;

        return SizedBox(
          height: 155,
          width: double.infinity,
          child: Center(
            child: SizedBox(
              width: fanWidth,
              height: 145,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: List.generate(count, (index) {
                  final card = cards[index];

                  final middle = (count - 1) / 2;
                  final distance = index - middle;

                  // Slight rotation for each card.
                  final angle = count == 1
                      ? 0.0
                      : distance * 0.045;

                  // Middle cards appear higher.
                  final verticalOffset =
                      distance.abs() * 3.0;

                  final playable =
                      !current.activePlayer.isBot &&
                      current.canPlay(card);

                  return Positioned(
                    left: index * actualOverlap,
                    bottom: verticalOffset,
                    child: Transform.rotate(
                      angle: angle,
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: playable
                            ? () => playHumanCard(card)
                            : null,
                        child: AnimatedOpacity(
                          duration:
                              const Duration(milliseconds: 200),
                          opacity: playable ? 1.0 : 0.45,
                          child: cardFace(
                            card,
                            width: actualWidth,
                            height: actualHeight,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  // Draw pile card design.
  Widget cardBack() {
    return Container(
      width: 85,
      height: 125,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 5,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'UNO',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w900,
            fontSize: 27,
          ),
        ),
      ),
    );
  }

  // Individual UNO card design.
  Widget cardFace(
    UnoCard card, {
    double width = 80,
    double height = 120,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: getColor(card.color),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 5,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: width * 0.76,
          height: height * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Transform.rotate(
              angle: -0.3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  card.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: card.isWild
                        ? Colors.black
                        : getColor(card.color),
                    fontSize: card.label.length > 4 ? 14 : 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
