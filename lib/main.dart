
import 'package:flutter/material.dart';
import 'games/uno_game_screen.dart';

void main() {
  runApp(const LocalPlayApp());
}

class LocalPlayApp extends StatelessWidget {
  const LocalPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalPlay UNO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
        ),
        useMaterial3: true,
      ),
      home: const UnoGameScreen(),
    );
  }
}
