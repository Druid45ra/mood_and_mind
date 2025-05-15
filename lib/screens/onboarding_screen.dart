import 'package:flutter/material.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/models/settings_model.dart' as settings_model;

class OnboardingScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  const OnboardingScreen({super.key, required this.databaseHelper});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(databaseHelper: widget.databaseHelper),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<settings_model.SettingsModel>(
      builder: (context, settingsModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Onboarding'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildPage(
                        title: 'Welcome to Mood & Mind',
                        description: 'Track your mood and habits daily.',
                      ),
                      _buildPage(
                        title: 'Log Your Thoughts',
                        description:
                            'Write journal entries to reflect on your day.',
                      ),
                      _buildPage(
                        title: 'Achieve Your Goals',
                        description:
                            'Set and track habits to improve your life.',
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) => _buildDot(index)),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20.0),
                  child: ElevatedButton(
                    onPressed: _currentPage == 2
                        ? _completeOnboarding
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      _currentPage == 2 ? 'Get Started' : 'Next',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage({required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      width: _currentPage == index ? 12.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.teal : Colors.grey,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}
