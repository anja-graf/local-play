import 'package:flutter/material.dart';
import 'package:localplay/features/select_game/select_game_page.dart';

class LocalPlayApp extends StatelessWidget {
  const LocalPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'LocalPlay',
      home: SelectGamePage(),
    );
  }
}