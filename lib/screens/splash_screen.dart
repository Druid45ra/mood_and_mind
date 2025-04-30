import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // Adăugăm importul pentru Database
import 'package:mood_and_mind/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  final Database database;

  const SplashScreen({super.key, required this.database});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(database: widget.database),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 100,
              ),
              const SizedBox(height: 20),
              Text(
                'Mood & Mind',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your Mental Wellness Companion',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.teal[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
