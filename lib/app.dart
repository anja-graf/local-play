import 'package:flutter/material.dart';
import 'ui/host_page.dart';

class LocalPlayApp extends StatelessWidget {
  const LocalPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'LocalPlay',
      home: HostPage(),
    );
  }
}