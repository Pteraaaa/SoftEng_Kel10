import 'package:flutter/material.dart';
import 'package:myapp/Screens/AuthScreen.dart';
import 'package:myapp/Screens/HomeScreen.dart';
import 'package:myapp/Screens/TemplateScreen.dart';
import 'Screens/LandingScreen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Pocket Log",
      debugShowCheckedModeBanner: false,
      home: const AuthScreen(),
    );
  }
}
