import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const UserDirectoryApp());
}

class UserDirectoryApp extends StatelessWidget {
  const UserDirectoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'User Directory',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomeScreen(),
    );
  }
}