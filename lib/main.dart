import 'package:flutter/material.dart';
import 'package:smart_kisan/welcome_screen.dart';
import 'package:smart_kisan/home_page.dart'; 

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
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home:  WelcomeScreen(),
      
      // Add routes for navigation
      routes: {
        '/home': (context) => HomePage(
          isNewUser: false,
          userName: 'Farmer',
        ),
      },
    );
  }
}