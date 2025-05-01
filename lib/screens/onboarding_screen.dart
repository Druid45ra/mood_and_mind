import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:sqflite/sqflite.dart';

class OnboardingScreen extends StatelessWidget {
  final Database database;
  const OnboardingScreen({super.key, required this.database});

  Future<void> _onDone(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(database: database),
      ),
    );
  }

  Widget _buildSlide({
    required String title,
    required String description,
    required String imagePath,
    required Color backgroundColor,
  }) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 120,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> slides = [
      _buildSlide(
        title: 'Welcome to Mood & Mind',
        description: 'Track your mood, habits, and mental wellness with ease.',
        imagePath: 'assets/logo.png',
        backgroundColor: Colors.teal[100]!,
      ),
      _buildSlide(
        title: 'Daily Journal',
        description: 'Log your mood and thoughts every day to understand your emotional patterns.',
        imagePath: 'assets/logo.png',
        backgroundColor: Colors.teal[200]!,
      ),
      _buildSlide(
        title: 'Build Habits',
        description: 'Set daily habits and get reminders to stay on track.',
        imagePath: 'assets/logo.png',
        backgroundColor: Colors.teal[300]!,
      ),
      _buildSlide(
        title: 'Explore Insights',
        description: 'View statistics and achievements to see your progress.',
        imagePath: 'assets/logo.png',
        backgroundColor: Colors.teal[400]!,
      ),
    ];

    return IntroSlider(
      listCustomTabs: slides,
      onDonePress: () => _onDone(context),
      onSkipPress: () => _onDone(context),
      renderSkipBtn: const Text('Skip', style: TextStyle(color: Colors.white)),
      renderNextBtn: const Icon(Icons.arrow_forward, color: Colors.white),
      renderDoneBtn: const Text('Get Started', style: TextStyle(color: Colors.white)),
      colorDot: Colors.white54,
      colorActiveDot: Colors.white,
    );
  }
}
