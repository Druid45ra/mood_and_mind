import '../screens/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:mood_and_mind/screens/calendar_screen.dart';
import 'package:mood_and_mind/screens/journal_screen.dart';
import 'package:mood_and_mind/screens/achievements_screen.dart';
import 'package:mood_and_mind/screens/settings_screen.dart';
import 'package:mood_and_mind/screens/dashboard_screen.dart';
import 'package:mood_and_mind/screens/habits_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:mood_and_mind/models/settings_model.dart' as settings_model;
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  const HomeScreen({super.key, required this.databaseHelper});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  Future<void> _initializeScreens() async {
    final settingsModel =
        Provider.of<settings_model.SettingsModel>(context, listen: false);
    await settingsModel.loadSettings();

    // Resolve the database Future for StatisticsScreen
    final database = await widget.databaseHelper.database;

    setState(() {
      _screens = [
        CalendarScreen(databaseFuture: widget.databaseHelper.database),
        JournalScreen(databaseHelper: widget.databaseHelper),
        HabitsScreen(databaseHelper: widget.databaseHelper),
        DashboardScreen(databaseFuture: widget.databaseHelper.database),
        AchievementsScreen(databaseFuture: widget.databaseHelper.database),
        StatisticsScreen(database: database),
        SettingsScreen(updateTheme: (isDark) {
          final settingsModel =
              Provider.of<settings_model.SettingsModel>(context, listen: false);
          settingsModel.setDarkMode(isDark);
        }),
      ];
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens[_selectedIndex],
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
