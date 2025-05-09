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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settingsModel =
          Provider.of<settings_model.SettingsModel>(context, listen: false);
      settingsModel.loadSettings();
      final database = await widget.databaseHelper.database;
      setState(() {
        _screens = [
          CalendarScreen(database: database),
          JournalScreen(databaseHelper: widget.databaseHelper),
          HabitsScreen(databaseHelper: widget.databaseHelper),
          DashboardScreen(database: database),
          AchievementsScreen(),
          ChangeNotifierProvider(
            create: (context) => Provider.of<settings_model.SettingsModel>(context, listen: false),
            child: SettingsScreen(),
          ),
        ];
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index.clamp(0, _screens.length - 1);
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
