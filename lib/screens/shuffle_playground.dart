import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/shake_detector.dart';
import '../widgets/playing_card.dart';
import '../widgets/shuffle_button.dart';

class ShufflePlayground extends StatefulWidget {
  const ShufflePlayground({super.key});

  @override
  State<ShufflePlayground> createState() => _ShufflePlaygroundState();
}

class _ShufflePlaygroundState extends State<ShufflePlayground> {
  final ShakeDetector _shakeDetector = ShakeDetector();

  int shuffleCount = 0;

  List<PlayingCard> cards = [
    const PlayingCard(symbol: '3', color: AppColors.secondary, rotation: -0.12),
    const PlayingCard(symbol: '7', color: AppColors.primary),
    const PlayingCard(symbol: '♥', color: AppColors.accent, rotation: 0.12),
  ];

  @override
  void initState() {
    super.initState();

    _shakeDetector.startListening(() {
      shuffleCards();
    });
  }

  void shuffleCards() {
    setState(() {
      cards.shuffle(Random());
      shuffleCount++;
    });
  }

  @override
  void dispose() {
    _shakeDetector.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LocalPlay.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),

              const SizedBox(height: 12),

              Text(
                'Let\'s shuffle!',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 50),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: cards,
              ),

              const SizedBox(height: 50),

              const Text('Shake your phone to shuffle!'),

              const SizedBox(height: 20),

              ShuffleButton(onPressed: shuffleCards),

              const SizedBox(height: 20),

              Text('Shuffled $shuffleCount times'),
            ],
          ),
        ),
      ),
    );
  }
}
