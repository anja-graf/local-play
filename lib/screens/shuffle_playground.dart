import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/playing_card.dart';
import '../widgets/shuffle_button.dart';

class ShufflePlayground extends StatefulWidget {
  final String gameName;

  const ShufflePlayground({super.key, required this.gameName});

  @override
  State<ShufflePlayground> createState() => _ShufflePlaygroundState();
}

class _ShufflePlaygroundState extends State<ShufflePlayground> {
  int shuffleCount = 0;

  List<PlayingCard> cards = [
    const PlayingCard(symbol: '3', color: AppColors.secondary, rotation: -0.12),
    const PlayingCard(symbol: '7', color: AppColors.primary),
    const PlayingCard(symbol: '♥', color: AppColors.accent, rotation: 0.12),
  ];

  void shuffleCards() {
    setState(() {
      cards.shuffle(Random());
      shuffleCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameName),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ready to play?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 45),

              // The deck of cards
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: cards,
              ),

              const SizedBox(height: 55),

              ShuffleButton(onPressed: shuffleCards),

              const SizedBox(height: 20),

              Text(
                'Shuffled $shuffleCount times',
                style: const TextStyle(color: AppColors.text, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
