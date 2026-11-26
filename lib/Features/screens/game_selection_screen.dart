import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'shuffle_playground.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  final List<String> games = const [
    'Game 1',
    'Game 2',
    'Game 3',
    'Game 4',
    'Game 5',
    'Game 6',
  ];

  final List<Color> gameColors = const [
    AppColors.primary,
    AppColors.secondary,
    Color(0xFF779BC2), // Blue
    Color(0xFFC49ACB), // Purple
    Color(0xFFE9C96A), // Yellow
    Color(0xFFD58D54), // Orange
  ];

  void openGame(BuildContext context, String gameName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShufflePlayground(gameName: gameName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a game'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.text,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What game would you like to play?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 25),

            Expanded(
              child: GridView.builder(
                itemCount: games.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gameColors[index],
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => openGame(context, games[index]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.style, size: 34),
                        const SizedBox(height: 10),
                        Text(
                          games[index],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
