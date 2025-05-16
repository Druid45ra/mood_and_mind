import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  final Function(bool) updateTheme;

  const OnboardingScreen(
      {super.key, required this.databaseHelper, required this.updateTheme});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<ContentConfig> getSlides() {
    return [
      const ContentConfig(
        title: "Welcome to Mood & Mind",
        description: "Track your mood, habits, and goals in one place.",
        backgroundColor: Color(0xFFE3F2FD),
      ),
      const ContentConfig(
        title: "Stay Organized",
        description:
            "Use our calendar and reminders to stay on top of your tasks.",
        backgroundColor: Color(0xFFE8F5E9),
      ),
      const ContentConfig(
        title: "Achieve Your Goals",
        description: "Monitor your progress and celebrate your achievements!",
        backgroundColor: Color(0xFFFDE9E0),
      ),
    ];
  }

  void onDonePress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          databaseHelper: widget.databaseHelper,
          updateTheme: widget.updateTheme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      listContentConfig: getSlides(),
      renderSkipBtn: const Text("Skip"),
      renderNextBtn: const Text("Next"),
      renderDoneBtn: const Text("Done"),
      onDonePress: onDonePress,
      onSkipPress: onDonePress,
    );
  }
}
