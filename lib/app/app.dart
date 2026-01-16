import 'package:flutter/material.dart';
import 'theme.dart';
import '../features/home/home_shell.dart';

class TTGOApp extends StatelessWidget {
  const TTGOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeShell(),
    );
  }
}
