import 'package:flutter/material.dart';
import 'package:mood_and_mind/screens/journal_screen.dart';
import 'package:mood_and_mind/screens/habits_screen.dart';
import 'package:mood_and_mind/screens/calendar_screen.dart';
import 'package:mood_and_mind/screens/settings_screen.dart';
import 'package:mood_and_mind/screens/achievements_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const HomeScreen({super.key, required this.databaseHelper});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  late final List<Widget> screens;
  late AnimationController animationController;
  late Animation<double> fadeAnimation; // Corectăm declarația

  @override
  void initState() {
    super.initState();
    print('HomeScreen initialized');
    screens = [
      const DashboardScreen(),
      JournalScreen(databaseHelper: widget.databaseHelper),
      HabitsScreen(databaseHelper: widget.databaseHelper),
      CalendarScreen(databaseHelper: widget.databaseHelper),
      const SettingsScreen(),
      AchievementsScreen(databaseHelper: widget.databaseHelper),
    ];
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
    print('Selected screen index: $selectedIndex');
    animationController.forward();
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
      print('Switched to screen index: $index');
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building HomeScreen with selectedIndex: $selectedIndex');
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

class ErrorHandler extends StatelessWidget {
  final Widget child;

  const ErrorHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e) {
          return const Center(
            child: Text(
              'Eroare la încărcarea ecranului.',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }
      },
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building DashboardScreen');
    return Container(
      color: Colors.grey,
      child: const Center(
          child: Text('Dashboard',
              style: TextStyle(fontSize: 24, color: Colors.black))),
    );
  }
}

class CalendarScreen extends StatelessWidget {
  final DatabaseHelper databaseHelper;

  const CalendarScreen({super.key, required this.databaseHelper});

  @override
  Widget build(BuildContext context) {
    print('Building CalendarScreen');
    return Container(
        color: Colors.blue, child: const Center(child: Text('Calendar')));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building SettingsScreen');
    return Container(
        color: Colors.green, child: const Center(child: Text('Settings')));
  }
}

class AchievementsScreen extends StatelessWidget {
  final DatabaseHelper databaseHelper;

  const AchievementsScreen({super.key, required this.databaseHelper});

  @override
  Widget build(BuildContext context) {
    print('Building AchievementsScreen');
    return Container(
        color: Colors.orange, child: const Center(child: Text('Achievements')));
  }
}
