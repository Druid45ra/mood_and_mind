import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';

class OnboardingScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  const OnboardingScreen({super.key, required this.databaseHelper});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<Map<String, String>> _slides = [
    {
      'title': 'Welcome to Mood & Mind',
      'description': 'Track your mood and build healthy habits.',
      'image': 'assets/onboarding1.png',
    },
    {
      'title': 'Journal Your Feelings',
      'description': 'Log your emotions and reflect on your day.',
      'image': 'assets/onboarding2.png',
    },
    {
      'title': 'Achieve Your Goals',
      'description': 'Earn achievements as you progress.',
      'image': 'assets/onboarding3.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(databaseHelper: widget.databaseHelper),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Placeholder pentru imagini (înlocuiește cu asset-urile reale)
                  Container(
                    height: 200,
                    color: Colors.teal[100],
                    child: const Center(child: Icon(Icons.image, size: 100)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _slides[index]['title']!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _slides[index]['description']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.teal : Colors.grey,
                  ),
                );
              }),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                child: const Text('Get Started',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
