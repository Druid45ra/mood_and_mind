import 'package:flutter/material.dart';
import 'package:mood_and_mind/screens/journal_screen.dart';
import 'package:mood_and_mind/screens/habits_screen.dart';
import 'package:mood_and_mind/screens/calendar_screen.dart';
import 'package:mood_and_mind/screens/settings_screen.dart';
import 'package:mood_and_mind/screens/achievements_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const HomeScreen({Key? key, required this.databaseHelper}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  late final List<Widget> screens;
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    screens = [
      const DashboardScreen(), // Placeholder, nu necesită DatabaseHelper
      JournalScreen(databaseHelper: widget.databaseHelper),
      HabitsScreen(databaseHelper: widget.databaseHelper),
      CalendarScreen(databaseHelper: widget.databaseHelper),
      const SettingsScreen(), // Placeholder, nu necesită DatabaseHelper
      AchievementsScreen(databaseHelper: widget.databaseHelper),
    ];
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
      animationController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood & Mind'),
      ),
      body: FadeTransition(
        opacity: fadeAnimation,
        child: IndexedStack(
          index: selectedIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Habits'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: 'Achievements'),
        ],
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Clase placeholder pentru ecranele care nu au fost furnizate
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.grey);
  }
}

class CalendarScreen extends StatelessWidget {
  final DatabaseHelper databaseHelper;

  const CalendarScreen({Key? key, required this.databaseHelper})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.blue);
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.green);
  }
}

class AchievementsScreen extends StatelessWidget {
  final DatabaseHelper databaseHelper;

  const AchievementsScreen({Key? key, required this.databaseHelper})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.orange);
  }
}
