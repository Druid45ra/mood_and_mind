import 'package:flutter/material.dart';
import 'package:mood_and_mind/screens/calendar_screen.dart';
import 'package:mood_and_mind/screens/journal_screen.dart';
import 'package:mood_and_mind/screens/achievements_screen.dart';

import 'package:mood_and_mind/screens/settings_screen.dart';

import 'package:mood_and_mind/screens/dashboard_screen.dart';
import 'package:mood_and_mind/screens/habits_screen.dart';
import 'package:mood_and_mind/screens/statistics_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:mood_and_mind/screens/achievements_screen.dart';
import 'package:mood_and_mind/models/achievements_model.dart'
    as achievements_model;
import 'package:mood_and_mind/models/settings_model.dart' as settings_model;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  const HomeScreen({super.key, required this.databaseHelper});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Inițializăm datele pentru AchievementsModel și SettingsModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<achievements_model.AchievementsModel>(context, listen: false)
          .loadAchievements();
      Provider.of<settings_model.SettingsModel>(context, listen: false)
          .loadSettings();
    });

    _screens = [
      FutureBuilder<Database>(
        future: widget.databaseHelper.database,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (snapshot.hasData) {
            return CalendarScreen(database: snapshot.data!);
          }
          return const Center(child: Text('No database available'));
        },
      ),
      FutureBuilder<Database>(
        future: widget.databaseHelper.database,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (snapshot.hasData) {
            return JournalScreen(databaseHelper: widget.databaseHelper);
          }
          return const Center(child: Text('No database available'));
        },
      ),
      FutureBuilder<Database>(
        future: widget.databaseHelper.database,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (snapshot.hasData) {
            return HabitsScreen(databaseHelper: widget.databaseHelper);
          }
          return const Center(child: Text('No database available'));
        },
      ),
      FutureBuilder<Database>(
        future: widget.databaseHelper.database,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (snapshot.hasData) {
            return DashboardScreen(database: snapshot.data!);
          }
          return const Center(child: Text('No database available'));
        },
      ),
      FutureBuilder<Database>(
        future: widget.databaseHelper.database,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (snapshot.hasData) {
            return AchievementsScreen(database: snapshot.data!);
          }
          return const Center(child: Text('No database available'));
        },
      ),
      FutureBuilder<Database>(
        future: widget.databaseHelper.database,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (snapshot.hasData) {
            return StatisticsScreen(database: snapshot.data!);
          }
          return const Center(child: Text('No database available'));
        },
      ),
      FutureBuilder<Database>(
        future: widget.databaseHelper.database,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (snapshot.hasData) {
            return SettingsScreen(databaseHelper: widget.databaseHelper);
          }
          return const Center(child: Text('No database available'));
        },
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Achievements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.teal,
        onTap: _onItemTapped,
        elevation: 8.0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
