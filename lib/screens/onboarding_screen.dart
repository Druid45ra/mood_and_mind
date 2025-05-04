import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';

class OnboardingScreen extends StatelessWidget {
  final DatabaseHelper databaseHelper;

  const OnboardingScreen({Key? key, required this.databaseHelper})
      : super(key: key);

  Future<void> _onDone(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(databaseHelper: databaseHelper),
      ),
    );
  }

  // Metodă pentru slide-uri (nefolosită momentan, pentru viitor)
  Widget buildSlide({
    required String title,
    required String description,
    required String imagePath,
    required Color backgroundColor,
  }) {
    return Container(
      color: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(fontSize: 24, color: Colors.white)),
          const SizedBox(height: 10),
          Text(description,
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _onDone(context),
          child: const Text('Done'),
        ),
      ),
    );
  }
}
