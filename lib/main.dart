import 'package:flutter/material.dart';
import 'welcome_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Kisan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        // If you don't have Arimo font yet, use this:
        fontFamily: 'Roboto', // Fallback font
        useMaterial3: true,
      ),
      home: WelcomeScreen(),
    );
  }
}