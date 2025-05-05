import 'package:flutter/material.dart';
import 'package:mood_and_mind/screens/journal_screen.dart';
import 'package:mood_and_mind/screens/habits_screen.dart';
import 'package:mood_and_mind/screens/calendar_screen.dart';
import 'package:mood_and_mind/screens/settings_screen.dart';
import 'package:mood_and_mind/screens/achievements_screen.dart';
import 'package:mood_and_mind/screens/dashboard_screen.dart'; // Importăm versiunea corectă
import 'package:mood_and_mind/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const HomeScreen({super.key, required this.databaseHelper});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    print('HomeScreen initialized');
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController)
          ..addListener(() {
            if (mounted) setState(() {});
          });
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
    return FutureBuilder<Database>(
      future: widget.databaseHelper.database, // Așteptăm baza de date
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error loading database')),
          );
        }
        final database = snapshot.data!;
        final screens = [
          DashboardScreen(
              database:
                  database), // Folosim versiunea din dashboard_screen.dart
          JournalScreen(databaseHelper: widget.databaseHelper),
          HabitsScreen(databaseHelper: widget.databaseHelper),
          CalendarScreen(database: database),
          const SettingsScreen(),
          AchievementsScreen(database: database),
        ];

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
            backgroundColor: Colors.white,
            selectedItemColor: Colors.teal, // Culoare vizibilă
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.favorite), label: 'Habits'),
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
      },
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
